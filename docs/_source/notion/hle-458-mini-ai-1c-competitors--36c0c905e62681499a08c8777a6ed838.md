Here is the result of "view" for the Page with URL https://www.notion.so/36c0c905e62681499a08c8777a6ed838 as of 2026-05-26T17:59:15.908Z:
<page url="https://www.notion.so/36c0c905e62681499a08c8777a6ed838" icon="🤝">
<ancestor-path>
<parent-page url="https://www.notion.so/36b0c905e626813491fcf7e9ccf2046e" title="Дизайн системы 2.0"/>
<ancestor-2-page url="https://www.notion.so/36b0c905e626819eaca7ed0875cb6f8e" title="🤖 1С-ассистент — Агент-консультант по 1С ERP"/>
</ancestor-path>
<properties>
{"title":"Конкуренты mini-ai-1c / 1c-buddy / EDT-MCP (HLE-458) — нарезка инструментов, темы 2/7/17"}
</properties>
<content>
> Источник: отчёты Claude Code по задаче [HLE-458](https://linear.app/hleserg/issue/HLE-458) — `result-HLE-458.md` + `notes-HLE-458.md`, read-only, 2026-05-26. Разбор трёх смежных/конкурентных проектов: состав MCP-серверов и инструментов. Это карта «что делают конкуренты и как нарезают функциональность», бьёт в темы 2 (поиск/граф), 7 (внешние MCP рядом), 17 (интеграция с Конфигуратором).
## Лицензии (важно — разные)
- **mini-ai-1c** — ⚠️ **Attribution Non-Commercial** (по отчёту). Коммерция запрещена, требует attribution @hawkxtreme. **Код брать нельзя**; кроме того, Non-Commercial несовместима с нашей AGPL/OSS-целью. Берём только архитектурные идеи.
- **1c-buddy** — ⚠️ лицензия НЕ ПОДТВЕРЖДЕНА: в notes «нужно проверить LICENSE», в result лицензия не указана. Перед любым использованием — сверить LICENSE репо.
- **EDT-MCP** — ✅ **GNU AGPL v3.0** (Copyright 2026 DitriX, по отчёту). Совместима с нашей AGPL.
## hawkxtreme/mini-ai-1c (\~197★) — ближайший конкурент
Desktop (Tauri 2 + Rust + React 19), чат для разработки на 1С. Ценность для нас — **образец архитектуры, не код** (лицензия запрещает).
**4 встроенных MCP-сервера — чистая нарезка по доменам:**
- **1С:Справка** (TS, 4 инстр.) — FTS5-поиск по `.hbk` файлам установленной платформы (синтаксис/запросы/язык). SQLite WAL + FTS5 unicode61.
- **1С:Метаданные** (TS, 2 инстр.) — тонкий прокси к `vladimir-kharin/1c_mcp` (тот самый кандидат №1 из HLE-464!) по HTTP JSON-RPC.
- **1С:Напарник** (TS, 3 инстр.) — клиент [code.1c.ai](http://code.1c.ai) (SSE streaming, max 10 сессий, TTL 1ч).
- **1С:Поиск** (Rust, 15 инстр.) — символьный индекс + граф вызовов (tree-sitter-bsl + SQLite + Rayon + Tokio).
**1С:Поиск — нарезка инструментов (прямо под реш. 2.3 о роутинге):** `find_symbol` (индекс, **1ms**) vs `search_code` (grep+regex, **77ms**) — разные сценарии; `get_function_context` (граф вызовов caller→callee в SQLite), `impact_analysis` (кто использует символ/объект), `smart_find` (symbol+code за один вызов), `get_object_structure` (одна точка входа — реквизиты/ТЧ/формы/модули).
> 🔥 **Эмпирика, релевантная дымовому прогону (реш. 1.4):** замеры сделаны на реальной ERP **10.8 ГБ / 123k файлов / 642k символов**: find_symbol 1ms, search_code 77ms. Это факт из отчёта (чужой бенчмарк), но показывает: tree-sitter + SQLite на объёме ERP реально тянет.
**Slash-команды (11):** /исправить, /доработай, /рефакторинг, /описание, /объясни, /ревью, /стандарты, /итс, /найти, /где, /объект. Полная поддержка внешних MCP (http/stdio/internal). Context compression: disabled/sliding_window/summarize, порог 75%.
## ROCTUP/1c-buddy
Python, Docker (порт 6002), веб-чат + MCP + OpenAI-совместимый шлюз к 1С:Напарнику. Наследник artesk/1copilot_MCP. 8 инструментов, **уникальные относительно mini-ai-1c:** `modify_1c_code`, `search_1c_documentation`, `search_its`, `fetch_its`, `diff_1c_documentation_versions`. Последний — сравнение доков платформы между версиями (перекликается с задачей 18 «обновление доков» и привязкой спек к версии из HLE-457).
## DitriXNew/EDT-MCP — AGPL
Eclipse/EDT-плагин (Java), встраивается в 1C:EDT 2025.2+. **56 инструментов в 9 группах**, мощнейший из трёх. HTTP+SSE, порт 8765.
Уникальное: полный LLM-debug-цикл (breakpoint → wait_for_break → variables → evaluate → step/resume, автономно), server-side отладка через Attach (rphost, HTTP-сервисы, регл./фоновые задания), профилирование, `validate_query` (синтаксис+семантика запроса в контексте проекта), семантический call hierarchy через BM-index EDT (не grep), рефакторинг с cascade update, скриншот формы PNG+YAML.
## Сравнение: нарезка функциональности
<table header-row="true">
<tr>
<td>Функция</td>
<td>mini-ai-1c</td>
<td>1c-buddy</td>
<td>EDT-MCP</td>
<td>Азимут</td>
</tr>
<tr>
<td>Поиск по коду (grep/FTS)</td>
<td>✅</td>
<td>❌</td>
<td>✅</td>
<td>✅ нужен</td>
</tr>
<tr>
<td>Символьный индекс</td>
<td>✅ 642k, 1ms</td>
<td>❌</td>
<td>✅</td>
<td>✅ нужен</td>
</tr>
<tr>
<td>Граф вызовов</td>
<td>✅ caller/callee</td>
<td>❌</td>
<td>✅ call hierarchy</td>
<td>✅ нужен</td>
</tr>
<tr>
<td>Справка платформы</td>
<td>✅ .hbk FTS</td>
<td>❌</td>
<td>✅</td>
<td>✅ (реш. 1.6, mcp-bsl-platform-context)</td>
</tr>
<tr>
<td>ИТС / Напарник</td>
<td>✅ 3</td>
<td>✅ 8</td>
<td>❌</td>
<td>❌</td>
</tr>
<tr>
<td>Дебаггинг 1С</td>
<td>❌</td>
<td>❌</td>
<td>✅ 12</td>
<td>❌</td>
</tr>
<tr>
<td>Рефакторинг метаданных</td>
<td>❌</td>
<td>❌</td>
<td>✅ 3</td>
<td>❌</td>
</tr>
<tr>
<td>Интеграция с редактором</td>
<td>✅ EditorBridge WM_CHAR</td>
<td>❌</td>
<td>✅ write_module_source</td>
<td>? (тема 17)</td>
</tr>
</table>
## Что брать (идеи/ориентиры, НЕ код)
1. **Нарезка инструментов 1С:Поиск** — ориентир для Азимута: разделение find_symbol (индекс) vs search_code (grep), impact_analysis и get_function_context как отдельные инструменты поверх одного индекса, get_object_structure как единая точка входа. Стыкуется с реш. 2.3.
2. **Разделение ролей серверов** (mini-ai-1c: один сервер = один домен) — подтверждает реш. 1.5/1.7 (несколько MCP рядом, без шлюза).
3. **1c-buddy: diff_1c_documentation_versions** — идея для задачи 18 (сравнение версий доков).
## Кандидаты на внешний MCP рядом (тема 7)
- **EDT-MCP** — ✅ AGPL, работает HTTP-сервером, подключается через mcpServers. Для пользователей EDT. `validate_query` и `get_content_assist` — capability, которую без EDT почти не сделать. ⚠️ нужен сам EDT — у мамы/Сергея используется ли EDT, решает Сергей.
- **1c-buddy MCP** — ✅ кандидат (Streamable HTTP, 8 инстр. по ИТС/докам, Docker), **ОДНАКО** лицензия не подтверждена (см. вверху) — сначала сверить LICENSE.
- **mini-ai-1c (1С:Поиск / 1С:Справка)** — ❌ код нельзя (Non-Commercial). Подход (FTS5 по .hbk) — можно реализовать самостоятельно (хотя у нас справка платформы уже закрыта реш. 1.6).
## Что НЕ брать
Дебаггинг EDT (12 инстр. — требует EDT, не приоритет консультанта), код mcp-1c-search (Rust, переписывать на Python незачем — образец нарезки берём), код mini-ai-1c (Non-Commercial).
---
## ⚠️ Интеграция с Конфигуратором — факт из отчёта, НЕ проверено нами (тема 17)
По отчёту HLE-458, EditorBridge в mini-ai-1c работает так (всё ниже — утверждения из чужого репо, не проверены на наших исходниках/прогоне):
- Отдельный .NET `EditorBridge.exe`, подключение через Named Pipe `\\.\pipe\mini-ai-editor-bridge-<USERNAME>`.
- UIAutomation для определения фокусированного редактора.
- **Ввод текста через WM_CHAR** — отчёт утверждает, что это обходит keyboard hooks Конфигуратора, которые блокируют обычный SendKeys. Windows only, без clipboard.
- Чтение кода (по отчёту) — UIAutomation + Ctrl+A/Ctrl+C либо через HTTP-сервис 1С.
> Эти утверждения про поведение Конфигуратора взяты из чужого репо (mini-ai-1c) и НЕ проверены нами. Перед использованием в задаче 17 (живые процедуры) — проверить/согласовать с Сергеем (правило про код 1С).
> Ничего не прикручиваем сейчас — это реестр/ориентир. mini-ai-1c уже в реш. 1.7a (Сергею на захват кода), EDT-MCP и 1c-buddy — кандидаты темы 7.
</content>
</page>
