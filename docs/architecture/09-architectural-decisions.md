# 9. Архитектурные решения (Architectural Decisions)

> arc42 §9 — индекс ADR по темам и статусам. Сами ADR — в [`adr/`](adr/).

Этот файл автогенерируется командой `./scripts/update-adr-index.sh` из фронтматтеров ADR-файлов.

Шаблон ADR: [`adr/template.md`](adr/template.md).
Все ADR (34 штуки, нумерация 0001–0034): см. [`adr/`](adr/) с подпапками `anti-hallucinations/`, `foundation/`, `code-processing/`, `tooling/`, `open/`.

<!-- ADR-INDEX:START -->
| № | Тема | Статус | Заголовок |
|---|---|---|---|
| 0001 | anti-hallucinations | accepted | [Метрика противоречивости источников ПЕРЕД выдачей](adr/anti-hallucinations/0001-р1-metric-contradiction.md) |
| 0002 | anti-hallucinations | accepted | [Faithfulness и relevance ретривера — разные метрики](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) |
| 0003 | anti-hallucinations | accepted | [LLM-судья со спан-привязкой (Claude как арбитр)](adr/anti-hallucinations/0003-р3-llm-judge-spans.md) |
| 0004 | anti-hallucinations | superseded by 0007 | [«Честный тупик» как фолбэк (снято)](adr/anti-hallucinations/0004-р4-honest-deadend-retired.md) |
| 0005 | anti-hallucinations | accepted | [Контроль ретривинга — на сервере (планка релевантности, триггер добора, потолок окна)](adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md) |
| 0006 | anti-hallucinations | accepted | [Иерархия источников при конфликте: код → справка → ИТС](adr/anti-hallucinations/0006-р6-source-hierarchy.md) |
| 0007 | anti-hallucinations | accepted | [Фолбэк = смена режима (дип-ресёрч в интернете с тем же контрактом)](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md) |
| 0008 | anti-hallucinations | proposed | [Детектор «relevance высокий / groundedness низкий» — 3 уровня действий](adr/anti-hallucinations/0008-п1-groundedness-detector.md) |
| 0009 | anti-hallucinations | proposed | [Второй проход ретривера при неуверенности (открытый триггер)](adr/anti-hallucinations/0009-п2-re-retrieval.md) |
| 0010 | anti-hallucinations | proposed | [Оценка достаточности запроса + подсказки агенту что переспросить](adr/anti-hallucinations/0010-п3-query-sufficiency.md) |
| 0011 | foundation | accepted | [Основа — форк `bsl-atlas` (AGPL-3.0) как ядро понимания кода 1С](adr/foundation/0011-fork-bsl-atlas-as-core.md) |
| 0012 | foundation | accepted | [Имя форка/проекта — «Азимут» / `azimuth`](adr/foundation/0012-name-azimut.md) |
| 0013 | foundation | accepted | [Роль `bsl-atlas`: только «движок понимания кода» (берём парсер BSL + граф вызовов + каркас MCP + docker; меняем хранилище/эмбеддер/реранк; дописываем поведенческий контракт и оркестрацию)](adr/foundation/0013-fork-role-code-engine.md) |
| 0014 | foundation | accepted | [`FSerg/mcp-1c-v1` — референс архитектуры, не кодовая основа (берём идеи payload-схемы и RRF, код не копируем)](adr/foundation/0014-fserg-mcp-1c-as-reference-only.md) |
| 0015 | foundation | accepted | [Миграция стека: гибрид по времени — один дымовой прогон `bsl-atlas` на ChromaDB, затем сразу Qdrant+BGE-M3 (ни строчки нового кода под Chroma)](adr/foundation/0015-stack-migration-smoke-then-qdrant.md) |
| 0016 | foundation | accepted | [MCP-шлюз `onec-mcp-universal` — отложен до темы 7 (на локальном сценарии не нужен; Claude Desktop тянет несколько MCP-серверов напрямую)](adr/foundation/0016-onec-mcp-universal-deferred.md) |
| 0017 | foundation | accepted | [`alkoleft/mcp-bsl-platform-context` берём в фундамент (drop-in вторым MCP, MIT, бесплатно)](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
<!-- ADR-INDEX:END -->
