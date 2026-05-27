# Результат HLE-463: Обёртки BSL LS в MCP

**Репо 1:** https://github.com/1c-syntax/claude-code-bsl-lsp  
**Репо 2:** https://github.com/SteelMorgan/mcp-bsl-lsp-bridge  
**Дата исследования:** 2026-05-26  
**Статус:** READ-ONLY. Без запуска кода.

---

## Репо 1: 1c-syntax/claude-code-bsl-lsp

### Архитектура обёртки

Claude Code **плагин** (не MCP-сервер), подключающий BSL Language Server как LSP-провайдер через механизм `.lsp.json`.

**Транспортная схема:**

```
Claude Code (агент)
    │ .lsp.json: command="bsl-language-server", args=["lsp"]
    ▼
BSL Language Server (нативный бинарник, дочерний процесс)
    │ stdio / LSP protocol
    ▼
[Индекс кода 1С: диагностики, навигация, символы]
```

Файл `.lsp.json` (репо:`.lsp.json`) объявляет сервер:
```json
{
  "bsl": {
    "command": "bsl-language-server",
    "args": ["lsp"],
    "extensionToLanguage": { ".bsl": "bsl", ".os": "bsl" },
    "startupTimeout": 120000
  }
}
```
Claude Code берёт LSP-протокол на себя — транслирует LSP в контекст агента автоматически. Мост встроен в платформу.

**Хук SessionStart** (`hooks/hooks.json`) при каждом старте сессии запускает `check-bsl-ls.sh` (или `.ps1`): проверяет установленную версию BSL LS, при необходимости скачивает свежую с GitHub Releases. Дросселирование: не чаще раз в 8 минут.

### Перечень возможностей BSL LS (все стандартные LSP)

| Возможность | Нужна Азимуту |
|---|---|
| Diagnostics — ~180 BSL-специфичных проверок | ✓ (анализ кода) |
| Go to definition | ✓ (навигация по коду) |
| Find references | ✓ (поиск использований) |
| Hover — сигнатура и тип | ✓ (описание символа) |
| Symbol navigation | ✓ (поиск символов) |
| Code actions / quick fixes | ✗ (разработка, не консультирование) |
| Formatting | ✗ |
| Auto-update при старте | нейтрально |

### Зависимости и среда

- **BSL LS**: нативный бинарник — **Java не нужна**. Pre-built native images для Linux/macOS/Windows, скачиваются автоматически.
  - Linux/macOS: `~/.local/share/bsl-language-server/<version>/`
  - Windows: `%LOCALAPPDATA%\Programs\bsl-language-server\`
- **Требования на хост**: только `curl` или `wget` + `unzip` (для первой установки), `git` для Windows (Git Bash).
- Размер бинарника: не определить из репо (нужно смотреть Releases BSL LS).

### Язык моста

Bash (`check-bsl-ls.sh`) + PowerShell (`check-bsl-ls.ps1`) + JSON (конфиги). Не Python. Мост как таковой — минималистичный: только установка/обновление бинарника.

### Граф вызовов / структура кода

**Не реализовано** в самом плагине. Claude Code получает стандартный LSP — `textDocument/definition`, `workspace/symbol`, `textDocument/documentDiagnostics`, `callHierarchy/incomingCalls/outgoingCalls` и т.д. — но специального инструмента для построения полного графа вызовов нет. Claude Code сам интерпретирует LSP-ответы.

### Лицензия

**MIT** (`LICENSE:1`), Copyright (c) 2025 1c-syntax.

---

## Репо 2: SteelMorgan/mcp-bsl-lsp-bridge

### Архитектура обёртки

Полноценный **MCP-сервер** на Go, обёртывающий BSL Language Server через многослойную транспортную схему. Принципиально: всё работает внутри Docker-контейнера.

**Транспортная схема:**

```
IDE/Агент (хост)
    │ docker exec -i <container> mcp-lsp-bridge  [stdio MCP]
    ▼
mcp-lsp-bridge (Go, MCP server, внутри контейнера)
    │ TCP :9999  [jsonrpc2]
    ▼
lsp-session-manager (Go daemon, держит сессию)
    │ stdio  [LSP protocol]
    ▼
BSL Language Server (Java 17, -Xmx6g / -Xms2g)
    │ volume mount
    ▼
/projects (код 1С, смонтирован с хоста)
```

Конфигурация транспорта — `docker/lsp_config.json`:
```json
{
  "language_servers": {
    "bsl-language-server": {
      "mode": "session",
      "host": "localhost",
      "port": 9999
    }
  }
}
```

Запуск BSL LS (`docker/s6-rc.d/bsl-ls/run:23-34`):
```sh
exec /usr/bin/lsp-session-manager \
    --command=java \
    -- \
    -Xmx${MCP_LSP_BSL_JAVA_XMX:-6g} \
    -Xms${MCP_LSP_BSL_JAVA_XMS:-2g} \
    -XX:+UseG1GC \
    -jar /opt/bsl-ls/bsl-language-server.jar lsp
