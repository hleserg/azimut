# 5. Структурный вид (Building Block View)

> arc42 §5 — иерархия строительных блоков: системный контекст → контейнеры → компоненты.
> Диаграммы — в [`workspace.dsl`](../../workspace.dsl) (Structurizr DSL, ADR 0034). Статичные C4-схемы в Mermaid не создаются.
> Запуск: `docker compose --profile diagrams up -d structurizr-proxy` (остановить: `docker compose --profile diagrams down`)

---

## 5.1 Уровень 1 — Системный контекст

**Диаграмма:** view `systemContext` в `workspace.dsl`.

Система «Азимут» — MCP-сервер + ядро понимания кода 1С. Взаимодействует с двумя пользователями и тремя внешними системами.

| Актор / система | Роль | Направление |
|---|---|---|
| Сергей | Лид-разработчик; пользователь everyday и premium-режима | → Азимут |
| Мама | Бухгалтер / 1С-оператор; конечный пользователь-нетехник | → Азимут |
| Платформа 1С | Источник BSL-кода и метаданных через DumpConfigToFiles | → Азимут |
| DeepSeek | Облачная LLM по умолчанию (ADR 0021) | ← Азимут |
| Claude (Anthropic) | LLM-судья и Сергей-премиум (ADR 0021) | ← Азимут |
| ИТС / Портал платформы | Справочные материалы 1С — третий уровень иерархии (ADR 0006) | ← Азимут |

---

## 5.2 Уровень 2 — Контейнеры (whitebox)

**Диаграмма:** view `container` в `workspace.dsl`.

### Клиентские приложения (External)

| Контейнер | Технология | Пользователь | ADR |
|---|---|---|---|
| Cherry Studio | Electron App | Мама + Сергей everyday | [0019](adr/foundation/0019-cherry-studio-default-client.md) |
| Claude Desktop | Desktop App | Сергей premium | [0019](adr/foundation/0019-cherry-studio-default-client.md) |
| mini-ai-1c | Desktop App | Сергей (захват кода из Конфигуратора) | [0019](adr/foundation/0019-cherry-studio-default-client.md) |

Клиенты не входят в кодовую базу Азимута — это External контейнеры (ADR 0018).

### Внешние сервисы (External)

