# HLE-458: mini-ai-1c, 1c-buddy, EDT-MCP — Итоговый отчёт

**Дата:** 2026-05-26  
**Задача:** Разобрать состав MCP-серверов и инструментов трёх конкурентных/смежных проектов: hawkxtreme/mini-ai-1c, ROCTUP/1c-buddy, DitriXNew/EDT-MCP

---

## 1. hawkxtreme/mini-ai-1c (~197★) — ближайший конкурент

### Что это
Desktop-приложение (Tauri 2 + Rust + React 19) с чатом для разработки на 1С. Интегрируется с Конфигуратором через EditorBridge.exe. **Лицензия: Attribution Non-Commercial** — коммерческое использование запрещено.

### Архитектура MCP-серверов (4 штуки)

| Сервер | Стек | Инструментов | Назначение |
|--------|------|--------------|-----------|
| 1С:Справка | TypeScript | 4 | Поиск в .hbk файлах установленной 1С платформы |
| 1С:Метаданные | TypeScript | 2 (+N от kharin) | Тонкий прокси к vladimir-kharin/1c_mcp по HTTP |
| 1С:Напарник | TypeScript | 3 | Клиент code.1c.ai REST API |
| 1С:Поиск | Rust | 15 | Символьный индекс + граф вызовов (tree-sitter-bsl + SQLite) |

### Детальный состав инструментов

#### 1С:Справка (4 инструмента)
- `search_1c_help(query, category?, limit?)` — FTS5 полнотекстовый поиск
- `get_1c_help_topic(topic_id)` — полный текст топика по ID
- `list_1c_help_versions()` — статус проиндексированных версий
- `reindex_1c_help()` — принудительная переиндексация

Источник данных: `.hbk` файлы из `C:\Program Files\1cv8` (3 файла: синтаксис, запросы, язык). SQLite WAL + FTS5 `unicode61`. Путь к БД: `%APPDATA%/com.mini-ai-1c/help/help.db`.

#### 1С:Метаданные (2 инструмента в bundled 1c_mcp_ext)
- `list_metadata_objects(type?, nameMask?)` — список объектов конфигурации
- `get_metadata_structure(objectType, objectName)` — структура объекта

Работает через HTTP JSON-RPC 2.0 к HTTP-сервису 1С. Таймаут 5 секунд. Env: `ONEC_METADATA_URL`, `ONEC_USERNAME`, `ONEC_PASSWORD`. Все стандартные MCP-примитивы (tools, resources, prompts) проксируются насквозь.

#### 1С:Напарник (3 инструмента)
- `ask_1c_ai(question, programming_language?, create_new_session?)` — вопрос ИИ-консультанту по 1С
- `explain_1c_syntax(syntax_element, context?)` — синтаксис метода/объекта
- `check_1c_code(code, check_type: syntax|logic|performance)` — проверка кода

SSE streaming (eventsource-parser). Session management: max 10 сессий, TTL 1 час. Tool call round-trip: при получении tool_calls от code.1c.ai отправляет `"rejected"` (не выполняет локально). Retry 3 попытки с exponential backoff от 1000ms.

#### 1С:Поиск по конфигурации (15 инструментов)
| Инструмент | Описание |
|-----------|---------|
| `search_code` | Полнотекстовый grep (regex, scope) |
| `get_file_context` | Код вокруг строки ±40 |
| `find_symbol` | Exact/prefix поиск в символьном индексе |
| `get_symbol_context` | Полный код функции по ID |
| `smart_find` | Symbol + code в одном вызове |
| `find_function_in_object` | Функция в конкретном объекте 1С |
| `get_module_functions` | Все процедуры/функции модуля |
| `list_objects` | Объекты конфигурации (по типу/имени) |
| `get_object_structure` | Реквизиты, ТЧ, формы, команды, модули |
| `find_references` | Все вхождения символа |
| `impact_analysis` | Какие модули используют символ/объект |
| `get_function_context` | Граф вызовов: что вызывает + что вызывается |
| `stats` | Статистика индекса |
| `benchmark` | Бенчмарк производительности |
| `sync_index` | Перестройка индекса |

**Производительность на ERP 10.8GB / 123k файлов / 642k символов:**
- `find_symbol`: 1ms
- `search_code`: 77ms

Стек: Rust + rusqlite bundled + tree-sitter-bsl + Rayon + Tokio. WAL mode, параллельная индексация.

