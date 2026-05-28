# Архитектурный state (auto-generated)
> Сгенерировано 2026-05-28 скриптом `scripts/dump_arch_state.py` (HLE-543). **Не редактировать вручную** — перегенерируется из `workspace.dsl` + frontmatter ADR.
> Stats: 10 systems, 4 containers, 16 components · 35 ADRs (22 accepted, 11 proposed, 0 superseded) · 2 people.

## Пользователи

### Сергей

Лид-разработчик; основной пользователь системы на ежедневной основе.

**Использует:**
  - → **Cherry Studio** [Desktop GUI] — использует everyday
  - → **Claude Desktop** [Desktop GUI] — использует для сложного кода
  - → **mini-ai-1c** [Desktop GUI] — захватывает код из Конфигуратора

### Мама

Бухгалтер / 1С-оператор; конечный пользователь-нетехник.

**Использует:**
  - → **Cherry Studio** [Desktop GUI] — задаёт вопросы по 1С

<a id="softwaresystem-платформа-1с"></a>
## SoftwareSystem: Платформа 1С

Конфигурации ERP/Бухгалтерия; источник BSL-кода и метаданных через DumpConfigToFiles.

**Tags**: `External`

- **ADR**: —
- **Open issues**: —

**Связи (исходящие):**
  - → **Азимут-ядро** [DumpConfigToFiles / File system] — передаёт BSL-код и метаданные
  - → **Азимут** [DumpConfigToFiles / File system] — передаёт BSL-код и метаданные

<a id="softwaresystem-deepseek"></a>
## SoftwareSystem: DeepSeek

Облачная разговорная модель (дефолт): DeepSeek V4 Flash (обычный код) / Pro (тяжёлый код); ADR 0021.

**Tags**: `External`

- **ADR**: —
- **Open issues**: —

<a id="softwaresystem-claude-anthropic"></a>
## SoftwareSystem: Claude (Anthropic)

Облачная LLM для LLM-судьи и Сергея-премиум; Anthropic API; ADR 0021.

**Tags**: `External`

- **ADR**: —
- **Open issues**: —

<a id="softwaresystem-итс-портал-платформы"></a>
## SoftwareSystem: ИТС / Портал платформы

Справочные материалы 1С; третий уровень иерархии источников (Р6, ADR 0006).

**Tags**: `External`

- **ADR**: —
- **Open issues**: —

<a id="softwaresystem-cherry-studio"></a>
## SoftwareSystem: Cherry Studio

MCP-клиент по умолчанию для Мамы и Сергея-everyday; подключается к MCP-оркестратору по JSON-RPC (ADR 0019).

**Tags**: `External`

- **ADR**: [`0019-cherry-studio-default-client.md`](../docs/architecture/adr/foundation/0019-cherry-studio-default-client.md) — Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода) *(accepted)*
- **Open issues**: —

**Связи (исходящие):**
  - → **MCP-оркестратор** [MCP / JSON-RPC] — вызывает инструменты
  - → **Азимут** [MCP / JSON-RPC] — вызывает инструменты

<a id="softwaresystem-claude-desktop"></a>
## SoftwareSystem: Claude Desktop

MCP-клиент для Сергея-премиум дома; поддерживает несколько MCP-серверов параллельно (ADR 0019).

**Tags**: `External`

- **ADR**: [`0019-cherry-studio-default-client.md`](../docs/architecture/adr/foundation/0019-cherry-studio-default-client.md) — Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода) *(accepted)*
- **Open issues**: —

**Связи (исходящие):**
  - → **MCP-оркестратор** [MCP / JSON-RPC] — вызывает инструменты
  - → **Азимут** [MCP / JSON-RPC] — вызывает инструменты

<a id="softwaresystem-mini-ai-1c"></a>
## SoftwareSystem: mini-ai-1c

Клиент Сергея для захвата BSL-кода непосредственно из Конфигуратора 1С (ADR 0019).

**Tags**: `External`

- **ADR**: [`0019-cherry-studio-default-client.md`](../docs/architecture/adr/foundation/0019-cherry-studio-default-client.md) — Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода) *(accepted)*
- **Open issues**: —

**Связи (исходящие):**
  - → **MCP-оркестратор** [MCP / JSON-RPC] — вызывает инструменты
  - → **Азимут** [MCP / JSON-RPC] — вызывает инструменты

<a id="softwaresystem-mcp-bsl-platform-context"></a>
## SoftwareSystem: mcp-bsl-platform-context

