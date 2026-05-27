# HLE-460: FSerg/mcp-1c-v1 — Chunking-стратегия и Qdrant-схема

**Репозиторий:** FSerg/mcp-1c-v1 (TypeScript-оболочка + Python-ядро)
**Режим:** READ-ONLY. Код не копируется, только идеи.

---

## 1. Chunking-стратегия

### Принцип нарезки

**Один объект конфигурации 1С = одна точка в Qdrant.** Нет разбивки внутри объекта, нет overlap, нет sliding window.

Входные данные — ZIP-архив с `objects.csv` и набором markdown-файлов. CSV содержит колонки: `"Имя объекта"`, `"Тип объекта"`, `"Синоним"`, `"Файл"` (путь к markdown). Каждая строка CSV → один чанк.

- `loader/loader.py:84-116` — функция `process_csv_batch`

### Формирование текста чанка для эмбеддинга — ДВА вектора на объект

| Вектор | Исходный текст | Пример |
|--------|----------------|--------|
| `object_name` | `object_name` (точное имя как в 1С) | `"Справочник.Номенклатура"` |
| `friendly_name` | `f"{object_type}: {synonym}"` | `"Справочник: Номенклатура"` |

- `loader/loader.py:107` — текст для object_name
- `loader/loader.py:110` — текст для friendly_name

**Критически важно:** полное markdown-описание объекта (поле `doc`) **НЕ эмбеддится**. Оно хранится в payload как есть и возвращается при поиске. Автор объясняет (article/article.md:72): векторизация полного описания давала хуже результаты — семантически похожие объекты (расходный ордер ≈ расходная накладная) обгоняли точные совпадения по имени. Решение — векторизовать только имена.

### Размеры батчей

- ROW_BATCH_SIZE = 250 строк CSV за раз (`loader/config.py:15`)
- EMBEDDING_BATCH_SIZE = 50 текстов за вызов к embedding-сервису (`loader/config.py:17`)

---

## 2. Qdrant-схема

### Коллекции

- Одна коллекция на конфигурацию 1С (по умолчанию `"1c_rag"`, `mcp/config.py:11`)
- Имя коллекции переопределяется через HTTP-заголовок `x-collection-name` при запросе к MCP-серверу — можно держать несколько конфигураций в одном Qdrant (`mcp/mcp_server.py:166-170`)
- Нет явных HNSW/quantization параметров — используются дефолты Qdrant

### Named vectors (два на точку)

```python
client.create_collection(
    collection_name=collection_name,
    vectors_config={
        "object_name": VectorParams(size=DIMENSIONS, distance=Distance.COSINE, on_disk=True),
        "friendly_name": VectorParams(size=DIMENSIONS, distance=Distance.COSINE, on_disk=True)
    }
)
```

- `loader/loader.py:226-239`
- Размерность: 384 для all-MiniLM-L6-v2, 1024 для jina/Qwen — берётся динамически от embedding-сервиса (`loader/loader.py:210`)
- `on_disk=True` — векторы хранятся на диске (экономия RAM)

### Payload fields

| Поле | Тип | Содержимое |
|------|-----|------------|
| `object_name` | str | Точное имя в 1С: `"Справочник.Номенклатура"` |
| `object_type` | str | Тип: `"Справочник"`, `"Документ"`, ... |
| `doc` | str | Полный markdown-текст описания объекта |
| `file_name` | str | Исходный путь к markdown-файлу |
| `friendly_name` | str | `"Тип: Синоним"` → `"Справочник: Номенклатура"` |

- `loader/loader.py:98-103, 155-164`
- ID точки: UUID4 (`loader/loader.py:150`)

---

## 3. RRF / Гибридный поиск

### Что объединяют

**Два dense-вектора** (`object_name` + `friendly_name`) — **НЕ dense+sparse**, **НЕ BM25**. Оба вектора — семантические, один и тот же запросный вектор (query_embedding) используется для обоих prefetch.

### Реализация через Qdrant native RRF

```python
qdrant_client.query_points(
    collection_name=collection_name,
    prefetch=[
        Prefetch(query=query_embedding, using="object_name",   filter=query_filter, limit=limit * 3),
        Prefetch(query=query_embedding, using="friendly_name", filter=query_filter, limit=limit * 3),
    ],
    query=FusionQuery(fusion=Fusion.RRF),
    limit=limit
)
```

- `mcp/mcp_server.py:110-128`

### Параметры

