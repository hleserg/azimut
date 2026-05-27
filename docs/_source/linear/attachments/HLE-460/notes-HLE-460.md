# Заметки HLE-460: FSerg/mcp-1c-v1 — chunking, Qdrant, RRF

Клонировано в /tmp/mcp-1c-v1 (удалено после изучения)

## Файловая структура (ключевые файлы)
- loader/loader.py — индексатор (chunking здесь)
- loader/config.py — конфигурация загрузчика
- mcp/mcp_server.py — MCP-сервер, поиск
- mcp/config.py — конфигурация MCP
- embeddings/embedding_service.py — сервис эмбеддингов
- embeddings/config.json — конфиг модели
- mcp/MULTIVECTOR_SEARCH.md — документация гибридного поиска
- article/article.md — статья-описание проекта
- LICENSE — ЕСТЬ MIT License (см. п.5 ниже)

---

## 1. CHUNKING-СТРАТЕГИЯ

### Входные данные
- ZIP-архив с `objects.csv` + набор markdown-файлов описания объектов
- objects.csv содержит колонки: "Имя объекта", "Тип объекта", "Синоним", "Файл"
  - loader.py:250-256

### Принцип нарезки
- **Один чанк = один объект конфигурации 1С** (без нарезки внутри объекта)
- Нет разбивки на суб-чанки, нет overlap — каждый объект целиком = 1 точка в Qdrant
- loader.py:84-116

### Формирование текстов для эмбеддинга — ДВА вектора на объект
1. **object_name** text: просто `object_name` (имя объекта как в 1С: "Справочник.Номенклатура")
   - loader.py:107: `object_name_text = object_name`
2. **friendly_name** text: `f"{object_type}: {synonym}"` → "Справочник: Номенклатура"
   - loader.py:110: `friendly_name_text = f"{object_type}: {synonym}"`

### Что НЕ эмбеддится
- Полное markdown-описание объекта (doc) → хранится в payload, НЕ векторизуется
- article.md:72: «векторизуются только внутр.названия объектов и их синоним. А сами подробные описания объектов сохраняются в БД как часть метаданных коллекции»

### Размеры батчей
- ROW_BATCH_SIZE = 250 строк CSV за раз (loader/config.py:15)
- EMBEDDING_BATCH_SIZE = 50 текстов за раз для вызова сервиса (loader/config.py:17)

---

## 2. QDRANT-СХЕМА

### Коллекция
- По умолчанию одна: "1c_rag" (mcp/config.py:11)
- Поддержка нескольких коллекций (разные конфигурации 1С) через HTTP-заголовок `x-collection-name`
- mcp_server.py:166-170

### Named vectors (два на точку)
- `"object_name"`: Distance.COSINE, on_disk=True (loader.py:228-232)
- `"friendly_name"`: Distance.COSINE, on_disk=True (loader.py:233-237)
- Размерность: динамически от сервиса эмбеддингов (384 по умолчанию, 1024 у jina/Qwen)
- loader.py:210: `DIMENSIONS = embedding_info.get('dimensions', 384)`

### Payload fields (loader.py:155-164)
- `object_name` — строка, точное имя объекта как в 1С ("Справочник.Номенклатура")
- `object_type` — тип ("Справочник", "Документ", "РегистрСведений", ...)
- `doc` — полный markdown-текст описания объекта
- `file_name` — исходный путь к markdown-файлу
- `friendly_name` — строка "Тип: Синоним" ("Справочник: Номенклатура")

### ID точки
- UUID4 (str) — loader.py:150

### Параметры коллекции
- Нет явных HNSW/quantization настроек — используются дефолты Qdrant
- on_disk=True для обоих векторов

---

## 3. RRF / ГИБРИДНЫЙ ПОИСК

### Что сливают
- **ДВА DENSE вектора** (object_name + friendly_name) — НЕ dense+sparse, НЕ BM25
- Один и тот же запросный вектор используется для обоих prefetch
- mcp_server.py:112-128

### Реализация (Qdrant native RRF)
```python
qdrant_client.query_points(
    collection_name=collection_name,
    prefetch=[
        Prefetch(query=query_embedding, using="object_name",   limit=limit*3),
        Prefetch(query=query_embedding, using="friendly_name", limit=limit*3),
    ],
    query=FusionQuery(fusion=Fusion.RRF),
    limit=limit
)
```
- mcp_server.py:110-128

### Параметры
- PREFETCH_LIMIT_MULTIPLIER = 3 по умолчанию (mcp/config.py:37)
  - При limit=5 → prefetch 15 кандидатов по каждому вектору → RRF → топ-5
- DEFAULT_SEARCH_LIMIT = 5, MAX=10, MIN=1 (mcp/config.py:23-25)

### Обычный поиск (fallback)
- Только "friendly_name" вектор (mcp_server.py:131-137)
- Используется при use_multivector=False (только в REST API, MCP всегда multivector)

---

## 4. ЭМБЕДДЕР

### По умолчанию
- Модель: `all-MiniLM-L6-v2`, 384 измерения, supports_task=false
- embeddings/config.json:3-9

### Поддерживаемые модели (из config.json)
- `all-MiniLM-L6-v2`: 384d, не поддерживает task-parameter
- `jinaai/jina-embeddings-v3`: 1024d, поддерживает task-parameter
- `Qwen/Qwen3-Embedding-0.6B`: 1024d, не поддерживает task-parameter
- embeddings/config.json:10-19

### Реализация
- FastAPI-сервис, SentenceTransformer (embeddings/embedding_service.py:1-8)
- Порт 5000 (embeddings/embedding_service.py:138)
- Замена модели: просто изменить config.json → перезапустить контейнер (article.md:47)

### Разделение задач
- Индексация: task="retrieval.passage" (loader.py:43)
- Поиск: task="retrieval.query" (mcp_server.py:74)
- Актуально для моделей с supports_task=true (jina)

---

## 5. ЛИЦЕНЗИЯ

**ВАЖНО:** Задача утверждает "лицензии у репо НЕТ", но это НЕВЕРНО.
- LICENSE файл ЕСТЬ в корне репозитория
- **MIT License**, Copyright (c) 2025 [Sergey Filkin] (LICENSE:1-3)
- Разрешает использование, копирование, изменение, распространение, продажу

---

## Источники
- loader/loader.py — chunking, Qdrant загрузка
- loader/config.py — параметры батчинга
- mcp/mcp_server.py — RRF поиск
- mcp/config.py — параметры поиска
- embeddings/embedding_service.py — эмбеддинги
- embeddings/config.json — конфиг модели
- mcp/MULTIVECTOR_SEARCH.md — архитектура поиска
- article/article.md — авторское описание архитектурных решений
