# Заметки по HLE-463: Обёртки BSL LS в MCP

## Репо 1: 1c-syntax/claude-code-bsl-lsp
## Репо 2: SteelMorgan/mcp-bsl-lsp-bridge
## Дата: 2026-05-26

---

## РЕПО 1: claude-code-bsl-lsp

### Файловая структура (полная — репо компактный)
```
.claude-plugin/
  marketplace.json   # плагин-манифест marketplace
  plugin.json        # метаданные плагина
.lsp.json            # объявление LSP-сервера
LICENSE              # MIT
README.md
hooks/
  check-bsl-ls.sh    # bash: установка/обновление BSL LS
  check-bsl-ls.ps1   # PowerShell: то же самое
  hooks.json         # триггер: SessionStart
```

### .lsp.json (ключевой файл)
```json
{
  "bsl": {
    "command": "bsl-language-server",
    "args": ["lsp"],
    "extensionToLanguage": {
      ".bsl": "bsl",
      ".os": "bsl"
    },
    "startupTimeout": 120000
  }
}
```
→ Claude Code запускает `bsl-language-server lsp` как дочерний процесс, общается через **stdio LSP**.

### hooks/hooks.json
```json
"SessionStart": [
  {
    "type": "command",
    "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/check-bsl-ls.sh\" 2>/dev/null || pwsh ...",
    "timeout": 120
  }
]
```
→ При старте сессии автоматически проверяет/скачивает BSL LS binary.

### check-bsl-ls.sh — ключевые факты
- BSL LS скачивается как **нативный бинарник** (не JAR!):
  - Linux: `bsl-language-server_nix.zip` → `bsl-language-server/bin/bsl-language-server`
  - macOS: `bsl-language-server_mac.zip` → `bsl-language-server.app/Contents/MacOS/bsl-language-server`
  - Windows: `bsl-language-server_win.zip` → `bsl-language-server/bsl-language-server.exe`
- Установка: `~/.local/share/bsl-language-server/<version>/`
- Симлинк: `~/.local/bin/bsl-language-server`
- Дросселирование GitHub API: проверяет обновления не чаще раз в 8 минут
- Версионирование: хранит SERVER-INFO с `{"version":"...", "lastUpdate":...}`, автоудаляет старые версии

### КРИТИЧНО: Java НЕ нужна!
README.md явно: «The plugin automatically downloads BSL Language Server on first session start.»
BSL LS имеет предсобранные нативные бинарники (вероятно GraalVM native-image). Нет JRE-зависимости на хосте.

### Возможности (из README.md)
- Diagnostics (code quality checks)
- Go to definition
- Find references
- Hover information
- Code actions and quick fixes
- Symbol navigation
- Formatting
- Auto-update (проверяет новые релизы при старте сессии)

### Архитектура (claude-code-bsl-lsp)
```
Claude Code (агент)
    │ .lsp.json
    ▼
BSL Language Server (нативный бинарник)
    │ stdio LSP
    ▼
[index 1С кода, диагностики, навигация]
```
Claude Code сам транслирует LSP-протокол в контекст для агента — мост встроен в платформу.

### Язык
Bash (check-bsl-ls.sh) + PowerShell (check-bsl-ls.ps1) + JSON (конфиги). Не Python.

### Лицензия
MIT — LICENSE:1, Copyright (c) 2025 1c-syntax.

---

## РЕПО 2: mcp-bsl-lsp-bridge

### Файловая структура (существенные части)
```
main.go                        # точка входа MCP сервера
go.mod                         # Go 1.24.2
mcpserver/
  setup.go                     # регистрация MCP-сервера
  tools.go                     # регистрация инструментов
  tools/
    call_graph.go              # ★ граф вызовов (уникальная надстройка)
    call_hierarchy.go
    definition.go
    hover.go
    symbol_explore.go
    project_analysis.go
    document_diagnostics.go
    workspace_diagnostics.go
    code_actions.go
    rename.go
    prepare_rename.go
    semantic_tokens.go
    format_document.go
    ...
lsp/
  client.go                    # LSP клиент
  tcp_client.go                # TCP-соединение к lsp-session-manager (port 9999)
  lsp.go                       # LSP protocol
cmd/
  lsp-session-manager/main.go  # daemon: держит BSL LS запущенным
  lsp-proxy/main.go            # TCP proxy
Dockerfile                     # multi-stage build
docker-compose.yml
docker/
  lsp_config.json              # конфиг: mode=session, host=localhost, port=9999
  bsl-ls.json                  # BSL LS config
  s6-rc.d/bsl-ls/run           # s6-overlay service: запускает lsp-session-manager
docs/tools/tools-reference.md  # полный справочник инструментов
README.AI.md                   # инструкция для ИИ-агента
```

