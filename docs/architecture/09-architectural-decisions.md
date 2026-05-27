# 9. Архитектурные решения (Architectural Decisions)

> arc42 §9 — индекс ADR по темам и статусам. Сами ADR — в [`adr/`](adr/).

Этот файл автогенерируется командой `./scripts/update-adr-index.sh` из фронтматтеров ADR-файлов.

Шаблон ADR: [`adr/template.md`](adr/template.md).
Все ADR (34 штуки, нумерация 0001–0034): см. [`adr/`](adr/) с подпапками `anti-hallucinations/`, `foundation/`, `code-processing/`, `tooling/`, `open/`.

<!-- ADR-INDEX:START -->
| № | Тема | Статус | Заголовок |
|---|---|---|---|
| 0018 | foundation | superseded by 0019 | [UX и клиент — свой UI не строим, берём готовый MCP-клиент с облачной разговорной моделью](adr/foundation/0018-mcp-client-no-own-ui.md) |
| 0019 | foundation | accepted | [Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода)](adr/foundation/0019-cherry-studio-default-client.md) |
| 0020 | foundation | accepted | [Разговорная модель — облачная и подключаемая через адаптер; внутри MCP-сервера нет разговорной LLM; лёгкие модели (BGE/реранкер/судья) — локально по умолчанию, грант Cohere — опциональный апгрейд](adr/foundation/0020-cloud-llm-via-adapter.md) |
| 0021 | foundation | accepted | [Дефолт разговорной модели — DeepSeek V4 (Flash основной, Pro для тяжёлого кода); запас — Claude/Qwen/Yandex; финал валидируем eval-ом в теме 6](adr/foundation/0021-default-model-deepseek-v4.md) |
| 0022 | foundation | accepted | [Граница «форк/готовые библиотеки vs наш код» — форк даёт понимание кода, библиотеки дают механику RAG, наш код — поведение, гарантии, оркестрацию](adr/foundation/0022-boundary-fork-vs-own-code.md) |
| 0023 | foundation | accepted | [Лицензионный чек-лист OSS под AGPL-3.0 + правило источников («✅ проверено: <файл/url>» или «⚠️ предположение»)](adr/foundation/0023-license-checklist-and-source-rule.md) |
<!-- ADR-INDEX:END -->
