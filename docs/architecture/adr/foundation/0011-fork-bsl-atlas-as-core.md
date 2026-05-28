---
status: accepted
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "`_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md` реш. 1.1; `_source/notion/bsl-atlas-opensource-research--36b0c905e626814fa52ce80b248c4311.md`; `LICENSE` в корне репо (AGPL-3.0)"
implemented-in: "`docs/architecture/05-building-block-view.md` §«Азимут-ядро»; `workspace.dsl` softwareSystem «Азимут»"
related-to: "[0012](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0012-name-azimut.md), [0013](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0013-fork-role-code-engine.md), [0015](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0015-stack-migration-smoke-then-qdrant.md)"
supersedes: ""
superseded-by: ""
---

# Основа — форк `bsl-atlas` (AGPL-3.0) как ядро понимания кода 1С

## Context and Problem Statement

Проект «Азимут» (ИИ-ассистент по коду 1С) нуждается в ядре, которое умеет разбирать BSL-код и строить детерминированный граф вызовов. Это самая дорогая и рискованная часть системы: парсинг текстовых модулей 1С + понимание структуры вызовов — специфическая задача, не решённая ни одной универсальной RAG-платформой. Нужно решить: писать всё с нуля или форкнуть существующий проект?

## Decision Drivers

* Не строить заново то, что уже есть — вкладываться только в конкурентное ядро.
* Парсер BSL + граф вызовов — ровно то, что нельзя взять ни из RAGFlow, ни из kotaemon, ни из Onyx.
* Стек-совместимость: Python ≥ 3.11 + MCP + Ollama/русский — обязательное условие.
* Лицензия должна быть совместима с целью проекта — OSS под AGPL-3.0.
* Первый рабочий прототип — через минимальное время, без переписывания базового парсинга.

## Considered Options

* **Форк `bsl-atlas`** — единственный зрелый OSS-проект, понимающий структуру кода 1С.
* **`FSerg/mcp-1c-v1`** — MCP-сервер с RAG по метаданным конфигурации, TypeScript.
* **Большие RAG-платформы (RAGFlow, kotaemon, Onyx)** — универсальные, BSL не понимают.
* **Сборка с нуля** — максимальная свобода, максимальные сроки и риски.

## Decision Outcome

Chosen option: **«Форк `bsl-atlas`»**, because это единственный проект, который уже решает самую дорогую часть задачи — парсинг текста BSL и построение детерминированного графа вызовов. AGPL-3.0 совместима с целью проекта: Азимут сам OSS, монетизации через закрытость нет. Форк официально разрешён лицензией — отдельного согласования с автором не требуется (проверено: файл `LICENSE` на ветке `master` bsl-atlas содержит GNU AGPL v3).

### Consequences

* Good, because не пишем парсер BSL и граф вызовов с нуля — это 2–3 месяца работы.
* Good, because стек совместим (Python + FastMCP + Docker + Ollama/русский).
* Good, because AGPL-3.0 согласуется с целями проекта: открытость — цель, не ограничение.
* Bad, because хранилище (ChromaDB) и эмбеддер форка не подходят под наш целевой стек — нужна миграция (ADR 0015).
* Bad, because покрытие форка ограничено: внешние обработки `.epf/.erf` не читаются, подписки на события — частично, асинхрон — слепая зона. Это открытые риски, валидируются на дымовом прогоне.
* Bad, because AGPL §13 (сетевой пункт) требует раскрывать исходники при сетевом деплое — это намеренная позиция, не ограничение для нас.
* Bad, because конфликт с Sentry for Open Source (просят permissive-лицензию): форк важнее гранта, но вопрос открыт — ADR 0028 фиксирует план Б.
* Neutral, because bsl-atlas работает **только** с текстовой выгрузкой `DumpConfigToFiles` (`*.bsl` + plain-text метаданные) — это единственный входной формат форка. XML-выгрузка из Конфигуратора (структура объектов: формы, регистры, реквизиты) — **отдельный формат, за пределами этого ADR**; рассматривается как второй источник данных в ADR 0035 (⚠️ предположение: нужны оба источника — окончательно не принято, тема 2/4).
* Neutral, because парсер в bsl-atlas двойной: **tree-sitter** (`alkoleft/tree-sitter-bsl`, MIT) — первичный (компилируется в `.so` при Docker-сборке), regex-fallback — если `.so` отсутствует. BSL Language Server (Java, BSL LS) рассматривался как альтернатива — **отложен до v2**: сложность Java-интеграции и отсутствие Python-биндингов делают его нецелесообразным для v1.