```

### Перечень возможностей (экспонированных по умолчанию)

**Поиск и навигация:**

| Tool | LSP-метод | Нужен Азимуту |
|---|---|---|
| `project_analysis` | `workspace/symbol`, `textDocument/documentSymbol` | ✓ |
| `symbol_explore` | `workspace/symbol` + code extraction | ✓ |
| `definition` | `textDocument/definition` | ✓ |
| `hover` | `textDocument/hover` | ✓ |
| `get_range_content` | прямое чтение файла | ✓ |

**Анализ зависимостей (ключевое):**

| Tool | Реализация | Нужен Азимуту |
|---|---|---|
| `call_hierarchy` | `callHierarchy/incomingCalls` + `outgoingCalls` (1 уровень) | ✓ |
| **`call_graph`** | **рекурсивный обход `call_hierarchy` (надстройка, не LSP)** | ✓✓ |

**Диагностика:**

| Tool | LSP-метод | Нужен Азимуту |
|---|---|---|
| `document_diagnostics` | `textDocument/diagnostic` (LSP 3.17+) | ✓ |
| `code_actions` | `textDocument/codeAction` | ✗ (разработка) |

**Рефакторинг** (rename, prepare_rename) — не нужны Азимуту.  
**Скрытые** (не экспонированы по умолчанию): workspace_diagnostics, format_document, semantic_tokens, implementation, signature_help, folding_range, execute_command и др.

### call_graph — подробно

`mcpserver/tools/call_graph.go` — уникальная надстройка, не присутствующая в базовом LSP. BSL LS отдаёт стандартные `IncomingCalls`/`OutgoingCalls` (по одному уровню), мост рекурсивно их обходит и строит полное дерево.

Параметры (с дефолтами): `depth_up=5`, `depth_down=5`, `max_nodes=100` (hard limit=500), таймаут=60с.

Детекция точек входа BSL (`call_graph.go:29-71`) — список 25+ событий:
- Объект: `ПриЗаписи`, `ПриПроведении`, `ПриОтменеПроведения`, `ПередЗаписью`, `ПередУдалением`, `ПриКопировании`, `ОбработкаЗаполнения`, `ОбработкаПроверкиЗаполнения`
- Форма: `ПриСозданииНаСервере`, `ПриОткрытии`, `ПриЗакрытии`, `ПередЗаписьюНаСервере`, `ПриЗаписиНаСервере`, `ПослеЗаписиНаСервере`, `ПриЧтенииНаСервере`, `ОбработкаОповещения`, `ОбработкаНавигационнойСсылки`
- Команды: `ОбработкаКоманды`, `ПриВыполнении`
- Сессия: `ПриНачалеРаботыСистемы`, `ПриЗавершенииРаботыСистемы`, `ПередНачаломРаботыСистемы`, `ПередЗавершениемРаботыСистемы`
- Регл.задания: `ОбработчикРегламентногоЗадания`
- HTTP/Web: `ОбработкаВызоваHTTPСервиса`, `ОбработкаВызоваWebСервиса`
- English-аналоги: `OnWrite`, `Posting`, `OnOpen`, `OnCreateAtServer`, `BeforeWrite`, `OnClose`

Также: детекция циклов, параллельный обход (goroutines + semaphore=5 конкурентных LSP-вызовов).

### Зависимости и среда

**На хосте:**
- Docker + Docker Compose — обязательно
- 8+ ГБ RAM (BSL LS с дефолтными настройками: Xmx6g + Xms2g + overhead)

**Внутри контейнера** (`Dockerfile:46`):
- `openjdk-17-jre-headless` — Java 17 JRE headless
- BSL LS как JAR: `bsl-language-server-exec.jar` (скачивается при сборке образа)
- s6-overlay для управления процессами

**Проблема Windows + Docker** (`README.md` — Дорожная карта):
> «40к файлов у меня читает около 12 минут. 9к файлов — в районе 3-5 минут. (упирается в общую "пропускную способность докера")»
Это нерешённая задача в roadmap.

### Язык моста

**Go 1.24.2** (`go.mod:3`). Не Python, переиспользовать код напрямую нельзя, можно только переиспользовать подход.

### Граф вызовов / структура кода

**Да** — `call_graph` даёт полный граф вызовов с:
- Кросс-модульным разрешением имён (BSL LS индексирует весь workspace)
- Детекцией точек входа BSL (события форм, объектов, задания)
- Детекцией циклов
- Настраиваемой глубиной и лимитом узлов

Дополнительно: `definition` и `symbol_explore` дают кросс-модульную навигацию — BSL LS видит всю кодовую базу как связный граф.

### Лицензия

**Apache 2.0** (`LICENSE`) — позволяет использование, модификацию, дистрибуцию при сохранении уведомлений.

---

## Сравнительная таблица

| Характеристика | claude-code-bsl-lsp | mcp-bsl-lsp-bridge |
|---|---|---|
| Тип | Claude Code плагин (LSP) | MCP сервер |
| Язык | Bash/PowerShell | Go 1.24.2 |
| BSL LS деплой | Нативный бинарник (auto-download) | JAR в Docker (Java 17) |
| Java на хосте | Не нужна | Не нужна (внутри Docker) |
| Docker | Не нужен | Обязателен |
| RAM | Не указано | 8+ ГБ |
| call_graph | Нет | Да (рекурсивный, с BSL entry-points) |
| Применимость к MCP | Нет (LSP-плагин) | Да (нативный MCP-сервер) |
| Лицензия | MIT | Apache 2.0 |
| Мама's machine | Потенциально (без Java/Docker) | Нет (Docker + 8 GB) |

---

## Ключевой вывод

### Что BSL LS даёт сверх tree-sitter

| Возможность | tree-sitter | BSL LS через мосты |
|---|---|---|
| Синтаксический разбор AST | ✓ (быстро, локально) | ✓ (медленнее, через индекс) |
| Кросс-модульное разрешение имён | ✗ (только в файле) | ✓ (весь workspace) |
| Граф вызовов (call_graph) | ✗ | ✓ (рекурсивный, с entry-points) |
| ~180 BSL-специфичных диагностик | ✗ | ✓ |
| Hover с типами (semantic) | ✗ | ✓ |
| Go to definition (cross-file) | ✗ | ✓ |

**BSL LS добавляет семантический уровень поверх синтаксиса**: не просто «что написано», а «что это значит и где используется в контексте всего проекта». Ключевая ценность для Азимута — `call_graph` с BSL-специфичными точками входа и кросс-модульное разрешение имён.

### Цена Java-зависимости

- **claude-code-bsl-lsp**: Java не нужна — нативные бинарники снимают проблему полностью.
- **mcp-bsl-lsp-bridge**: Java скрыта в Docker — пользователь ставит Docker, не JRE. Но Docker сам по себе тяжёл и проблемен на Windows с большими проектами.

### Какой из мостов предпочтительнее, ЕСЛИ возьмём BSL LS

Для AI-агентов (MCP): однозначно `mcp-bsl-lsp-bridge` — полноценный MCP-сервер с богатым набором инструментов и уникальным `call_graph`. `claude-code-bsl-lsp` — только для прямой интеграции в Claude Code через LSP, не в произвольный MCP-клиент.

Однако для нашего сценария (Азимут, Python, мама's machine) ни один не подходит «как есть»:
- `mcp-bsl-lsp-bridge`: Docker + 8GB RAM — нельзя
- `claude-code-bsl-lsp`: LSP-плагин, не MCP — нельзя

### Рекомендация

**Для Азимута v1: tree-sitter, без BSL LS.**

Обоснование:
1. **Мама's machine**: `mcp-bsl-lsp-bridge` требует Docker + 8 GB RAM — заблокировано. `claude-code-bsl-lsp` снимает Java-проблему (нативный бинарник), но это LSP-плагин, не MCP-сервер.
2. **Python-стек**: оба моста написаны не на Python (Bash/PS и Go соответственно). Никакого кода для переиспользования.
3. **Тип задачи**: консультант по 1С ERP читает и объясняет, не пишет и не рефакторит. tree-sitter даёт AST и поиск символов — этого достаточно для большинства консультационных запросов.
4. **Что теряем**: кросс-модульное разрешение имён и `call_graph`. Это реальные потери — граф вызовов был бы ценен для сложных вопросов типа «где ещё вызывается эта процедура». Но стоимость инфраструктуры перевешивает.

**Если call_graph критичен в будущем** — есть путь: написать лёгкий Python-клиент к нативному BSL LS бинарнику (как это делает `claude-code-bsl-lsp`, только в MCP-варианте). Нативный бинарник запускается как subprocess с `lsp` аргументом, общается через stdio LSP. Никакого Docker, никакого Java. Это возможный v2 — но требует разработки LSP-клиента на Python.

**Архитектурный инсайт из `call_graph.go`**: список точек входа BSL (25+ событий) и логика рекурсивного обхода — ценный референс для нашего собственного анализатора графа вызовов на tree-sitter, если пойдём этим путём.