Drop-in MCP-сервер: справочник платформы 1С (MIT, alkoleft). Второй MCP-сервер рядом с Азимутом (ADR 0017).

**Tags**: `External`

- **ADR**: [`0017-mcp-bsl-platform-context-included.md`](../docs/architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md) — `alkoleft/mcp-bsl-platform-context` берём в фундамент (drop-in вторым MCP, MIT, бесплатно) *(accepted)*
- **Open issues**: —

<a id="softwaresystem-sentry-glitchtip"></a>
## SoftwareSystem: Sentry / GlitchTip

Мониторинг ошибок и распределённая трассировка. Выбор между Sentry SaaS и self-hosted GlitchTip открыт (ADR 0028).

**Tags**: `External, Proposed`

- **ADR**: [`0028-sentry-vs-agpl.md`](../docs/architecture/adr/open/0028-sentry-vs-agpl.md) — Конфликт AGPL × Sentry for Open Source — ждём ответ Sentry; если откажут — план Б *(proposed)*
- **Open issues**: [`0028-sentry-vs-agpl.md`](../docs/architecture/adr/open/0028-sentry-vs-agpl.md) — Конфликт AGPL × Sentry for Open Source — ждём ответ Sentry; если откажут — план Б *(proposed)*

<a id="softwaresystem-азимут"></a>
## SoftwareSystem: Азимут

MCP-сервер + Азимут-ядро: понимание кода 1С, RAG, анти-галлюцинации. Форк bsl-atlas под AGPL-3.0 (ADR 0011).

- **ADR**: [`0011-fork-bsl-atlas-as-core.md`](../docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md) — Основа — форк `bsl-atlas` (AGPL-3.0) как ядро понимания кода 1С *(accepted)*
- **Open issues**: —

**Связи (исходящие):**
  - → **DeepSeek** [HTTPS / OpenAI-compatible API] — генерирует текст
  - → **mcp-bsl-platform-context** [MCP / JSON-RPC] — запрашивает справку платформы 1С
  - → **Sentry / GlitchTip** [HTTPS / Sentry SDK] — отправляет трассировки и ошибки
  - → **ИТС / Портал платформы** [HTTPS] — ищет справочные материалы (Р6, ADR 0006)
  - → **Claude (Anthropic)** [HTTPS / Anthropic API] — арбитрирует качество ответа

<a id="container-mcp-оркестратор"></a>
### Container: MCP-оркестратор

- **Технология**: `Python / FastMCP`
- **Описание**: Принимает MCP-запросы клиентов; управляет ретривингом, иерархией источников, LLM-судьёй, фолбэком. Граница форк vs наш код (ADR 0022).
- **ADR**: [`0022-boundary-fork-vs-own-code.md`](../docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md) — Граница «форк/готовые библиотеки vs наш код» — форк даёт понимание кода, библиотеки дают механику RAG, наш код — поведение, гарантии, оркестрацию *(accepted)*
- **Open issues**: [`0028-sentry-vs-agpl.md`](../docs/architecture/adr/open/0028-sentry-vs-agpl.md) — Конфликт AGPL × Sentry for Open Source — ждём ответ Sentry; если откажут — план Б *(proposed)*
- **Исходящие**:
  - → **Азимут-ядро** [Python API] — запрашивает индекс кода
  - → **Qdrant** [HTTP / Qdrant API] — читает векторы и метаданные
  - → **Adapter-слой LLM** [HTTPS / JSON] — генерирует ответ и фолбэк
  - → **mcp-bsl-platform-context** [MCP / JSON-RPC] — запрашивает справку платформы 1С
  - → **Sentry / GlitchTip** [HTTPS / Sentry SDK] — отправляет трассировки и ошибки
  - → **ИТС / Портал платформы** [HTTPS] — ищет справочные материалы (Р6, ADR 0006)
  - → **BSL Synonyms RU↔EN** [Python API] — нормализует запрос рус↔англ
  - → **Claude (Anthropic)** [HTTPS / Anthropic API] — арбитрирует качество ответа
- **Входящие**:
  - ← **Cherry Studio** [MCP / JSON-RPC] — вызывает инструменты
  - ← **Claude Desktop** [MCP / JSON-RPC] — вызывает инструменты
  - ← **mini-ai-1c** [MCP / JSON-RPC] — вызывает инструменты
  - ← **Азимут-ядро** [in-process] — возвращает реранкированные результаты
  - ← **Реранкер** [in-process] — возвращает реранкированные результаты