### Confirmation

Успех подтверждается, когда дымовой прогон (`bsl-atlas` as-is на реальной ERP) проходит без ошибок: парсит модули BSL, строит граф вызовов, не давится на объёме (десятки тысяч модулей). Зафиксировано в `roadmap.md` как открытый риск «Дымовой прогон на реальной ERP».

## Pros and Cons of the Options

### Форк `bsl-atlas`

* Good, because единственный зрелый проект с парсером BSL + детерминированным графом вызовов.
* Good, because Docker-упаковка, каркас MCP-сервера, поддержка русских идентификаторов — готово.
* Good, because парсер двойной: tree-sitter (`alkoleft/tree-sitter-bsl`) + regex-fallback.
* Bad, because ChromaDB как хранилище не держит hybrid dense+sparse, нужно мигрировать.
* Bad, because граф вызовов — только 1 уровень (прямые вызовы), рекурсивного обхода нет из коробки.
* Bad, because `.epf/.erf` и асинхрон — слепые зоны.

### `FSerg/mcp-1c-v1`

* Good, because рабочий образец: RRF через Qdrant, docker-оркестрация, схема payload.
* Bad, because TypeScript-стек — код напрямую не переиспользуется (у нас Python).
* Bad, because индексирует только метаданные структуры конфигурации, не тексты BSL-модулей.
* Bad, because нет реранкера, эмбеддер `all-MiniLM` слабее BGE-M3.

### Большие RAG-платформы

* Good, because готовый UI и мульти-аренда из коробки (RAGFlow, kotaemon).
* Bad, because BSL не понимают — нет парсера и графа вызовов, придётся добавлять самостоятельно.
* Bad, because heavyweight: притаскивают зависимости и архитектурные ограничения.

### Сборка с нуля

* Good, because полная свобода в выборе стека и архитектуры.
* Bad, because 2–3 месяца только на парсер BSL до первого рабочего прототипа.
* Bad, because высокий риск: языки 1С нестандартны, готового грамматического описания нет вне bsl-atlas/tree-sitter-bsl.

## More Information

* Реш. 1.1 и 1.10 в `_source/notion/design-system-v2--*.md` — детальное обоснование и лицензионный чек-лист.
* `_source/notion/bsl-atlas-opensource-research--*.md` — сводная таблица пробелов bsl-atlas и drop-in компонентов.
* `_source/_resolutions.md` §«Что НЕ изменилось» — форк важнее гранта Sentry.
* ADR 0013 — роль форка: только «движок», что берём/меняем/дописываем.
* ADR 0015 — миграция ChromaDB → Qdrant+BGE-M3 после дымового прогона.
* ADR 0023 — лицензионный чек-лист зависимостей.
* ADR 0028 — конфликт AGPL × Sentry for Open Source, план Б.
* ADR 0035 — XML-выгрузка конфигурации как второй источник данных (proposed): структура объектов ERP, нужна для тем 2 и 4; решение не принято, ждёт прототипирования.
* `_source/notion/hle-463-bsl-ls-wrappers--*.md` — research обёрток BSL LS в MCP (claude-code-bsl-lsp, mcp-bsl-lsp-bridge): что даёт и какой ценой; подтверждение решения «BSL LS отложить до v2».