- `PREFETCH_LIMIT_MULTIPLIER` = 3 по умолчанию (`mcp/config.py:37`) → при `limit=5` берётся 15 кандидатов по каждому вектору, затем RRF → топ-5
- Рекомендуемые значения multiplier: 2–5 (`mcp/MULTIVECTOR_SEARCH.md:104`)
- DEFAULT_SEARCH_LIMIT = 5, MAX = 10 (`mcp/config.py:23-25`)

### Обычный поиск (fallback)

Только вектор `friendly_name`, только через REST API (`use_multivector=false`). MCP-инструмент всегда использует RRF (`mcp/mcp_server.py:176`).

---

## 4. Эмбеддер

- **По умолчанию:** `all-MiniLM-L6-v2`, 384 измерения (`embeddings/config.json:3-9`)
- **Альтернативы** (уже прописаны в config):
  - `jinaai/jina-embeddings-v3`: 1024d, поддерживает task-параметр
  - `Qwen/Qwen3-Embedding-0.6B`: 1024d
- **Замена:** изменить `embeddings/config.json` → перезапустить контейнер (`article/article.md:47`)
- **Реализация:** FastAPI-сервис на порту 5000, SentenceTransformer (`embeddings/embedding_service.py:1-8, 138`)
- **Разделение задач:** индексация с `task="retrieval.passage"`, поиск с `task="retrieval.query"` — для моделей типа jina, которые это поддерживают (`loader/loader.py:43`, `mcp/mcp_server.py:74`)

---

## 5. Лицензия

**Задача предполагала отсутствие лицензии, но это неверно.**

В репозитории присутствует файл `LICENSE` с **MIT License**, Copyright (c) 2025 [Sergey Filkin] (`LICENSE:1-3`). MIT разрешает использование, копирование, изменение и распространение при сохранении уведомления об авторских правах.

Технически код использовать можно (MIT), но принятое ранее решение (реш. 1.3, 1.10) о том, что репо не годится в ядро по архитектурным причинам, остаётся в силе: индексирует только метаданные структуры, не тексты модулей; TS-стек для MCP-обёртки нам не нужен. Изучаем только как идеи.

---

## 6. Что стоит перенять в Азимут (идеи, не код)

### Применимо

| Идея | Где у них | Применимость к нам |
|------|-----------|---------------------|
| **Два текста на чанк для разных векторов** | loader.py:107-110 — `object_name` (точное имя) + `friendly_name` (синоним) | У нас для BSL-модулей: один вектор из краткого «заголовка» функции/процедуры, другой — из сигнатуры с комментарием |
| **Payload хранит полный текст, эмбеддится только «ключ»** | loader.py:98-103 — doc в payload, не в эмбеддинге | У нас тексты модулей — эмбеддить фрагмент кода, в payload класть весь контекст |
| **Multivector RRF через Qdrant Prefetch+FusionQuery** | mcp_server.py:110-128 | Прямой образец реализации — точный API уже показан |
| **PREFETCH_LIMIT_MULTIPLIER × limit кандидатов** | config.py:37, MULTIVECTOR_SEARCH.md:103-106 | Хорошая практика: брать 2–5× больше на prefetch, RRF потом сортирует |
| **on_disk=True для векторов** | loader.py:230,236 | Экономия RAM при больших коллекциях |
| **x-collection-name header** | mcp_server.py:166-170 | Удобный паттерн для мультиконфигурационности |
| **task=retrieval.passage / query** | loader.py:43, mcp_server.py:74 | Разделение задач эмбеддинга — нужно применять для jina/моделей с задачами |

### Неприменимо / требует переосмысления

| Аспект | Почему |
|--------|--------|
| **1 объект = 1 чанк без нарезки** | У нас текстовые файлы BSL-кода — нужна реальная нарезка по функциям/процедурам с overlap |
| **Только short-text для эмбеддинга** | У нас длинные тексты кода — нарезку нельзя заменить одним именем, нужно эмбеддить сам код |
| **Нет BM25/sparse** | Их RRF объединяет два dense-вектора разных именований. Для кода имеет смысл рассмотреть dense+BM25 (точные идентификаторы важны) |
| **all-MiniLM-L6-v2 по умолчанию** | Для кода нужна code-специфичная модель (CodeBERT, codebert-base и т.д.) |

---

*DoD: закрыты пункты 1–5. Технические детали с `файл:строка`. Вывод «что перенять» отделён от «код не берём».*
