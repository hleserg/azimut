Here is the result of "view" for the Page with URL https://www.notion.so/36c0c905e626813689ade4d5112deae1 as of 2026-05-26T17:18:14.470Z:
<page url="https://www.notion.so/36c0c905e626813689ade4d5112deae1" icon="🔌">
<ancestor-path>
<parent-page url="https://www.notion.so/36b0c905e626813491fcf7e9ccf2046e" title="Дизайн системы 2.0"/>
<ancestor-2-page url="https://www.notion.so/36b0c905e626819eaca7ed0875cb6f8e" title="🤖 1С-ассистент — Агент-консультант по 1С ERP"/>
</ancestor-path>
<properties>
{"title":"Обёртки BSL LS в MCP (HLE-463) — выводы для реестра доноров"}
</properties>
<content>
> Источник: отчёты Claude Code по задаче [HLE-463](https://linear.app/hleserg/issue/HLE-463) — `result-HLE-463.md` + `notes-HLE-463.md`, read-only, без запуска кода, 2026-05-26. **Обновлено: пришёл result, страница переписана начиная с него (раньше была только по notes). Противоречий с notes нет; result добавил уточнения по путям установки, требованиям на хост, графу в plugin-варианте и усилил рекомендацию.**
## Что разбирали
Две обёртки BSL Language Server — как обернуть BSL LS в инструмент для агента и какой ценой. Вопрос важен для реестра доноров (BSL LS там кандидат на парсер, если tree-sitter не хватит).
## claude-code-bsl-lsp (1c-syntax, MIT)
Claude Code **плагин**, НЕ MCP-сервер. Bash/PowerShell + JSON-конфиги.
- Механизм: `.lsp.json` объявляет `bsl-language-server lsp` (`extensionToLanguage`: .bsl/.os → bsl, startupTimeout 120с), Claude Code сам запускает его дочерним процессом и общается через stdio LSP. Мост встроен в платформу — Claude Code транслирует LSP в контекст агента автоматически.
- **Ключевое: Java НЕ нужна.** BSL LS скачивается как нативный бинарник (pre-built native image, вероятно GraalVM), не JAR. SessionStart-хук авто-проверяет/обновляет бинарник с GitHub Releases (дроссель раз в 8 мин).
- **Пути установки:** Linux/macOS → `~/.local/share/bsl-language-server/<version>/`; Windows → `%LOCALAPPDATA%\Programs\bsl-language-server\`.
- **Требования на хост:** только `curl`/`wget` + `unzip` для первой установки, на Windows ещё `git` (Git Bash). Никакой Java, никакого Docker.
- Возможности (стандартный LSP): \~180 BSL-диагностик, go-to-definition, find references, hover (сигнатура+тип), symbol navigation. Code actions / formatting — есть, но нам не нужны (это разработка, не консультирование).
- **Графа вызовов своего НЕТ.** Claude Code получает стандартный LSP (`definition`, `workspace/symbol`, `documentDiagnostics`, `callHierarchy/incoming+outgoingCalls`), но отдельного инструмента построения полного графа в плагине нет — Claude Code сам интерпретирует LSP-ответы.
- **Не подходит нам напрямую:** это LSP-плагин Claude Code, не MCP-сервер.
## mcp-bsl-lsp-bridge (SteelMorgan, Apache 2.0)
Полноценный MCP-сервер на Go 1.24.2 (mcp-go, lsprotocol-go, jsonrpc2). Всё работает внутри Docker.
- Архитектура: IDE/агент → `docker exec` (stdio MCP) → mcp-lsp-bridge (Go, MCP) → TCP:9999 (jsonrpc2) → lsp-session-manager (Go daemon, держит сессию) → stdio LSP → BSL LS (Java 17, -Xmx6g/-Xms2g) → volume mount кода 1С (`/projects`).
- **BSL LS здесь = JAR (****`*-exec.jar`****) + Java 17 JRE внутри Docker** (`openjdk-17-jre-headless`, s6-overlay для процессов). Java спрятана в контейнер — пользователь ставит Docker, не JRE.
- Требования: Docker + Compose **обязательно**, 8+ GB RAM (Xmx6g+Xms2g+overhead), один проект = один контейнер.
- **Самое ценное — ****`call_graph`****:** рекурсивный граф вызовов как надстройка над LSP CallHierarchy (BSL LS отдаёт стандартные incoming/outgoing по 1 уровню, мост рекурсивно обходит и строит полное дерево). Параметры: depth_up/down=5, max_nodes=100 (hard 500), timeout 60с, детекция циклов, параллельный обход (goroutines, semaphore=5). Со списком 25+ известных BSL entry-points (см. ниже).
- Прочие экспонированные инструменты: project_analysis, symbol_explore, definition, hover, get_range_content, call_hierarchy, document_diagnostics. Rename/code_actions — есть, но нам не нужны.
- **Проблема Windows + Docker (WSL2):** чтение примаунченных каталогов медленное — авторы сами пишут «40к файлов \~12 мин, 9к \~3–5 мин», упирается в пропускную способность Docker. В roadmap как нерешённая задача.
## BSL entry-points из `call_graph.go:29-71` (ценный референс)
Готовый список «откуда начинаются цепочки», полезен для нашего анализатора графа и для поиска неиспользуемого кода:
- **Объект/документ:** ПриЗаписи, ПриПроведении, ПриОтменеПроведения, ПередЗаписью, ПередУдалением, ПриКопировании, ОбработкаЗаполнения, ОбработкаПроверкиЗаполнения
- **Форма:** ПриСозданииНаСервере, ПриОткрытии, ПриЗакрытии, ПередЗаписьюНаСервере, ПриЗаписиНаСервере, ПослеЗаписиНаСервере, ПриЧтенииНаСервере, ОбработкаОповещения, ОбработкаНавигационнойСсылки
- **Команды:** ОбработкаКоманды, ПриВыполнении
- **Сессия:** ПриНачалеРаботыСистемы, ПриЗавершенииРаботыСистемы, ПередНачаломРаботыСистемы, ПередЗавершениемРаботыСистемы
- **Регл.задания:** ОбработчикРегламентногоЗадания
- **HTTP/Web:** ОбработкаВызоваHTTPСервиса, ОбработкаВызоваWebСервиса
- **English-аналоги:** OnWrite, Posting, OnOpen, OnCreateAtServer, BeforeWrite, OnClose
## Сравнение
<table header-row="true">
<tr>
<td></td>
<td>claude-code-bsl-lsp</td>
<td>mcp-bsl-lsp-bridge</td>
</tr>
<tr>
<td>Тип</td>
<td>Claude Code плагин (LSP)</td>
<td>MCP-сервер</td>
</tr>
<tr>
<td>Язык</td>
<td>Bash/PowerShell</td>
<td>Go 1.24.2</td>
</tr>
<tr>
<td>BSL LS деплой</td>
<td>Нативный бинарник (auto-download)</td>
<td>JAR в Docker (Java 17)</td>
</tr>
<tr>
<td>Java на хосте</td>
<td>НЕ нужна</td>
<td>НЕ нужна (внутри Docker)</td>
</tr>
<tr>
<td>Docker</td>
<td>Не нужен</td>
<td>Обязателен</td>
</tr>
<tr>
<td>RAM</td>
<td>н/д</td>
<td>8+ GB</td>
</tr>
<tr>
<td>call_graph</td>
<td>нет</td>
<td>Да (рекурсивный, entry-points)</td>
</tr>
<tr>
<td>Применимость к MCP</td>
<td>Нет (LSP-плагин)</td>
<td>Да (нативный MCP)</td>
</tr>
<tr>
<td>Машина мамы</td>
<td>Потенциально (без Java/Docker)</td>
<td>Нет (Docker + 8GB)</td>
</tr>
<tr>
<td>Лицензия</td>
<td>MIT</td>
<td>Apache 2.0</td>
</tr>
</table>
## Что BSL LS даёт сверх tree-sitter
Через эти мосты BSL LS добавляет семантический уровень поверх синтаксиса — не просто «что написано», а «что это значит и где используется в контексте всего проекта»:
- кросс-модульное разрешение имён (definition между файлами) — tree-sitter видит только внутри файла;
- полный граф вызовов (call_graph) с детекцией entry-points и циклов;
- \~180 BSL-специфичных диагностик (не только синтаксис);
- семантический hover с типами.
---
## 📌 Рекомендации к закреплению
1. **Ни одну из двух обёрток в текущем виде не берём.** claude-code-bsl-lsp — не MCP (привязан к Claude Code). mcp-bsl-lsp-bridge — Docker + 8GB RAM + известная проблема Windows+WSL2, неприемлемо для сценария «маме не ставить тяжёлое».
2. **Явная рекомендация отчёта: для Азимута v1 — tree-sitter, без BSL LS.** Обоснование: машина мамы (Docker/8GB заблокированы), Python-стек (оба моста не на Python — код не переиспользуется), тип задачи (консультант читает и объясняет, не пишет/рефакторит — AST + поиск символов от tree-sitter покрывают большинство запросов). Что теряем: кросс-модульное разрешение имён и call_graph — реальные потери для сложных вопросов «где ещё вызывается процедура», но стоимость инфраструктуры перевешивает.
3. **Путь v2, если call_graph станет критичен:** лёгкий **Python-клиент к нативному бинарнику BSL LS** (как делает claude-code-bsl-lsp, только в MCP-варианте) — бинарник запускается как subprocess с аргументом `lsp`, общается через stdio LSP. Никакого Docker, никакой Java. Требует разработки LSP-клиента на Python. Прямо стыкуется с реш. 1.10 («1c-syntax вызывать отдельным процессом, не линковать»).
4. **Ценные идеи на будущее (если tree-sitter не хватит):**
	- **Паттерн ****`call_graph`**** как надстройка над LSP CallHierarchy** — рекурсивный обход на уровне моста, не BSL LS. Резонирует с реш. 2.2 (многоуровневый обход, которого нет в bsl-atlas).
	- **Список BSL entry-points** (см. выше) — готовый справочник точек входа для графа и для find_unused.
5. **Для консультанта из набора LSP-инструментов нужны только:** call_graph, definition, hover, document_diagnostics. Rename/code_actions — нет.
6. **Актуализировать реестр доноров:** по строке BSL LS добавить наблюдение — есть **нативный бинарник BSL LS без Java** (из claude-code-bsl-lsp), снимает главное возражение против BSL LS («Java, маме не ставить вторую среду»). Если дойдёт до BSL LS — брать нативный бинарник + Python-клиент, не JAR-в-Docker.
> Ничего не прикручиваем сейчас — это реестр-уровень. Java-vs-Python и «tree-sitter хватит или нет» решается на дымовом прогоне (реш. 1.4).
</content>
</page>
