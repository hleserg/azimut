# 9. Архитектурные решения (Architectural Decisions)

> arc42 §9 — индекс ADR по темам и статусам. Сами ADR — в [`adr/`](adr/).

Этот файл автогенерируется командой `./scripts/update-adr-index.sh` из фронтматтеров ADR-файлов.

Шаблон ADR: [`adr/template.md`](adr/template.md).
Все ADR (34 штуки, нумерация 0001–0034): см. [`adr/`](adr/) с подпапками `anti-hallucinations/`, `foundation/`, `code-processing/`, `tooling/`, `open/`.

<!-- ADR-INDEX:START -->
| № | Тема | Статус | Заголовок |
|---|---|---|---|
| 0011 | foundation | accepted | [Основа — форк `bsl-atlas` (AGPL-3.0) как ядро понимания кода 1С](adr/foundation/0011-fork-bsl-atlas-as-core.md) |
| 0012 | foundation | accepted | [Имя форка/проекта — «Азимут» / `azimuth`](adr/foundation/0012-name-azimut.md) |
| 0013 | foundation | accepted | [Роль `bsl-atlas`: только «движок понимания кода» (берём парсер BSL + граф вызовов + каркас MCP + docker; меняем хранилище/эмбеддер/реранк; дописываем поведенческий контракт и оркестрацию)](adr/foundation/0013-fork-role-code-engine.md) |
| 0014 | foundation | accepted | [`FSerg/mcp-1c-v1` — референс архитектуры, не кодовая основа (берём идеи payload-схемы и RRF, код не копируем)](adr/foundation/0014-fserg-mcp-1c-as-reference-only.md) |
| 0015 | foundation | accepted | [Миграция стека: гибрид по времени — один дымовой прогон `bsl-atlas` на ChromaDB, затем сразу Qdrant+BGE-M3 (ни строчки нового кода под Chroma)](adr/foundation/0015-stack-migration-smoke-then-qdrant.md) |
| 0016 | foundation | accepted | [MCP-шлюз `onec-mcp-universal` — отложен до темы 7 (на локальном сценарии не нужен; Claude Desktop тянет несколько MCP-серверов напрямую)](adr/foundation/0016-onec-mcp-universal-deferred.md) |
| 0017 | foundation | accepted | [`alkoleft/mcp-bsl-platform-context` берём в фундамент (drop-in вторым MCP, MIT, бесплатно)](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
| 0018 | foundation | superseded by 0019 | [UX и клиент — свой UI не строим, берём готовый MCP-клиент с облачной разговорной моделью](adr/foundation/0018-mcp-client-no-own-ui.md) |
| 0019 | foundation | accepted | [Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода)](adr/foundation/0019-cherry-studio-default-client.md) |
| 0020 | foundation | accepted | [Разговорная модель — облачная и подключаемая через адаптер; внутри MCP-сервера нет разговорной LLM; лёгкие модели (BGE/реранкер/судья) — локально по умолчанию, грант Cohere — опциональный апгрейд](adr/foundation/0020-cloud-llm-via-adapter.md) |
| 0021 | foundation | accepted | [Дефолт разговорной модели — DeepSeek V4 (Flash основной, Pro для тяжёлого кода); запас — Claude/Qwen/Yandex; финал валидируем eval-ом в теме 6](adr/foundation/0021-default-model-deepseek-v4.md) |
| 0022 | foundation | accepted | [Граница «форк/готовые библиотеки vs наш код» — форк даёт понимание кода, библиотеки дают механику RAG, наш код — поведение, гарантии, оркестрацию](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| 0023 | foundation | accepted | [Лицензионный чек-лист OSS под AGPL-3.0 + правило источников («✅ проверено: <файл/url>» или «⚠️ предположение»)](adr/foundation/0023-license-checklist-and-source-rule.md) |
| 0024 | code-processing | accepted | [Детерминированная структурная резка кода поверх Азимута](adr/code-processing/0024-code-chunking-deterministic-structural.md) |
| 0025 | code-processing | proposed | [Алгоритм резолва одноимённых процедур — открытая инженерная задача](adr/code-processing/0025-resolve-same-named-procedures.md) |
| 0026 | code-processing | accepted | [Роутинг поиска по коду — fallback-цепочка graph → metadata → grep](adr/code-processing/0026-code-search-routing.md) |
| 0027 | code-processing | accepted | [Портировать техники `mcp-1c` (feenlace) в Python — не переписывать на Go](adr/code-processing/0027-port-feenlace-techniques-to-python.md) |
<!-- ADR-INDEX:END -->
