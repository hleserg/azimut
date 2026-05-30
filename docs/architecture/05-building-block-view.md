# 5. Структурный вид (Building Block View)

> arc42 §5 — иерархия строительных блоков: системный контекст → контейнеры → компоненты.
> Диаграммы — в [`workspace.dsl`](../../workspace.dsl) (Structurizr DSL, ADR 0034). Статичные C4-схемы в Mermaid не создаются.
> Запуск: `docker compose --profile diagrams up -d structurizr-proxy` (остановить: `docker compose --profile diagrams down`)

## 5.0 Конвенции

### 5.0.1 Контейнер = пакет, компонент = модуль

В строгом C4 контейнер — это runtime boundary (отдельно запускаемый процесс / БД / файловая система). У нас MCP-сервер и Азимут-ядро формально живут в одном Python-процессе, поэтому конвенция проекта мягче:

- **Контейнер (C2)** — логическая подсистема, обычно соответствует Python-пакету (`src/<package>/`) или БД.
- **Компонент (C3)** — модуль внутри пакета (`src/<package>/<module>.py`) или класс с публичным интерфейсом.

Граница «наш код / форк bsl-atlas» (ADR 0022) — это группа контейнеров (Structurizr `group`), а не отдельный контейнер. Это позволяет видеть и ownership, и реальное устройство кода.

### 5.0.2 Связи

- **Направление**: стрелка от инициатора (кто зовёт) к получателю.
- **Технология** (значение по умолчанию — sync request-response):
  - `Python API` — кросс-контейнерный in-process вызов (Python import + function call)
  - `in-process` — компонент → компонент внутри одного контейнера
  - `ChromaDB API`, `SQLite API` — sync, embedded клиенты
  - `MCP / JSON-RPC` — sync request-response (stdio / http transport)
  - `HTTPS / X` — sync request-response
  - `HTTPS / X (fire-and-forget)` — async без ожидания ответа (Sentry SDK)
  - `Python API (async background)` — через FastAPI BackgroundTask (HTTP `/reindex`)
  - `File system` — чтение файлов
- **Подпись** — конкретный API-вызов / поток данных, без vague "uses"/"использует".

---

## 5.1 Уровень 1 — Системный контекст

**Диаграмма:** view `systemContext` в `workspace.dsl`.

Система «Азимут» — MCP-сервер для понимания кода 1С. Взаимодействует с двумя пользователями и несколькими внешними системами.

| Актор / система | Роль | Направление |
|---|---|---|
| Сергей | Лид-разработчик; пользователь everyday и premium-режима | → Азимут |
| Мама | Бухгалтер / 1С-оператор; конечный пользователь-нетехник | → Азимут |
| Платформа 1С | Источник BSL-кода, XML-конфигурации, HTML-справки через DumpConfigToFiles | → Азимут |
| MCP-клиенты (Cherry Studio / Claude Desktop / mini-ai-1c) | Десктоп-клиенты по ролям (ADR 0019), группа на диаграмме | → Азимут |
| Облачные LLM (DeepSeek / Claude) | Разговорная модель + LLM-судья (ADR 0021), группа на диаграмме | ← Азимут |
| ИТС / Портал платформы | Справочные материалы — третий уровень иерархии (ADR 0006) | ← Азимут |
| mcp-bsl-platform-context | Drop-in справочник платформы 1С (ADR 0017) | ← Азимут |
| Sentry / GlitchTip | Мониторинг ошибок (ADR 0028) | ← Азимут |

> **Cross-Encoder Reranker** (HTTP-сервис, опц., ADR 0002) намеренно скрыт из C1 — это техническая деталь Hybrid Search; виден в C2 (container view).

---

## 5.2 Уровень 2 — Контейнеры

**Диаграмма:** view `container` в `workspace.dsl`.

### Клиентские приложения (External, ADR 0019)

| Контейнер | Технология | Пользователь | ADR |
|---|---|---|---|
| Cherry Studio | Electron App | Мама + Сергей everyday | [0019](adr/foundation/0019-cherry-studio-default-client.md) |
| Claude Desktop | Desktop App | Сергей premium | [0019](adr/foundation/0019-cherry-studio-default-client.md) |
| mini-ai-1c | Desktop App | Сергей (захват кода из Конфигуратора) | [0019](adr/foundation/0019-cherry-studio-default-client.md) |

### Внешние сервисы