### go.mod — зависимости
```
go 1.24.2
github.com/mark3labs/mcp-go v0.43.2       # MCP framework
github.com/myleshyson/lsprotocol-go       # LSP типы
github.com/sourcegraph/jsonrpc2           # JSON-RPC2 over TCP
github.com/gorilla/websocket             # WebSocket (альтернативный транспорт)
github.com/fsnotify/fsnotify             # file watcher
```
→ Язык: **Go 1.24.2**

### Архитектура (README.md, схема)
```
IDE (Cursor/Claude Code)
    │ docker exec -i <container> mcp-lsp-bridge
    ▼
mcp-lsp-bridge (Go, MCP server, в контейнере)
    │ TCP :9999
    ▼
lsp-session-manager (Go daemon, в контейнере)
    │ stdio
    ▼
BSL Language Server (Java JAR, в контейнере)
    │ volume mount
    ▼
/projects (код 1С, примонтирован с хоста)
```

### docker/s6-rc.d/bsl-ls/run — как запускается BSL LS (файл:9-34)
```sh
exec /usr/bin/lsp-session-manager \
    --port=${BSL_LS_PORT:-9999} \
    --workspace=${WORKSPACE_ROOT:-/projects} \
    --command=java \
    -- \
    -Xmx${MCP_LSP_BSL_JAVA_XMX:-6g} \
    -Xms${MCP_LSP_BSL_JAVA_XMS:-2g} \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -jar /opt/bsl-ls/bsl-language-server.jar \
    lsp \
    -c /etc/mcp-lsp-bridge/bsl-ls.json
```
→ BSL LS = JAR, Java 17 JRE (openjdk-17-jre-headless в контейнере), 6GB heap default.

### Dockerfile — ключевые детали (файл:31-34, 46-49)
```dockerfile
# Скачивает бинарник *-exec.jar (не нативный):
BSL_LS_URL=$(... | grep '"browser_download_url": *"[^"]*-exec.jar"' ...)
# Зависимости в образе:
apt-get install -y openjdk-17-jre-headless procps netcat-openbsd locales
```
→ Внутри контейнера — **Java 17 JRE** + Java JAR. Пользователь ставит Docker, не Java напрямую.

### Требования (README.md)
- Docker + Docker Compose на хосте
- 8+ ГБ RAM (BSL LS требователен на больших проектах)
- Один проект = один контейнер

### Проблема Windows + Docker (README.md — Дорожная карта)
> «Если использовать докер в Windows (WSL 2), то скорость чтения примаунченных каталогов ограничена. 40к файлов у меня читает около 12 минут. 9к файлов — в районе 3-5 минут.»

### Инструменты — экспонированные по умолчанию (docs/tools/tools-reference.md)
**Поиск и навигация:**
- `project_analysis` — универсальный поиск: символы, файлы, текст
- `symbol_explore` — детальный поиск с кодом и документацией
- `definition` — перейти к определению
- `hover` — документация и сигнатура
- `get_range_content` — получить фрагмент кода по координатам

**Анализ зависимостей:**
- `call_hierarchy` — кто вызывает / что вызывает (1 уровень)
- **`call_graph`** — полный граф вызовов (рекурсивный, надстройка над BSL LS)

**Диагностика:**
- `document_diagnostics` — синтаксические ошибки, предупреждения, стиль
- `code_actions` — автоматические исправления

**Рефакторинг:**
- `prepare_rename` — проверить возможность переименования
- `rename` — переименовать символ везде (preview/apply)

**Служебные:**
- `lsp_status` — статус LSP и прогресс индексации
- `did_change_watched_files` — уведомить об изменении файлов

