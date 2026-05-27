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
<!-- ADR-INDEX:END -->