| Контейнер | Технология | Назначение | ADR |
|---|---|---|---|
| mcp-bsl-platform-context | TypeScript / MCP | Справочник платформы 1С (MIT, alkoleft) | [0017](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
| Cross-Encoder Reranker | HTTP / Python | Опциональный реранкер (BGE-reranker / Cohere) | [0002](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) |
| Sentry / GlitchTip | Sentry / GlitchTip | Мониторинг ошибок (выбор открыт) | [0028](adr/open/0028-sentry-vs-agpl.md) |

### Группа «Наш код» (поверх форка, ADR 0022)

| Контейнер | Технология | Пакет / назначение | ADR |
|---|---|---|---|
| MCP-сервер | Python / FastMCP | `src/main.py`, `src/config.py` — точка входа, MCP-инструменты, lifespan, HTTP-эндпоинты | [0022](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| Anti-Hallucination Pipeline | Python (планируется) | Будущий `src/quality/` — гарантии качества ответа | [0022](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| Adapter-слой LLM | Python (планируется) | Будущий `src/adapters/llm/` — абстракция над разговорной LLM | [0020](adr/foundation/0020-cloud-llm-via-adapter.md), [0021](adr/foundation/0021-default-model-deepseek-v4.md) |

### Группа «Форк bsl-atlas» (движок понимания кода, ADR 0013)

| Контейнер | Технология | Пакет / назначение | ADR |
|---|---|---|---|
| Парсеры | Python / tree-sitter | `src/parsers/` — BSL, XML, текстовые дампы, HTML-справка | [0013](adr/foundation/0013-fork-role-code-engine.md) |
| Индексатор | Python | `src/indexer/` — vector_indexer, embeddings, file_tracker | [0027](adr/code-processing/0027-port-feenlace-techniques-to-python.md) |
| Поисковый движок | Python | `src/search/` — гибридный поиск + code_grep | [0026](adr/code-processing/0026-code-search-routing.md) |
| Хранилище | Python | `src/storage/` — DAL над SQLite, модели | [0013](adr/foundation/0013-fork-role-code-engine.md) |

### Data stores

| Контейнер | Технология | Назначение |
|---|---|---|
| SQLite | SQLite / FTS5 | Структурный индекс (`/data/bsl_index.db`): symbols, calls, objects, attributes, FTS5 |
| File Tracker DB | SQLite | Отдельная БД для file_tracker (`/data/chroma_db/file_tracker.db`): хеши и статусы индексации |
| Векторное хранилище | ChromaDB | Коллекции code, metadata, help. Целевая замена — Qdrant (ADR [0029](adr/open/0029-multitenancy-qdrant-embedded-vs-server.md)) |

---

## 5.3 Уровень 3 — Компоненты

**Диаграммы:** views `componentParsers`, `componentIndexer`, `componentSearchEngine`, `componentStorage`, `componentMcpServer`, `componentAntiHall`, `componentLlmAdapter` в `workspace.dsl`.

### 5.3.1 MCP-сервер

| Компонент | Файл | Назначение |
|---|---|---|
| FastMCP App | `src/main.py` | Регистрация MCP-инструментов, HTTP-эндпоинтов (/health, /reindex), init_services, lifespan |
| Config | `src/config.py` | Конфигурация из env: пути, провайдеры эмбеддингов, режимы индексации |

### 5.3.2 Парсеры

| Компонент | Файл | Назначение |
|---|---|---|
| BSL Code Parser | `src/parsers/code.py` | Парсер BSL: основной API над tree-sitter с regex fallback |
| Tree-sitter Parser | `src/parsers/tree_sitter_parser.py` | Загрузка нативной библиотеки tree-sitter-bsl, инициализация |
| Metadata XML Parser | `src/parsers/metadata_xml.py` | XML-выгрузка конфигуратора 1С (DumpConfigToFiles) |
| Metadata Text Parser | `src/parsers/metadata.py` | Текстовые дампы метаданных (legacy fallback) |
| Help Parser | `src/parsers/help.py` | HTML-справка 1С через BeautifulSoup → markdownify |

### 5.3.3 Индексатор

| Компонент | Файл | Назначение | ADR |
|---|---|---|---|
| Vector Indexer | `src/indexer/vector_indexer.py` | Главный класс индексации: parallel collection, batch-индекс, function-level hash | [0024](adr/code-processing/0024-code-chunking-deterministic-structural.md) |
| Embedding Providers | `src/indexer/embeddings.py` | OpenAI / OpenRouter / Ollama / Cohere / Jina + локальный fallback | [0020](adr/foundation/0020-cloud-llm-via-adapter.md) |
| File Tracker | `src/indexer/file_tracker.py` | Отслеживание изменений по SHA-256 (file-level и function-level) | [0027](adr/code-processing/0027-port-feenlace-techniques-to-python.md) |

> **Note:** Embedding Providers концептуально относится к Adapter-слою LLM (ADR 0020), но физически живёт в `src/indexer/` из-за тесной связки с индексацией. Планируется переезд в `src/adapters/`.

### 5.3.4 Поисковый движок

| Компонент | Файл | Назначение | ADR |
|---|---|---|---|
| Hybrid Search | `src/search/hybrid.py` | Гибридный поиск по ChromaDB: fulltext для single-word, vector для multi-word; вызов реранкера по HTTP | [0026](adr/code-processing/0026-code-search-routing.md), [0002](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) |
| Code Grep | `src/search/code_grep.py` | Текстовый поиск с AST-контекстом; FTS5 в SQLite с fallback на сканирование | [0026](adr/code-processing/0026-code-search-routing.md) |

### 5.3.5 Хранилище

| Компонент | Файл | Назначение |
|---|---|---|
| SQLite Store | `src/storage/sqlite_store.py` | Schema DDL, индексация BSL и метаданных, find_function, get_module_functions, get_function_context, search_metadata, code_grep по FTS5 |
| Data Models | `src/storage/models.py` | Dataclasses: BSLFunction, FunctionInfo, FunctionContext, MetadataObject, ObjectDetails, Attribute, TabPart, IndexStats |

### 5.3.6 Anti-Hallucination Pipeline (планируется)

| Компонент | Назначение | ADR |
|---|---|---|
| Server-Controlled Retrieval | Планка релевантности, триггер добора, потолок окна контекста | [0005](adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md) |
| Source Hierarchy | Иерархия источников при конфликте: код → справка → ИТС | [0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md) |
| Contradiction Metric | Метрика противоречивости источников ПЕРЕД выдачей ответа | [0001](adr/anti-hallucinations/0001-р1-metric-contradiction.md) |
| LLM Judge | LLM-судья со спан-привязкой через Claude API | [0003](adr/anti-hallucinations/0003-р3-llm-judge-spans.md) |
| Groundedness Detector | Три уровня реакции на сигнал судьи (proposed) | [0008](adr/anti-hallucinations/0008-п1-groundedness-detector.md) |
| Re-Retrieval Controller | Второй проход ретривера (proposed) | [0009](adr/anti-hallucinations/0009-п2-re-retrieval.md) |
| Fallback Mode | Дип-ресёрч после N исчерпанных повторов (proposed) | [0007](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md) |
| Query Sufficiency Gate | Гейт «слишком общий запрос» (proposed) | [0010](adr/anti-hallucinations/0010-п3-query-sufficiency.md) |

### 5.3.7 Adapter-слой LLM (планируется)

| Компонент | Назначение | ADR |
|---|---|---|
| Conversational LLM Adapter | Унифицированный интерфейс к DeepSeek / Claude / Qwen / Yandex | [0021](adr/foundation/0021-default-model-deepseek-v4.md) |

---

## 5.4 Реестр доноров

Открытые компоненты, из которых взяты идеи или код; лицензионный статус верифицирован по ADR 0023.

| Донор | Лицензия | Статус лицензии | Что взято | ADR |
|---|---|---|---|---|
| bsl-atlas (Arman Kudaibergenov) | AGPL-3.0 | ✅ проверено: `LICENSE`, `COPYRIGHT` репо | Форк-ядро: парсер BSL, граф вызовов, каркас MCP, docker | [0011](adr/foundation/0011-fork-bsl-atlas-as-core.md) |
| FSerg/mcp-1c-v1 (Sergey Filkin) | MIT | ✅ проверено: LICENSE репо (см. ADR 0023, исправление #3 в `_resolutions.md`) | Payload-схема Qdrant + RRF-слияние как референс; код не копируется | [0014](adr/foundation/0014-fserg-mcp-1c-as-reference-only.md) |
| alkoleft/mcp-bsl-platform-context | MIT | ✅ проверено: LICENSE репо (ADR 0023) | Drop-in MCP-сервер справочника платформы 1С | [0017](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
| 1c-mcp-metacode | ⚠️ closed | ⚠️ предположение: публичного репо нет; использовать только как архитектурный референс | Схема граф-резолва как референс ADR 0025; код не копируется | [0025](adr/code-processing/0025-resolve-same-named-procedures.md) |
| mcp-1c/feenlace | MIT | ⚠️ предположение: требует проверки LICENSE перед портированием | Техники скорости: кеш по SHA, манифест-diff, шардирование | [0027](adr/code-processing/0027-port-feenlace-techniques-to-python.md) |

> **Правило:** перед добавлением нового донора — проверить лицензию по ADR 0023. Без `✅ проверено` — не копировать код.