| Контейнер | Технология | Назначение | ADR |
|---|---|---|---|
| mcp-bsl-platform-context | TypeScript / MCP | Справочник платформы 1С (MIT, alkoleft) | [0017](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
| Sentry / GlitchTip | Sentry / GlitchTip | Мониторинг ошибок и трассировка (выбор открыт) | [0028](adr/open/0028-sentry-vs-agpl.md) |

### Наш код

| Контейнер | Технология | Назначение | ADR |
|---|---|---|---|
| MCP-оркестратор | Python / FastMCP | Принимает MCP-запросы; выставляет инструменты; оркестрирует ретривинг и анти-галлюцинации | [0022](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| Азимут-ядро | Python / bsl-atlas fork | Парсеры BSL и метаданных, чанкер, граф вызовов, индексатор, поисковый движок | [0011](adr/foundation/0011-fork-bsl-atlas-as-core.md), [0013](adr/foundation/0013-fork-role-code-engine.md) |
| SQLite | SQLite / FTS5 | Структурный индекс: символы BSL, граф вызовов, объекты метаданных, полнотекстовый поиск | — |
| Векторное хранилище | ChromaDB (текущий) | Коллекции code, metadata, help с эмбеддингами. Целевая замена — Qdrant | [0029](adr/open/0029-multitenancy-qdrant-embedded-vs-server.md) |
| Adapter-слой LLM | Python | Абстракция над облачной LLM; дефолт — DeepSeek V4 | [0020](adr/foundation/0020-cloud-llm-via-adapter.md), [0021](adr/foundation/0021-default-model-deepseek-v4.md) |

**Граница форк / наш код** зафиксирована в ADR 0022: Азимут-ядро = форк bsl-atlas; MCP-оркестратор + Adapter-слой LLM = наш код поверх форка.

**Двухслойная архитектура хранения:** SQLite (структурный, мгновенный, без эмбеддингов) + Векторное хранилище (семантический, с эмбеддингами). Структурные запросы (search_function, get_module_functions, get_function_context, metadatasearch, get_object_details, code_grep) идут через SQLite; семантические (codesearch, helpsearch, search_code_filtered) — через векторное хранилище.

---

## 5.3 Уровень 3 — Компоненты

**Диаграммы:** views `componentCore` и `componentOrch` в `workspace.dsl`.

### 5.3.1 Азимут-ядро (форк bsl-atlas)

| Компонент | Назначение | Код | ADR |
|---|---|---|---|
| Парсеры | BSL-парсер (tree-sitter + regex fallback) + парсер метаданных XML + парсер справки | `src/parsers/` | [0013](adr/foundation/0013-fork-role-code-engine.md) |
| Чанкер | Детерминированная структурная резка: функция = чанк; блоки Если/Цикл/Попытка/Область. LLM не используется | `src/indexer/vector_indexer.py` | [0024](adr/code-processing/0024-code-chunking-deterministic-structural.md) |
| Граф вызовов | BSL-граф вызовов: таблицы symbols/calls, get_function_context (calls + called_by) | `src/storage/sqlite_store.py` | [0013](adr/foundation/0013-fork-role-code-engine.md) |
| Same-Named Resolver | Резолв одноимённых процедур (proposed — главный технический риск) | — | [0025](adr/code-processing/0025-resolve-same-named-procedures.md) |
| Индексатор | Инкрементальная индексация + эмбеддинг: manifest-diff, SHA-256 кеш, file_tracker, провайдеры эмбеддингов | `src/indexer/` | [0027](adr/code-processing/0027-port-feenlace-techniques-to-python.md), [0020](adr/foundation/0020-cloud-llm-via-adapter.md) |
| Поисковый движок | Гибридный поиск: семантический + структурный (FTS5) + code_grep + реранкер. Маршрутизация: graph → metadata → grep | `src/search/` | [0026](adr/code-processing/0026-code-search-routing.md), [0002](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) |
| BSL Synonyms RU↔EN | Нормализация BSL-синонимов: СтрНайти↔StrFind (~40 ключевых слов + ~180 функций) | — | [0027](adr/code-processing/0027-port-feenlace-techniques-to-python.md) |

### 5.3.2 MCP-оркестратор

| Компонент | Назначение | Код | ADR |
|---|---|---|---|
| MCP Tools | MCP-инструменты: search_function, codesearch, helpsearch, code_grep, metadatasearch, get_object_details, reindex, stats | `src/main.py` | — |
| Server-Controlled Retrieval | Планка релевантности, триггер добора, потолок окна контекста | — | [0005](adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md) |
| Source Arbiter | Иерархия источников (код → справка → ИТС) + метрика противоречивости | — | [0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md), [0001](adr/anti-hallucinations/0001-р1-metric-contradiction.md) |
| LLM Judge | LLM-судья со спан-привязкой: арбитрирует faithfulness и groundedness через Claude API | — | [0003](adr/anti-hallucinations/0003-р3-llm-judge-spans.md) |
| Groundedness Detector | Три уровня реакции на сигнал LLM-судьи: блок / плашка / лог (proposed) | — | [0008](adr/anti-hallucinations/0008-п1-groundedness-detector.md) |
| Recovery Pipeline | Повторный проход ретривера + переключение в дип-ресёрч (proposed, объединяет П2+Р7) | — | [0009](adr/anti-hallucinations/0009-п2-re-retrieval.md), [0007](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md) |
| Query Sufficiency Gate | Гейт «слишком общий запрос» + подсказки агенту (proposed) | — | [0010](adr/anti-hallucinations/0010-п3-query-sufficiency.md) |

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