<a id="component-query-sufficiency-gate"></a>
#### Component: Query Sufficiency Gate ⚠️ **proposed**

- **Технология**: `Python`
- **Описание**: Три механики на сервере: гейт «слишком общий запрос», подсказки агенту на основе индекса, проверка дрейфа переформулировки (П3, ADR 0010 proposed).
- **Tags**: `Proposed`
- **ADR**: [`0010-п3-query-sufficiency.md`](../docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md) — Оценка достаточности запроса + подсказки агенту что переспросить *(proposed)*
- **Open issues**: [`0010-п3-query-sufficiency.md`](../docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md) — Оценка достаточности запроса + подсказки агенту что переспросить *(proposed)*
- **Исходящие**:
  - → **Server-Controlled Retrieval** [in-process] — пропускает только осмысленные запросы
- **Входящие**:
  - (нет)

<a id="component-server-controlled-retrieval"></a>
#### Component: Server-Controlled Retrieval

- **Технология**: `Python`
- **Описание**: Контроль ретривинга на стороне сервера: планка релевантности, триггер добора, потолок окна контекста (Р5, ADR 0005).
- **ADR**: [`0005-р5-server-controlled-retrieval.md`](../docs/architecture/adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md) — Контроль ретривинга — на сервере (планка релевантности, триггер добора, потолок окна) *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Route Dispatcher** [in-process] — триггерит добор у диспетчера
- **Входящие**:
  - ← **Query Sufficiency Gate** [in-process] — пропускает только осмысленные запросы
  - ← **Re-Retrieval Controller** [in-process] — запрашивает повтор в рамках бюджета окна

<a id="component-route-dispatcher"></a>
#### Component: Route Dispatcher

- **Технология**: `Python`
- **Описание**: Диспетчер поиска по коду: fallback-цепочка graph → metadata → grep по образцу comol/ai_rules_1c. Код: src/search/ (ADR 0026).
- **ADR**: [`0026-code-search-routing.md`](../docs/architecture/adr/code-processing/0026-code-search-routing.md) — Роутинг поиска по коду — fallback-цепочка graph → metadata → grep *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Азимут-ядро** [Python API] — маршрутизирует поиск (graph → metadata → grep)
  - → **BSL Synonyms RU↔EN** [Python API] — нормализует запрос рус↔англ
  - → **Adapter-слой LLM** [Python API] — запрашивает синтез ответа через разговорную модель (ADR 0021)
- **Входящие**:
  - ← **Server-Controlled Retrieval** [in-process] — триггерит добор у диспетчера
  - ← **Азимут-ядро** [in-process] — возвращает реранкированные результаты
  - ← **Реранкер** [in-process] — возвращает реранкированные результаты

<a id="component-source-hierarchy"></a>
#### Component: Source Hierarchy

- **Технология**: `Python`
- **Описание**: Иерархия источников при конфликте: код → справка → ИТС. Применяет метрику противоречивости (Р6, ADR 0006).
- **ADR**: [`0006-р6-source-hierarchy.md`](../docs/architecture/adr/anti-hallucinations/0006-р6-source-hierarchy.md) — Иерархия источников при конфликте: код → справка → ИТС *(accepted)*
- **Open issues**: [`0033-r1-contradiction-detection-mechanics.md`](../docs/architecture/adr/open/0033-r1-contradiction-detection-mechanics.md) — Механика детектирования противоречивости — как технически детектировать, порог, поведение при множестве конфликтов *(proposed)*
- **Исходящие**:
  - → **Contradiction Metric** [in-process] — передаёт результаты на проверку
- **Входящие**:
  - (нет)

<a id="component-contradiction-metric"></a>
#### Component: Contradiction Metric

- **Технология**: `Python`
- **Описание**: Метрика противоречивости источников ПЕРЕД выдачей ответа. Механика детектирования открыта (Р1, ADR 0001; см. ADR 0033).
- **ADR**: [`0001-р1-metric-contradiction.md`](../docs/architecture/adr/anti-hallucinations/0001-р1-metric-contradiction.md) — Метрика противоречивости источников ПЕРЕД выдачей *(accepted)*
- **Open issues**: [`0033-r1-contradiction-detection-mechanics.md`](../docs/architecture/adr/open/0033-r1-contradiction-detection-mechanics.md) — Механика детектирования противоречивости — как технически детектировать, порог, поведение при множестве конфликтов *(proposed)*
- **Исходящие**:
  - → **LLM Judge** [in-process] — передаёт спорные случаи арбитру
