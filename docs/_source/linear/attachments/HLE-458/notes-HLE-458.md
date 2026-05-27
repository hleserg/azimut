# HLE-458: mini-ai-1c + 1c-buddy + EDT-MCP — Raw Notes

## 1. hawkxtreme/mini-ai-1c (~197★)

### Общее
- Tauri 2 (Rust backend) + React 19 + TypeScript frontend
- Desktop app (Windows primary, Linux/macOS теоретически)
- Лицензия: **Attribution Non-Commercial License** — НЕ MIT/Apache. Коммерческое использование ЗАПРЕЩЕНО. Требует attribution @hawkxtreme
- 197 звёзд на GitHub

### Архитектура: 4 встроенных MCP-сервера

#### 1. 1С:Справка (`src/mcp-servers/1c-help.ts`)
- TypeScript, `@modelcontextprotocol/sdk`
- 4 инструмента:
  - `search_1c_help(query, category?, limit?)` — FTS5 поиск по SQLite
  - `get_1c_help_topic(topic_id)` — полный текст топика по ID
  - `list_1c_help_versions()` — статус версий
  - `reindex_1c_help()` — принудительная переиндексация
- Читает .hbk файлы из установленной 1С платформы:
  - `shcntx_ru.hbk` — синтаксис-помощник
  - `shquery_ru.hbk` — язык запросов
  - `shlang_ru.hbk` — встроенный язык
- SQLite с FTS5 (`unicode61` tokenizer), WAL mode
- Хранит БД в `%APPDATA%/com.mini-ai-1c/help/help.db`
- Auto-detect 1С по стандартным путям (`C:\Program Files\1cv8`, `/opt/1cv8`)

#### 2. 1С:Метаданные (`src/mcp-servers/1c-metadata.ts`)
- TypeScript, тонкий прокси
- Форвардит все MCP-запросы к `vladimir-kharin/1c_mcp` через JSON-RPC 2.0 по HTTP
- Переадресуются: tools/list, tools/call, resources/list, resources/read, prompts/list, prompts/get
- Env: `ONEC_METADATA_URL` (default: `http://localhost/base/hs/mcp`), `ONEC_USERNAME`, `ONEC_PASSWORD`
- Bundled 1c_mcp_ext имеет только 2 инструмента:
  - `list_metadata_objects(type?, nameMask?)` — список объектов конфигурации
  - `get_metadata_structure(objectType, objectName)` — структура объекта
- Таймаут 5 секунд на HTTP-запрос

#### 3. 1С:Напарник (`src/mcp-servers/1c-naparnik.ts`)
- TypeScript, клиент к `code.1c.ai` REST API
- 3 инструмента:
  - `ask_1c_ai(question, programming_language?, create_new_session?)` — вопрос ИИ-консультанту
  - `explain_1c_syntax(syntax_element, context?)` — объяснить синтаксис
  - `check_1c_code(code, check_type: syntax|logic|performance)` — проверка кода
- SSE streaming ответов (eventsource-parser)
- Session management: max 10 сессий, TTL 1 час
- Tool call round-trip loop: при получении tool_calls → отправляет "rejected" статус обратно (не выполняет локально)
- Auth: `ONEC_AI_TOKEN` env
- Retry с exponential backoff (3 попытки, начиная с 1000ms)

#### 4. 1С:Поиск по конфигурации (`tauri-app/mcp-1c-search/`)
- Rust, SQLite (rusqlite bundled), tree-sitter + tree-sitter-bsl, Rayon, Tokio
- WAL mode, parallel indexing
- **15 инструментов** (12 + 3 сервисных):
  - `search_code(query, scope?, regex?, limit?)` — полнотекстовый grep с regexp
  - `get_file_context(path, line, context_lines?)` — код вокруг строки ±40
  - `find_symbol(name, type?, exact?)` — поиск в символьном индексе
  - `get_symbol_context(symbol_id)` — полный код функции
  - `smart_find(name)` — symbol + code в одном вызове
  - `find_function_in_object(function_name, object_name)` — функция в конкретном объекте 1С
  - `get_module_functions(module_path)` — все проц/функции модуля
  - `list_objects(type?, name_filter?)` — объекты конфигурации
  - `get_object_structure(name)` — полная структура: реквизиты, ТЧ, формы, команды, модули
  - `find_references(symbol_name, scope?)` — все вхождения символа
  - `impact_analysis(name)` — какие модули используют символ/объект
  - `get_function_context(function_name, object?)` — граф вызовов (что вызывает + что вызывается)
  - `stats` — статистика индекса
  - `benchmark` — бенчмарк
  - `sync_index` — перестройка индекса
- **Производительность** на ERP 10.8GB / 123k файлов / 642k символов:
  - find_symbol: 1ms
  - search_code: 77ms
- Граф вызовов: caller→callee рёбра в SQLite, обход через get_function_context

### Интеграция с Конфигуратором
- EditorBridge: отдельный .NET exe (`EditorBridge.exe`)
- Подключение через Named Pipe `\\.\pipe\mini-ai-editor-bridge-<USERNAME>`
- UIAutomation для чтения/определения фокусированного редактора
- Ввод текста: WM_CHAR (обходит проблему с keyboard hooks в Конфигураторе)
- WM_CHAR важен: keyboard hooks 1С не перехватывают WM_CHAR
- НЕ использует clipboard
- Windows only

