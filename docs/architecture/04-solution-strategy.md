# 4. Стратегия решения (Solution Strategy)

> arc42 §4 — ключевые архитектурные решения одним списком. Каждый пункт — одна-две фразы; вся аргументация и альтернативы — в соответствующем ADR. Структура форка vs готового vs нашего кода — в [`05-building-block-view.md`](05-building-block-view.md) и [`workspace.dsl`](../../workspace.dsl).
>
> Источники: [`_source/notion/design-system-v2--*.md`](../_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md) (журнал решений темы 1–2); ADR 0011–0027, 0034.

## 4.1 Сводная таблица решений

| # | Решение | Подробности | ADR / DSL |
|---|---|---|---|
| 1 | **Форк `bsl-atlas` → «Азимут»** как ядро понимания кода 1С (AGPL-3.0, форк разрешён лицензией). Имя `azimuth` — наследует навигационный смысл «atlas», но не копирует. | Берём ровно одну дорогую и рискованную часть: парсер текста BSL + детерминированный граф вызовов. Большие RAG-платформы (RAGFlow, kotaemon, Onyx) BSL не понимают — годятся только как UI-морда, не как мозг. | [ADR 0011](adr/foundation/0011-fork-bsl-atlas-as-core.md), [ADR 0012](adr/foundation/0012-name-azimut.md); `softwareSystem azimuth` в [`workspace.dsl`](../../workspace.dsl) |
| 2 | **Роль форка — только «движок понимания кода»**, не готовый продукт. | Из форка оставляем: парсер BSL, граф вызовов, каркас MCP-сервера, docker-упаковку, поддержку русского и Ollama. Меняем: хранилище ChromaDB → Qdrant; эмбеддер → BGE-M3; добавляем реранкер. Дописываем: поведенческий контракт, серверный добор, иерархия источников, eval/судью. | [ADR 0013](adr/foundation/0013-fork-role-code-engine.md), [ADR 0022](adr/foundation/0022-boundary-fork-vs-own-code.md); `container azimuthCore` |
| 3 | **`FSerg/mcp-1c-v1` — только референс архитектуры.** | Лицензия MIT (✅ проверено), но код не берём: TypeScript-стек, индексирует только метаданные структуры, не тексты модулей. Берём идеи: RRF-слияние поверх Qdrant, схема payload по метаданным конфы. | [ADR 0014](adr/foundation/0014-fserg-mcp-1c-as-reference-only.md) |
| 4 | **Готовые библиотеки под каждый пробел RAG.** BGE-M3 (эмбеддинги, локально, dense+sparse), Qdrant (embedded локально / server для VDS), [`rerankers`](https://github.com/AnswerDotAI/rerankers) + BGE-reranker-v2-m3 (локально) / Cohere Rerank v4 (опц.), [Docling](https://github.com/DS4SD/docling) (приём документации), [RAGAS](https://github.com/explodinggradients/ragas) (eval), Self-RAG / Contextual Retrieval / CitationQueryEngine. | Принцип v2.0: собирать систему из проверенных «кирпичей», писать руками только то, чего нет в опенсорсе. Cohere — опциональный апгрейд, грант на пользователя автоматически не тратится. | [ADR 0015](adr/foundation/0015-stack-migration-smoke-then-qdrant.md), [ADR 0020](adr/foundation/0020-cloud-llm-via-adapter.md); тема 3 (HLE-415, ADR 0035+); реестр компонентов в [`05-building-block-view.md`](05-building-block-view.md) |
| 5 | **Миграция стека — гибрид: дымовой прогон форка as-is → сразу Qdrant+BGE-M3.** | ChromaDB+SQLite форка → Qdrant+BGE-M3 после одного дымового прогона (проверяем, что движок реально парсит нашу ERP). Правило: ни строчки нового кода под Chroma. | [ADR 0015](adr/foundation/0015-stack-migration-smoke-then-qdrant.md) |
| 6 | **Шлюз `onec-mcp-universal` — отложен до темы 7.** | Локально не нужен: Cherry Studio / Claude Desktop сами держат несколько MCP-серверов. Шлюз осмыслен на VDS с авторизацией по тенанту. | [ADR 0016](adr/foundation/0016-onec-mcp-universal-deferred.md) |
| 7 | **`alkoleft/mcp-bsl-platform-context` — drop-in MCP рядом** (MIT, бесплатно, ноль кода). | Закрывает API платформы (`shcntx_ru.hbk`): сигнатуры `ПолучитьОбщийМакет()`, `Записать()` и пр. — там, где облачный Claude чаще всего галлюцинирует из памяти. | [ADR 0017](adr/foundation/0017-mcp-bsl-platform-context-included.md); `container bslPlatformMcp` |
| 8 | **Свой UI не строим; клиент — готовый MCP-совместимый.** | Cherry Studio + DeepSeek — дефолт для мамы и Сергея-everyday; Claude Desktop — Сергей-премиум дома (подписка); mini-ai-1c — Сергей-захват кода из Конфигуратора. | [ADR 0018](adr/foundation/0018-mcp-client-no-own-ui.md), [ADR 0019](adr/foundation/0019-cherry-studio-default-client.md); `cherryStudio`/`claudeDesktop`/`miniAi1c` |
| 9 | **Adapter-слой к разговорной LLM — в фундаменте.** | Локально не тянем; Claude доступен только через VPN из РФ — поэтому подменяемость не «когда-нибудь», а с первого дня. | [ADR 0020](adr/foundation/0020-cloud-llm-via-adapter.md); `container llmAdapter` |
| 10 | **Дефолт разговорной модели — DeepSeek V4** (Flash основной, Pro для тяжёлого разбора кода). | Из РФ без VPN, ~81 % SWE-bench, 1М контекст, протокол Anthropic, дешевле всех (~\$2–12/мес на двоих). Запас: Claude (премиум + eval-эталон), Qwen3.7-Max, YandexGPT/GigaChat (152-ФЗ-фолбэк). Финал валидируем eval-ом в теме 6. | [ADR 0021](adr/foundation/0021-default-model-deepseek-v4.md); `softwareSystem deepSeekLLM` |
| 11 | **Граница «форк/готовое vs наш код» зафиксирована.** | Форк = «понимание кода 1С»; готовые либы = «механика RAG»; наш код = «поведение, гарантии, оркестрация» (контракт, Р5 добор, Р6 иерархия, судья, адаптер). Переход через границу — отдельный ADR. | [ADR 0022](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| 12 | **Лицензионный чек-лист OSS + правило источников.** | Проект — OSS под AGPL-3.0, чек-лист «перед монетизацией» снят; остаётся OSS-гигиена (атрибуция bsl-atlas, copyleft-через-subprocess для 1c-syntax, совместимость зависимостей с AGPL). Правило источников: «✅ проверено: \<файл/url\>» или «⚠️ предположение». | [ADR 0023](adr/foundation/0023-license-checklist-and-source-rule.md); [`02-architecture-constraints.md`](02-architecture-constraints.md) §2.2 O1 |

## 4.2 Обработка кода 1С (тема 2) — ключевые решения

| # | Решение | Подробности | ADR |
|---|---|---|---|
| 13 | **Детерминированная структурная резка кода** поверх Азимута. Функция ≤ порога → один чанк; иначе режем по top-level блокам (`Если`/`Цикл`/`Попытка`/`Область`), не разрывая блок. | Символьный fallback форка (порог 2000 символов) рвёт «ОбработкаПроведения» посреди условия — это сценарий Приоритета №1. LLM для резки не используем (недетерминированность = источник галлюцинаций). | [ADR 0024](adr/code-processing/0024-code-chunking-deterministic-structural.md); `component chunker` |
| 14 | **Резолв одноимённых процедур — открытый алгоритм (`proposed`).** | В типовой ERP много одноимённых процедур в разных модулях; форк `bsl-atlas` делает лукап на 1 уровень и без квалификации модуля. Алгоритм ещё не написан. | [ADR 0025 proposed](adr/code-processing/0025-resolve-same-named-procedures.md); `component graph` |
| 15 | **Роутинг поиска по коду — fallback-цепочка graph → metadata → grep.** | Диспетчер MCP-оркестратора выбирает стратегию в зависимости от типа вопроса; образец — `comol/ai_rules_1c`. | [ADR 0026](adr/code-processing/0026-code-search-routing.md); `component routeDispatcher` |
| 16 | **Техники `feenlace/mcp-1c` портируем в Python** (а не берём Go-код). | GC-off-аналог, шардирование по CPU, дисковый кеш по SHA, манифест-diff, BSL-синонимный анализатор — идеи берём, реализуем на Python. Прикручиваем только если упрёмся в скорость холодной сборки. | [ADR 0027](adr/code-processing/0027-port-feenlace-techniques-to-python.md) |

## 4.3 Поведение и анти-галлюцинации (фон) — ключевые решения

| # | Решение | Подробности | ADR |
|---|---|---|---|
| 17 | **Faithfulness и relevance ретривера — разные метрики.** | Не мерим одним числом; eval RAGAS считает оба отдельно. | [ADR 0002](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) |
| 18 | **LLM-судья со спан-привязкой.** | Сравнивает спаны ответа со спанами контекста, флажит неподкреплённое; реализуется через Claude API. | [ADR 0003](adr/anti-hallucinations/0003-р3-llm-judge-spans.md); `component llmJudge` |
| 19 | **Серверный контроль добора.** | Нижняя планка релевантности, триггер добора, потолок окна — на стороне сервера, измеримо и калибруемо. Агенту — только семантическая переформулировка для 2-го прохода. | [ADR 0005](adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md); `component serverControlledRetrieval` |
| 20 | **Иерархия источников при конфликте.** | Код в базе → встроенная справка конфы → ИТС. Не выкидываем конфликт — объясняем по приоритету, помечаем первый как вероятный, инкрементируем метрику противоречивости. | [ADR 0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md); `component sourceHierarchy` |
| 21 | **Фолбэк = смена режима, не капитуляция** (заменил «честный тупик» Р4). | «Не нашёл в индексе» → дип-ресёрч в интернете с тем же контрактом: показать источник, пометить «из интернета», не выдавать за истину. | [ADR 0007](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md); `component fallbackMode`; «надгробие» Р4 — [ADR 0004](adr/anti-hallucinations/0004-р4-honest-deadend-retired.md) |
| 22 | **Метрика противоречивости — перед выдачей.** | Принята с открытым подвопросом по механике детектирования. | [ADR 0001](adr/anti-hallucinations/0001-р1-metric-contradiction.md); механика — [ADR 0033 proposed](adr/open/0033-r1-contradiction-detection-mechanics.md); `component contradictionMetric` |
| 23 | **Детектор «релевантность высокая / groundedness низкая» — 3 слоя.** | Судья режет ответ до выдачи; плашка «частично из общих знаний»; канарейка доли негрунтованного в Sentry. | [ADR 0008](adr/anti-hallucinations/0008-п1-groundedness-detector.md) (П1, предложение); [ADR 0009](adr/anti-hallucinations/0009-п2-re-retrieval.md) (П2), [ADR 0010](adr/anti-hallucinations/0010-п3-query-sufficiency.md) (П3) |

## 4.4 Архитектура-как-код и процесс

| # | Решение | Подробности | ADR |
|---|---|---|---|
| 24 | **Architecture-as-Code: Structurizr DSL.** Единый источник C4-диаграмм — [`workspace.dsl`](../../workspace.dsl) в корне репо; рендер через Structurizr on-prem в local-режиме (`structurizr/structurizr local`, Docker); Mermaid остаётся только для §6 Runtime View. | Связь DSL ↔ ADR — через `properties { "adr-link" "..." }` на элементах DSL: компонент знает свой ADR, ADR знает свой компонент. | [ADR 0034](adr/tooling/0034-architecture-as-code-structurizr-dsl.md) |

## 4.5 Открытые решения

Эти ADR имеют статус `proposed`/`open` — закрываются при работе над соответствующей темой:

- [ADR 0028](adr/open/0028-sentry-vs-agpl.md) — Sentry × AGPL (план Б — GlitchTip / self-host).
- [ADR 0029](adr/open/0029-multitenancy-qdrant-embedded-vs-server.md) — Qdrant embedded vs server для мульти-аренды (тема 7).
- [ADR 0030](adr/open/0030-multitenancy-canary-vs-watchdog.md) — Canary vs Watchdog для мульти-аренды (тема 7).
- [ADR 0031](adr/open/0031-multitenancy-push-via-web-frontend.md) — Push через веб-морду или отдельный канал (тема 7).
- [ADR 0032](adr/open/0032-multitenancy-tenant-storage-isolation.md) — Изоляция хранилища тенантов (тема 7).
- [ADR 0033](adr/open/0033-r1-contradiction-detection-mechanics.md) — Механика детектирования противоречивости (тема 5, HLE-417).

## 4.6 Что НЕ выбрано (явно)

- **Локальная разговорная LLM** — отклонена ([T5](02-architecture-constraints.md#21-технические-ограничения)): рабочие ПК не тянут даже минимально вменяемую модель.
- **Свой парсер XML-конфигурации / свой индексатор / свой OCR с нуля** — отклонены [ADR 0013](adr/foundation/0013-fork-role-code-engine.md) и принципом v2.0: всё, что есть в опенсорсе, не пишем заново.
- **Mermaid C4Context / C4Container / C4Component** — отклонены [ADR 0034](adr/tooling/0034-architecture-as-code-structurizr-dsl.md): статичные C4 живут в `workspace.dsl`, чтобы не дублировать модель в каждом markdown-файле.
- **Веб-морда / собственный UI** — отложены до темы 7 ([ADR 0018](adr/foundation/0018-mcp-client-no-own-ui.md)).
- **Шлюз `onec-mcp-universal`** — отложен до темы 7 ([ADR 0016](adr/foundation/0016-onec-mcp-universal-deferred.md)).

Полный whitebox/blackbox-обзор системы — в [`05-building-block-view.md`](05-building-block-view.md) и views `container` / `componentAzimuthCore` / `componentMCPOrchestrator` в [`workspace.dsl`](../../workspace.dsl).