- **Входящие**:
  - ← **Source Hierarchy** [in-process] — передаёт результаты на проверку

<a id="component-llm-judge"></a>
#### Component: LLM Judge

- **Технология**: `Python / Claude API`
- **Описание**: LLM-судья со спан-привязкой: арбитрирует faithfulness и groundedness ответа через Claude API (Р3, ADR 0003).
- **ADR**: [`0003-р3-llm-judge-spans.md`](../docs/architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md) — LLM-судья со спан-привязкой (Claude как арбитр) *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Claude (Anthropic)** [HTTPS / Anthropic API] — арбитрирует качество ответа
  - → **Groundedness Detector** [in-process] — передаёт сигнал недогрунтованности
- **Входящие**:
  - ← **Contradiction Metric** [in-process] — передаёт спорные случаи арбитру

<a id="component-groundedness-detector"></a>
#### Component: Groundedness Detector ⚠️ **proposed**

- **Технология**: `Python`
- **Описание**: Три уровня реакции на сигнал LLM-судьи: блок-и-возврат / плашка «частично из общих знаний» / лог в Sentry (П1, ADR 0008 proposed).
- **Tags**: `Proposed`
- **ADR**: [`0008-п1-groundedness-detector.md`](../docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md) — Детектор «relevance высокий / groundedness низкий» — 3 уровня действий *(proposed)*
- **Open issues**: [`0008-п1-groundedness-detector.md`](../docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md) — Детектор «relevance высокий / groundedness низкий» — 3 уровня действий *(proposed)*
- **Исходящие**:
  - → **Re-Retrieval Controller** [in-process] — триггерит повторный проход (уровень 1)
  - → **Sentry / GlitchTip** [HTTPS / Sentry SDK] — лог уровней 2/3
- **Входящие**:
  - ← **LLM Judge** [in-process] — передаёт сигнал недогрунтованности

<a id="component-re-retrieval-controller"></a>
#### Component: Re-Retrieval Controller ⚠️ **proposed**

- **Технология**: `Python`
- **Описание**: Второй проход ретривера по переформулированному запросу. Инициатор — агент, исполнитель — сервер; гейт N повторов на запрос (П2, ADR 0009 proposed).
- **Tags**: `Proposed`
- **ADR**: [`0009-п2-re-retrieval.md`](../docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md) — Второй проход ретривера при неуверенности (открытый триггер) *(proposed)*
- **Open issues**: [`0009-п2-re-retrieval.md`](../docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md) — Второй проход ретривера при неуверенности (открытый триггер) *(proposed)*
- **Исходящие**:
  - → **Server-Controlled Retrieval** [in-process] — запрашивает повтор в рамках бюджета окна
  - → **Fallback Mode** [in-process] — переключает в дип-ресёрч после N исчерпанных повторов (Р7, ADR 0007/0009)
- **Входящие**:
  - ← **Groundedness Detector** [in-process] — триггерит повторный проход (уровень 1)

<a id="component-fallback-mode"></a>
#### Component: Fallback Mode

- **Технология**: `Python`
- **Описание**: Фолбэк = смена режима (дип-ресёрч с тем же контрактом); заменил «честный тупик» Р4. (Р7, ADR 0007).
- **ADR**: [`0007-р7-fallback-mode-switch.md`](../docs/architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md) — Фолбэк = смена режима (дип-ресёрч в интернете с тем же контрактом) *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Adapter-слой LLM** [Python API] — инициирует дип-ресёрч
- **Входящие**:
  - ← **Re-Retrieval Controller** [in-process] — переключает в дип-ресёрч после N исчерпанных повторов (Р7, ADR 0007/0009)

<a id="container-азимут-ядро"></a>
### Container: Азимут-ядро