### Slash-команды (11 штук)
`/исправить`, `/доработай`, `/рефакторинг`, `/описание`, `/объясни`, `/ревью`, `/стандарты`, `/итс` (→ ask_1c_ai), `/найти` (→ find_symbol/search_code), `/где` (→ find_references), `/объект` (→ get_object_structure)

### Интеграция с Конфигуратором
- `.NET` EditorBridge.exe
- Named Pipe `\\.\pipe\mini-ai-editor-bridge-<USERNAME>`
- UIAutomation для определения фокусированного редактора
- **Ввод текста через WM_CHAR** (ключевой момент: обходит keyboard hooks 1С, которые блокируют стандартный SendKeys)
- Windows only, НЕ использует clipboard

### Поддержка внешних MCP
Полная: `McpServerConfig.transport: 'http' | 'stdio' | 'internal'`. Из UI можно добавлять произвольные MCP серверы.

### Context compression
Три стратегии: disabled | sliding_window | summarize. Автоматический порог: 75% контекста модели.

---

## 2. ROCTUP/1c-buddy

### Что это
Python app: веб-чат + MCP сервер + OpenAI-совместимый API шлюз. НЕ desktop-приложение — разворачивается через Docker. Наследник artesk/1copilot_MCP.

### 8 инструментов

| Инструмент | Описание |
|-----------|---------|
| `ask_1c_ai` | Общие вопросы по платформе 1С |
| `explain_1c_syntax` | Объяснение метода/объекта |
| `check_1c_code` | Синтаксическая проверка / code review |
| `modify_1c_code` | Изменение кода по заданию |
| `search_1c_documentation` | Поиск по документации платформы |
| `search_its` | Поиск по базе знаний ИТС |
| `fetch_its` | Получение документа ИТС по id |
| `diff_1c_documentation_versions` | Сравнение документации двух версий |

Streamable HTTP транспорт (`http://localhost:6002/mcp`). OpenAI-совместимый API `/v1/chat/completions`. Поддержка внешних HTTP MCP серверов из UI чата.

**Уникальные инструменты по сравнению с mini-ai-1c:** `modify_1c_code`, `search_1c_documentation`, `search_its`, `fetch_its`, `diff_1c_documentation_versions`.

---

## 3. DitriXNew/EDT-MCP

### Что это
Eclipse/EDT плагин (Java). Встраивается в 1C:EDT 2025.2+. **Лицензия: GNU AGPL v3.0.** Streamable HTTP + SSE на порту 8765.

### 56 инструментов в 9 группах

| Группа | Инструментов | Ключевые |
|--------|--------------|---------|
| Core/Project | 8 | list_projects, get_configuration_properties, clean_project, export/import_configuration_to_xml |
| Errors & Problems | 4 | get_project_errors, get_problem_summary, get_bookmarks, get_tasks |
| Code Intelligence | 7 | get_content_assist, get_platform_documentation, get_metadata_objects, get_metadata_details, list_subsystems, get_subsystem_content, find_references |
| Tags | 2 | get_tags, get_objects_by_tags |
| Apps & Testing | 5 | get_applications, list_configurations, update_database, debug_launch, run_yaxunit_tests |
| **Debugging** | **12** | set_breakpoint, wait_for_break, get_variables, evaluate_expression, step, resume, start_profiling, get_profiling_results, debug_yaxunit_tests... |
| BSL Code | 12 | read/write_module_source, get_module_structure, list_modules, search_in_code, go_to_definition, get_symbol_info, get_form_screenshot, validate_query... |
| Refactoring | 3 | rename_metadata_object, delete_metadata_object, add_metadata_attribute |
| Translation | 3 | generate_translation_strings, translate_configuration, get_translation_project_info |

### Уникальные возможности EDT-MCP
- **Полный LLM debug цикл:** set_breakpoint → debug_yaxunit_tests → wait_for_break → get_variables / evaluate_expression → step → resume — полностью автономно без GUI
- **Server-side отладка** через Attach (rphost, HTTP services, scheduled jobs, background jobs)
- **Профилирование:** замер производительности прямо из MCP
- **Снимок формы** в PNG + YAML layout (требует JVM флаг, но работает из MCP)
- **Семантическое** find_references и get_method_call_hierarchy (через BM-index EDT, не grep)
- **Рефакторинг** с cascade update (rename → все BSL + формы + метаданные)
- **Экспорт/импорт** конфигурации в XML
- **Перевод** конфигурации через LanguageTool
- **Validate query** — синтаксис + семантика запроса 1С в контексте проекта
- **User Signal Controls** — прерывание MCP вызовов из статус бара EDT
- **Presets:** Analysis Only / Code Review / Development / All Tools