**Скрытые (реализованы, не экспонированы по умолчанию):**
format_document, range_formatting, implementation, signature_help, semantic_tokens, folding_range, document_link, document_color, color_presentation, workspace_diagnostics, did_change_configuration, execute_command, detect_project_languages, infer_language, lsp_connect, lsp_disconnect, mcp_lsp_diagnostics

### call_graph.go — уникальная надстройка (файл:29-71)
Список известных точек входа BSL (bslEntryPoints):
- Документ: ПриЗаписи, ПриПроведении, ПриОтменеПроведения, ПередЗаписью, ПередУдалением, ПриКопировании, ОбработкаЗаполнения, ОбработкаПроверкиЗаполнения
- Форма: ПриСозданииНаСервере, ПриОткрытии, ПриЗакрытии, ПередЗаписьюНаСервере, ПриЗаписиНаСервере, ПослеЗаписиНаСервере, ПриЧтенииНаСервере, ОбработкаОповещения, ОбработкаНавигационнойСсылки
- Команды: ОбработкаКоманды, ПриВыполнении
- Сессия: ПриНачалеРаботыСистемы, ПриЗавершенииРаботыСистемы, ПередНачаломРаботыСистемы, ПередЗавершениемРаботыСистемы
- Регл.задания: ОбработчикРегламентногоЗадания
- HTTP/Web: ОбработкаВызоваHTTPСервиса, ОбработкаВызоваWebСервиса
- English: OnWrite, Posting, OnOpen, OnCreateAtServer, BeforeWrite, OnClose

Параметры: depth_up=5 (default), depth_down=5, max_nodes=100, hard limit=500, timeout=60s
Детекция циклов, параллельный обход (goroutines, semaphore=5 конкурентных LSP-вызовов).

### Лицензия
Apache 2.0 — LICENSE (без copyright строки в заголовке, только шаблон Apache).

---

## Сравнительная таблица

| | claude-code-bsl-lsp | mcp-bsl-lsp-bridge |
|---|---|---|
| Язык моста | Bash/PowerShell | Go 1.24.2 |
| Тип | Claude Code плагин (LSP) | MCP сервер |
| BSL LS деплой | Нативный бинарник (auto-download) | JAR в Docker |
| Java на хосте | НЕ нужна | НЕ нужна (внутри Docker) |
| Docker | НЕ нужен | Нужен |
| RAM | Не указано | 8+ ГБ |
| Транспорт BSL LS | stdio | stdio (через lsp-session-manager по TCP:9999) |
| call_graph | нет | Да (рекурсивный, BSL entry-points) |
| Лицензия | MIT | Apache 2.0 |
| Применимость к Азимуту | Нет (не MCP) | Нет (Docker + 8 GB) |

---

## НАБЛЮДЕНИЯ

1. Нативный бинарник BSL LS снимает Java-проблему для claude-code-bsl-lsp, но это LSP-плагин, не MCP-сервер.

2. mcp-bsl-lsp-bridge прячет Java внутрь Docker — с точки зрения пользователя ставится Docker, не JRE. Но Docker сам по себе тяжёл.

3. call_graph — самое ценное в mcp-bsl-lsp-bridge. Это надстройка над LSP CallHierarchy (IncomingCalls/OutgoingCalls), сделанная на уровне моста, не на уровне BSL LS. BSL LS отдаёт стандартный LSP call_hierarchy, мост рекурсивно его обходит.

4. BSL LS через эти мосты даёт сверх tree-sitter:
   - Кросс-модульное разрешение имён (definition между файлами)
   - Полный граф вызовов с детекцией entry-points
   - 180+ BSL-специфичных диагностик (не только синтаксис)
   - Семантические токены (hover с типами)

5. Для консультанта (не разработчика) нужны только: call_graph, definition, hover, document_diagnostics. Rename/code_actions — нет.

6. Windows + Docker — известная проблема у mcp-bsl-lsp-bridge. Для мамы это неприемлемо.

7. Авторы mcp-bsl-lsp-bridge сами пишут в roadmap: «Сделать решение под Windows» как нерешённую задачу.