- **Технология**: `Python / bsl-atlas fork`
- **Описание**: Форк bsl-atlas: парсер BSL, чанкер, индексатор, граф вызовов, резолвер, эмбеддер, реранкер. Роль форка — только «движок понимания кода» (ADR 0013).
- **ADR**: [`0013-fork-role-code-engine.md`](../docs/architecture/adr/foundation/0013-fork-role-code-engine.md) — Роль `bsl-atlas`: только «движок понимания кода» (берём парсер BSL + граф вызовов + каркас MCP + docker; меняем хранилище/эмбеддер/реранк; дописываем поведенческий контракт и оркестрацию) *(accepted)*
- **Open issues**: [`0025-resolve-same-named-procedures.md`](../docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md) — Алгоритм резолва одноимённых процедур — открытая инженерная задача *(proposed)*
- **Исходящие**:
  - → **Qdrant** [HTTP / gRPC] — читает и сохраняет векторы
  - → **Route Dispatcher** [in-process] — возвращает реранкированные результаты
  - → **MCP-оркестратор** [in-process] — возвращает реранкированные результаты
- **Входящие**:
  - ← **Платформа 1С** [DumpConfigToFiles / File system] — передаёт BSL-код и метаданные
  - ← **MCP-оркестратор** [Python API] — запрашивает индекс кода
  - ← **Route Dispatcher** [Python API] — маршрутизирует поиск (graph → metadata → grep)

<a id="component-чанкер"></a>
#### Component: Чанкер

- **Технология**: `Python`
- **Описание**: Детерминированная структурная резка: функция = чанк (≤ порога); блоки Если/Цикл/Попытка/Область с шапкой контекста; запросы режутся по `|;`, ВТ помечаются. LLM не используем. Код: src/parsers/ (ADR 0024).
- **ADR**: [`0024-code-chunking-deterministic-structural.md`](../docs/architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md) — Детерминированная структурная резка кода поверх Азимута *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Индексатор** [in-process] — передаёт чанки на индексацию
- **Входящие**:
  - (нет)

<a id="component-индексатор"></a>
#### Component: Индексатор

- **Технология**: `Python`
- **Описание**: Инкрементальная индексация: manifest-diff {path: mtime+size}, дисковый кеш по SHA-256, шардирование по cpu_count(), GC-tuning на этапе batch. Код: src/indexer/ (ADR 0027).
- **ADR**: [`0027-port-feenlace-techniques-to-python.md`](../docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md) — Портировать техники `mcp-1c` (feenlace) в Python — не переписывать на Go *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Граф вызовов** [in-process] — передаёт обогащённый поток
- **Входящие**:
  - ← **Чанкер** [in-process] — передаёт чанки на индексацию

<a id="component-граф-вызовов"></a>
#### Component: Граф вызовов

- **Технология**: `Python`
- **Описание**: Построение графа BSL-вызовов; типизация процедур/функций; рёбра событие→обработчик достраиваем поверх metacode-подхода. SQLite-таблицы routines/calls. Код: src/storage/.
- **ADR**: [`0013-fork-role-code-engine.md`](../docs/architecture/adr/foundation/0013-fork-role-code-engine.md) — Роль `bsl-atlas`: только «движок понимания кода» (берём парсер BSL + граф вызовов + каркас MCP + docker; меняем хранилище/эмбеддер/реранк; дописываем поведенческий контракт и оркестрацию) *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Same-Named Resolver** [in-process] — передаёт calls(callee_id NULL) на резолв
- **Входящие**:
  - ← **Индексатор** [in-process] — передаёт обогащённый поток

<a id="component-same-named-resolver"></a>
#### Component: Same-Named Resolver ⚠️ **proposed**

- **Технология**: `Python`
- **Описание**: Резолв одноимённых процедур: routines + calls(callee_id NULL) → пост-проход. Алгоритм не написан — главный технический риск темы 2 (ADR 0025 proposed).
- **Tags**: `Proposed`
- **ADR**: [`0025-resolve-same-named-procedures.md`](../docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md) — Алгоритм резолва одноимённых процедур — открытая инженерная задача *(proposed)*
- **Open issues**: [`0025-resolve-same-named-procedures.md`](../docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md) — Алгоритм резолва одноимённых процедур — открытая инженерная задача *(proposed)*
- **Исходящие**:
  - → **Эмбеддер** [in-process] — передаёт resolved-чанки на векторизацию
- **Входящие**:
  - ← **Граф вызовов** [in-process] — передаёт calls(callee_id NULL) на резолв

<a id="component-bsl-synonyms-ru-en"></a>
#### Component: BSL Synonyms RU↔EN

