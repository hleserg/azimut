# 5. Структурный вид (Building Block View)

> arc42 §5 — иерархия строительных блоков: системный контекст → контейнеры → компоненты.
> Диаграммы — в [`workspace.dsl`](../../workspace.dsl) (Structurizr DSL, ADR 0034). Статичные C4-схемы в Mermaid не создаются.
> Запуск: `docker run --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/structurizr`

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

✅ проверено: `workspace.dsl` (модель persons + softwareSystems + связи)

---

## 5.2 Уровень 2 — Контейнеры (whitebox)

**Диаграмма:** view `container` в `workspace.dsl`.

Ниже — таблица всех контейнеров в формате «чёрного ящика».

### Клиентские приложения (External)

| Контейнер | Технология | Пользователь | ADR |
|---|---|---|---|
| Cherry Studio | Electron App | Мама + Сергей everyday | [0019](adr/foundation/0019-cherry-studio-default-client.md) |
| Claude Desktop | Desktop App | Сергей premium | [0019](adr/foundation/0019-cherry-studio-default-client.md) |
| mini-ai-1c | Desktop App | Сергей (захват кода из Конфигуратора) | [0019](adr/foundation/0019-cherry-studio-default-client.md) |

Клиенты не входят в кодовую базу Азимута — это External контейнеры (ADR 0018). ✅ проверено: `workspace.dsl` tags "External"

### Внешние сервисы (External)

| Контейнер | Технология | Назначение | ADR |
|---|---|---|---|
| mcp-bsl-platform-context | TypeScript / MCP | Справочник платформы 1С (MIT, alkoleft) | [0017](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
| Sentry / GlitchTip | Sentry / GlitchTip | Мониторинг ошибок и трассировка (выбор открыт) | [0028](adr/open/0028-sentry-vs-agpl.md) |

### Наш код

| Контейнер | Технология | Назначение | ADR |
|---|---|---|---|
| MCP-оркестратор | Python / FastMCP | Принимает MCP-запросы; управляет ретривингом, иерархией источников, LLM-судьёй, фолбэком | [0022](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| Азимут-ядро | Python / bsl-atlas fork | Парсер BSL, граф вызовов, чанкер, эмбеддер, реранкер | [0011](adr/foundation/0011-fork-bsl-atlas-as-core.md), [0013](adr/foundation/0013-fork-role-code-engine.md) |
| Adapter-слой LLM | Python | Абстракция над облачной LLM; дефолт — DeepSeek V4 | [0020](adr/foundation/0020-cloud-llm-via-adapter.md), [0021](adr/foundation/0021-default-model-deepseek-v4.md) |
| Qdrant | Qdrant | Векторное хранилище чанков и метаданных | [0029](adr/open/0029-multitenancy-qdrant-embedded-vs-server.md) |

✅ проверено: `workspace.dsl` (контейнеры + связи)

**Граница форк / наш код** зафиксирована в ADR 0022: Азимут-ядро = форк bsl-atlas; MCP-оркестратор + Adapter-слой LLM = наш код поверх форка.

---

## 5.3 Уровень 3 — Компоненты

**Диаграммы:** views `componentAzimuthCore` и `componentMCPOrchestrator` в `workspace.dsl`.

### 5.3.1 Азимут-ядро (форк bsl-atlas)

| Компонент | Назначение | ADR |
|---|---|---|
| Чанкер | Детерминированная структурная резка: функция = чанк; блоки Если/Цикл/Попытка/Область с шапкой контекста. LLM для резки не используется. | [0024](adr/code-processing/0024-code-chunking-deterministic-structural.md) |
| Граф вызовов | Построение BSL-графа вызовов; резолв одноимённых процедур — открытая инженерная задача | [0025](adr/code-processing/0025-resolve-same-named-procedures.md) |
| Эмбеддер | Векторизация чанков: BGE-M3 локально по умолчанию; Cohere Embed опционально через адаптер | [0020](adr/foundation/0020-cloud-llm-via-adapter.md) |
| Реранкер | Реранкинг результатов: BGE-reranker локально; Cohere Rerank опционально. Балансирует faithfulness и relevance | [0002](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) |

### 5.3.2 MCP-оркестратор

| Компонент | Назначение | ADR |
|---|---|---|
| Server-Controlled Retrieval | Планка релевантности, триггер добора, потолок окна контекста | [0005](adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md) |
| Route Dispatcher | Fallback-цепочка поиска: graph → metadata → grep | [0026](adr/code-processing/0026-code-search-routing.md) |
| Source Hierarchy | Иерархия источников при конфликте: код → справка → ИТС | [0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md) |
| Contradiction Metric | Метрика противоречивости источников перед выдачей; логируется в Sentry | [0001](adr/anti-hallucinations/0001-р1-metric-contradiction.md) |
| LLM Judge | LLM-судья со спан-привязкой: арбитрирует faithfulness и groundedness через Claude API | [0003](adr/anti-hallucinations/0003-р3-llm-judge-spans.md) |
| Fallback Mode | Фолбэк = смена режима (дип-ресёрч с тем же контрактом); заменил «честный тупик» Р4 | [0007](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md) |

✅ проверено: `workspace.dsl` (компоненты обоих контейнеров)

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