---

## Сравнительная таблица: нарезка функциональности

| Функция | mini-ai-1c | 1c-buddy | EDT-MCP | Азимут |
|---------|-----------|---------|--------|--------|
| Поиск по коду (grep/FTS) | ✅ mcp-1c-search | ❌ | ✅ search_in_code | ✅ нужен |
| Символьный индекс | ✅ 642k символов, 1ms | ❌ | ✅ go_to_definition | ✅ нужен |
| Граф вызовов | ✅ caller/callee | ❌ | ✅ get_method_call_hierarchy | ✅ нужен |
| Структура метаданных | ✅ 2 инстр. | ❌ | ✅ 5 инстр. | частично |
| Справка платформы | ✅ .hbk FTS | ❌ | ✅ get_platform_documentation | ❌ |
| ИТС / Напарник | ✅ 3 инстр. | ✅ 8 инстр. | ❌ | ❌ |
| Дебаггинг 1С | ❌ | ❌ | ✅ 12 инстр. | ❌ |
| Рефакторинг метаданных | ❌ | ❌ | ✅ 3 инстр. | ❌ |
| Интеграция с редактором | ✅ EditorBridge WM_CHAR | ❌ | ✅ write_module_source | ? |
| Скриншот форм | ❌ | ❌ | ✅ PNG + YAML | ❌ |
| Проверка BSL синтаксиса | ✅ через BSL LS | ❌ | ✅ validate_query | нужен |

---

## Выводы для Азимута

### Что взять в первую очередь

**1. mcp-1c-search как образец (НЕ как код)**
Принципы нарезки инструментов в 1С:Поиск — отличный ориентир для Азимута:
- Разделение: find_symbol (индекс, 1ms) vs search_code (grep, 77ms) — разные сценарии использования
- impact_analysis и get_function_context как отдельные инструменты поверх того же индекса
- get_object_structure — одна точка входа для полной структуры объекта

**2. Разделение ролей серверов (мощный паттерн)**
mini-ai-1c показывает чистую нарезку: каждый сервер отвечает за одну область. Азимуту рекомендуется аналогичная модель: отдельный сервер per домен.

**3. WM_CHAR для Конфигуратора**
Критичная находка: EditorBridge использует WM_CHAR вместо keyboard simulation — это обходит внутренние keyboard hooks 1С. Для Азимута это единственный надёжный способ вставки текста в Конфигуратор.

**4. Из 1c-buddy: search_its / fetch_its / diff_1c_documentation_versions**
1c-buddy имеет доступ к ИТС через API code.1c.ai. Инструмент `diff_1c_documentation_versions` уникален — позволяет моделям сравнивать документацию платформы между версиями.

**5. EDT-MCP: validate_query и get_content_assist**
Валидация 1С-запросов (синтаксис + семантика) — это capability, которую сложно реализовать без EDT. Для Азимута если EDT-интеграция нужна — EDT-MCP готовый вариант (AGPL, работает как HTTP сервер).

### Что НЕ брать

- **Дебаггинг** (EDT-MCP, 12 инструментов) — требует EDT, сложная интеграция. Не приоритет для Азимута.
- **mcp-1c-search код** — Rust, bundled rusqlite, tree-sitter-bsl. Азимут на Python, переписывать нет смысла.
- **Код mini-ai-1c** — Attribution Non-Commercial License, коммерческое использование запрещено.

### Кандидаты на интеграцию рядом с Азимутом

| Сервер | Кандидат? | Комментарий |
|--------|-----------|-------------|
| EDT-MCP | ✅ внешний MCP | AGPL, запускается как HTTP сервер, подключается к Азимуту через mcpServers. Для пользователей EDT. |
| 1c-buddy MCP | ✅ внешний MCP | Streamable HTTP, 8 инструментов по ИТС и документации. Docker. |
| mini-ai-1c 1С:Поиск | ❌ лицензия | Non-Commercial, код нельзя использовать. |
| mini-ai-1c 1С:Справка | ❌ лицензия | Non-Commercial. Но подход (FTS5 по .hbk) можно реализовать самостоятельно. |

### Паттерн интеграции с Конфигуратором (финальный вывод)
1. Named Pipe + UIAutomation для определения активного редактора — доказанный подход
2. WM_CHAR для вставки — единственный надёжный метод (EditorBridge.exe)
3. Для чтения кода — UIAutomation + Ctrl+A + Ctrl+C в Конфигураторе (или через BSP 1С API если есть HTTP-сервис)