- **Технология**: `Python`
- **Описание**: Анализатор синонимов BSL: СтрНайти↔StrFind, ~40 ключевых слов + ~180 функций. Подключается к Embedder и Route Dispatcher для нормализации запросов (ADR 0027).
- **ADR**: [`0027-port-feenlace-techniques-to-python.md`](../docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md) — Портировать техники `mcp-1c` (feenlace) в Python — не переписывать на Go *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Эмбеддер** [in-process] — предоставляет словарь синонимов
- **Входящие**:
  - ← **MCP-оркестратор** [Python API] — нормализует запрос рус↔англ
  - ← **Route Dispatcher** [Python API] — нормализует запрос рус↔англ

<a id="component-эмбеддер"></a>
#### Component: Эмбеддер

- **Технология**: `Python`
- **Описание**: Векторизация чанков: BGE-M3 локально по умолчанию; Cohere Embed опционально через адаптер (ADR 0020).
- **ADR**: [`0020-cloud-llm-via-adapter.md`](../docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md) — Разговорная модель — облачная и подключаемая через адаптер; внутри MCP-сервера нет разговорной LLM; лёгкие модели (BGE/реранкер/судья) — локально по умолчанию, грант Cohere — опциональный апгрейд *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Qdrant** [HTTP / Qdrant API] — сохраняет векторы
- **Входящие**:
  - ← **Same-Named Resolver** [in-process] — передаёт resolved-чанки на векторизацию
  - ← **BSL Synonyms RU↔EN** [in-process] — предоставляет словарь синонимов

<a id="component-реранкер"></a>
#### Component: Реранкер

- **Технология**: `Python`
- **Описание**: Реранкинг результатов перед выдачей: BGE-reranker локально; Cohere Rerank опционально. Faithfulness vs relevance (ADR 0002).
- **ADR**: [`0002-р2-faithfulness-vs-relevance.md`](../docs/architecture/adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) — Faithfulness и relevance ретривера — разные метрики *(accepted)*
- **Open issues**: —
- **Исходящие**:
  - → **Route Dispatcher** [in-process] — возвращает реранкированные результаты
  - → **MCP-оркестратор** [in-process] — возвращает реранкированные результаты
- **Входящие**:
  - (нет)

<a id="container-qdrant"></a>
### Container: Qdrant

- **Технология**: `Qdrant`
- **Описание**: Векторное хранилище чанков и метаданных. Embedded локально или server-mode на VDS (ADR 0029 open).
- **Tags**: `Database, Proposed`
- **ADR**: [`0029-multitenancy-qdrant-embedded-vs-server.md`](../docs/architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md) — Мульти-аренда: Qdrant embedded vs server — развилка по режиму деплоя *(proposed)*
- **Open issues**: —
- **Исходящие**:
  - (нет)
- **Входящие**:
  - ← **MCP-оркестратор** [HTTP / Qdrant API] — читает векторы и метаданные
  - ← **Азимут-ядро** [HTTP / gRPC] — читает и сохраняет векторы
  - ← **Эмбеддер** [HTTP / Qdrant API] — сохраняет векторы

<a id="container-adapter-слой-llm"></a>
### Container: Adapter-слой LLM

- **Технология**: `Python`
- **Описание**: Абстракция над разговорной облачной LLM; дефолт — DeepSeek V4; запас — Claude/Qwen/Yandex. Финал валидируем eval-ом в теме 6 (ADR 0020, 0021).
- **ADR**: [`0020-cloud-llm-via-adapter.md`](../docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md) — Разговорная модель — облачная и подключаемая через адаптер; внутри MCP-сервера нет разговорной LLM; лёгкие модели (BGE/реранкер/судья) — локально по умолчанию, грант Cohere — опциональный апгрейд *(accepted)*
- **Open issues**: [`0021-default-model-deepseek-v4.md`](../docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md) — Дефолт разговорной модели — DeepSeek V4 (Flash основной, Pro для тяжёлого кода); запас — Claude/Qwen/Yandex; финал валидируем eval-ом в теме 6 *(accepted)*
- **Исходящие**:
  - → **DeepSeek** [HTTPS / OpenAI-compatible API] — генерирует текст
  - → **Claude (Anthropic)** [HTTPS / Anthropic API] — генерирует текст в премиум-режиме (Сергей-премиум)
- **Входящие**:
  - ← **MCP-оркестратор** [HTTPS / JSON] — генерирует ответ и фолбэк
  - ← **Route Dispatcher** [Python API] — запрашивает синтез ответа через разговорную модель (ADR 0021)
  - ← **Fallback Mode** [Python API] — инициирует дип-ресёрч