### Поддержка внешних MCP
- `McpServerConfig` с `transport: 'http' | 'stdio' | 'internal'`
- Произвольные внешние MCP серверы поддерживаются полностью
- В settings UI можно добавлять кастомные MCP серверы

### Slash-команды (11 штук)
```
/исправить    — BSL + логические ошибки (check_bsl_syntax + fix)
/доработай    — доработка по задаче
/рефакторинг  — рефакторинг
/описание     — шапка описания ф-ции
/объясни      — объяснение кода
/ревью        — код-ревью
/стандарты    — проверка на стандарты 1С
/итс          — поиск в ИТС через ask_1c_ai
/найти        — поиск в конфигурации (find_symbol/search_code)
/где          — find_references
/объект       — get_object_structure
```

### Поддерживаемые LLM провайдеры
Anthropic/Claude, OpenAI, Ollama, Qwen CLI, Codex CLI, Gemini, DeepSeek, OpenRouter, 1С:Напарник

### Context compression
- `context_compress_strategy`: disabled | sliding_window | summarize
- 75% контекста модели как порог (автоматический)

---

## 2. ROCTUP/1c-buddy

- Python app: веб-чат + MCP сервер + OpenAI-совместимый API шлюз для 1С:Напарник
- Docker deployment (порт 6002)
- Streamable HTTP MCP транспорт (`http://localhost:6002/mcp`)
- Форк/развитие artesk/1copilot_MCP
- Лицензия: нужно проверить LICENSE файл

### 8 инструментов:
1. `ask_1c_ai` — общие вопросы по платформе 1С
2. `explain_1c_syntax` — объяснение объекта/метода/конструкции
3. `check_1c_code` — синтаксическая проверка / code review
4. `modify_1c_code` — изменение кода по явному заданию
5. `search_1c_documentation` — поиск по документации платформы
6. `search_its` — поиск по базе знаний ИТС
7. `fetch_its` — получение документа ИТС по id
8. `diff_1c_documentation_versions` — сравнение документации между двумя версиями платформы

### Веб-чат функции:
- Управление историей разговоров (хранится в браузере)
- Подключение внешних HTTP MCP серверов прямо из настроек
- Подсветка BSL/XML синтаксиса
- Визуализация mermaid диаграмм с сохранением в PNG
- Прикрепление файлов (.bsl, .xml, .txt)
- Статистика токенов
- OpenAI-совместимый API (`/v1/chat/completions`)

---

## 3. DitriXNew/EDT-MCP

- Eclipse/EDT plugin (Java)
- Лицензия: **GNU AGPL v3.0** (Copyright 2026 DitriX)
- Требования: 1C:EDT 2025.2+, Java 17+
- Streamable HTTP transport + SSE, порт 8765
- MCP Protocol 2025-11-25

### 56 инструментов в 9 группах:

#### Core / Project (8):
`get_edt_version`, `list_projects`, `get_configuration_properties`, `clean_project`, `revalidate_objects`, `get_check_description`, `export_configuration_to_xml`, `import_configuration_from_xml`

#### Errors & Problems (4):
`get_problem_summary`, `get_project_errors`, `get_bookmarks`, `get_tasks`

#### Code Intelligence (7):
`get_content_assist`, `get_platform_documentation`, `get_metadata_objects`, `get_metadata_details`, `list_subsystems`, `get_subsystem_content`, `find_references`

#### Tags (2):
`get_tags`, `get_objects_by_tags`

#### Applications & Testing (5):
`get_applications`, `list_configurations`, `update_database`, `debug_launch`, `run_yaxunit_tests`

#### Debugging (12):
`set_breakpoint`, `remove_breakpoint`, `list_breakpoints`, `wait_for_break`, `get_variables`, `step`, `resume`, `evaluate_expression`, `debug_yaxunit_tests`, `debug_status`, `start_profiling`, `get_profiling_results`

#### BSL Code (12):
`read_module_source`, `write_module_source`, `get_module_structure`, `list_modules`, `search_in_code`, `read_method_source`, `get_method_call_hierarchy`, `go_to_definition`, `get_symbol_info`, `get_form_layout_snapshot`, `get_form_screenshot`, `validate_query`

#### Refactoring (3):
`rename_metadata_object`, `delete_metadata_object`, `add_metadata_attribute`

#### Translation/LanguageTool (3):
`generate_translation_strings`, `translate_configuration`, `get_translation_project_info`

### Примечательные особенности:
- Полный дебаггинг цикл для LLM (set_breakpoint → wait_for_break → get_variables → evaluate_expression → step/resume)
- Поддержка Attach (server-side отладка rphost: HTTP services, scheduled jobs, background jobs)
- YAXUnit тесты в debug-режиме (полностью автономный LLM debug цикл)
- Профилирование: start_profiling / get_profiling_results
- Снимок формы в PNG + YAML layout snapshot (требует JVM флаг `-DnativeFormBufferedLayoutRender=true`)
- Рефакторинг метаданных (переименование, удаление с cascade update в BSL+forms+metadata)
- Семантический поиск call hierarchy через BM-index EDT (не text search)
- go_to_definition + get_symbol_info (инференс типов, hover info)
- Экспорт/импорт конфигурации в XML
- Теги и группы в Navigator (хранятся в `.settings/*.yaml`, совместимо с VCS)
- User Signal Controls: прерывание MCP вызовов из status bar EDT (Cancel/Retry/Continue in Background/Ask Expert)
- Presets: Analysis Only / Code Review / Development / All Tools
- Cursor compatibility mode (plain text вместо embedded resources)
