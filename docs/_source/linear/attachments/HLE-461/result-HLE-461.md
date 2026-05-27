# HLE-461: Архитектура агента comol/ai_rules_1c

**Репо**: https://github.com/comol/ai_rules_1c (~227★)  
**Дата исследования**: 2026-05-26  
**Режим**: read-only, без запуска установщика и подключения MCP

---

## 1. Fallback-цепочка graph → code-metadata → grep

> Это центральный вопрос задачи. Выписано максимально дословно из источников.

### Официальная формулировка (tooling-playbooks.md, строка 9):
> "The MCP server catalog, fallback order (**graph → code-metadata → grep=true retry → Grep** for project-source search)..."

### Полное описание цепочки (mcp-1c-tools/SKILL.md, раздел "Project-source search before `Grep` / `rg`"):

Цепочка применяется **только** к поиску по исходникам проекта (не к внешним знаниям — платформа, БСП, ИТС).

**Шаг 1 — `1c-graph-metadata-mcp`** (граф, Neo4j/Cypher, наивысший приоритет):
- Инструменты: `search_code`, `search_metadata`, `search_metadata_by_description`, `get_object_dossier`, `trace_impact`, `trace_call_chain`
- Это основной и самый мощный уровень

**Шаг 2 — `1c-code-metadata-mcp`** (индекс кода и метаданных, FTS+semantic):
- Инструменты: `codesearch`, `metadatasearch`, `search_function`, `search_forms`, `get_module_structure` и др.
- Используется как fallback когда граф недоступен или вернул пустой/нерелевантный результат

**Шаг 3 — `1c-code-metadata-mcp` с `grep=true`** (substring retry внутри MCP-индекса):
- Применяется **только после** того как индексированный/семантический/exact search не дал достаточно
- Работает **только для** инструментов с параметром `grep`: `codesearch`, `metadatasearch`, `search_function`, `helpsearch`, `search_forms`
- Сценарии применения (дословно из docs): *exact identifier, fragment of a query, metadata path, event handler name, error text, or literal string where semantic search is likely to miss*

**Шаг 4 — `Grep`/`rg`** (прямой grep по файлам):
- Только когда все MCP-пути исчерпаны
- **Обязательная** пометка в ответе: какие MCP-попытки были и почему не помогли

### Логика переключения между уровнями (AGENTS.md):

**Когда переходить с графа на code-metadata** (дословно из AGENTS.md):
> "If `1c-graph-metadata-mcp` returns empty / non-actionable results **twice on substantially different queries** for the same target, fall back to `1c-code-metadata-mcp` (hybrid → `grep=true`) instead of further graph attempts."

**Принцип остановки** (дословно из SKILL.md):
> "Stop as soon as the collected evidence is sufficient. Before each call, check that it closes a concrete context gap and is not a duplicate of an earlier call."

**Правило no-repeat** (AGENTS.md):
> "Do not repeat the same tool request against the same unchanged state when the previous result is still available: same search, same MCP query, same validator input."

### Quick map: задача → инструмент (из mcp-1c-tools/SKILL.md)

| Задача | Граф (первый выбор) | code-metadata (fallback) |
|---|---|---|
| Поиск BSL кода | `search_code` (`fulltext`/`semantic`/`hybrid`, L0–L3) | `codesearch` |
| Структура метаобъекта | `get_object_dossier` | `get_metadata_details` |
| Impact-анализ (рекурсивный) | `trace_impact` (depth 1–10) | `graph_dependencies` (плоский) |
| Граф вызовов | `trace_call_chain` | `get_method_call_hierarchy` |
| Поиск по имени/структуре | `search_metadata` (JSON templates) | `metadatasearch` |
| Где используется объект | `find_objects_using_object` / `find_usages_of_object` | `graph_dependencies` (direction="reverse") |
| Поиск по описанию/синониму | `search_metadata_by_description` | `metadatasearch` (names_only=true) |

### Параметры детализации search_code (важно для роутинга):

| Уровень | Содержимое | Когда использовать |
|---|---|---|
| L0 | Полный код процедуры без усечения | Нужен полный код конкретной процедуры |
| L1 | Сигнатура + описание + вызываемые (default) | Стандартный поиск |
| L2 | Карточка (имя, владелец, модуль, export, директива) | Обзор списка |
| L3 | Только имя и score | Максимально широкий обзор с большим top_k |

### Как применить у нас (тема 2 — роутинг поиска):

- Граф → code-metadata → grep=true → Grep — точная схема для нашего роутинга поиска по коду
- Триггер перехода: граф вернул пусто на двух **существенно разных** запросах → переход на code-metadata
- grep=true — промежуточный уровень (НЕ сразу файловый grep), для точных идентификаторов и фрагментов
- L0/L3 детализация в search_code — управление токенами, аналог нашего "глубина ответа"
- Принцип "стоп когда достаточно" — избегаем blind chaining

---

## 2. Диспетчер MCP

### Структура (два независимых вектора):

**Вектор 1 — поиск по проекту** (описан в разделе 1):
```
graph → code-metadata → grep=true → Grep
```

**Вектор 2 — внешние знания** (нет Grep-эквивалента; вызываются только когда нужны):
```
1c-templates-mcp   → шаблоны + векторная память проекта (remember/recall)
1c-ssl-mcp         → БСП/SSL: готовые функции и паттерны
1C-docs-mcp        → справка платформы (версионная, через docinfo/docsearch)
1c-code-check-mcp  → 1С:Напарник (check, review, rewrite) + ИТС-стандарты
1c-syntax-checker  → синтаксис BSL после правок
1c-data-mcp        → выполнение в живой ИБ (нет offline-замены)
```

### Правила выбора сервера (из SKILL.md):

- Сервер считается доступным **только** если его инструменты реально экспонированы в сессии
- Наличие в mcp-servers.json ≠ доступность
- Внешние серверы вызываются **только когда нужны** (условная обязательность)
- Для BSL/метаданных — MCP обязателен при наличии сервера

### Как применить у нас (темы 2 и 5):

- Разделение на "поиск по проекту" и "внешние знания" — именно так и нужно организовать наш диспетчер
- Азимут = аналог 1c-graph-metadata-mcp (структурный граф конфигурации)
- Справочник платформы = аналог 1C-docs-mcp
- Вектор = можно встраивать в code-metadata слой или как отдельный
- Принцип наличия в сессии важен: не вызывать сервер если он не поднят

---

## 3. Структура правил агента

### Слои правил:

| Слой | Файл/место | Когда загружается | Для чего |
|---|---|---|---|
| **Always-on** | `AGENTS.md` (корень) | Всегда | Персона, процедура, MCP-дисциплина, принципы |
| **Долговременная память** | `memory.md` (корень) | Всегда | Только глобальные критичные стабильные правила |
| **Векторная память** | `1c-templates-mcp` recall | Начало нетривиальной задачи | Проектные факты, корректировки, нетривиальные решения |
| **On-demand правила** | `content/rules/*.md` | По совпадению сценария | Coding standards, forms, subagents, tooling, integrations |
| **Субагенты** | `content/agents/*.md` | По размеру/типу задачи | 13 специализированных ролей |
| **SKILL-пакеты** | `content/skills/*/SKILL.md` | По триггеру | MCP-диспетчер, управление метаданными, диаграммы и др. |
| **OpenSpec** | `openspec/` | При работе со спеками | Spec-driven development workspace |
| **Handoff** | `handoffs/handoff-<ts>.md` | По запросу пользователя | Передача контекста между сессиями |

### `memory.md` — строгие критерии:
- **Global**: относится ко всему проекту
- **Critical**: нарушение = production breakage / data leak / regulatory
- **Stable**: не меняется от задачи к задаче
- **Non-derivable**: нельзя вывести из AGENTS.md или официальной документации

*Если хотя бы один критерий не выполнен — не в memory.md, а в `remember`.*

### OpenSpec workspace:
```
openspec/
├── specs/           # текущее поведение (source of truth)
│   └── <domain>/spec.md
├── changes/         # активные предложения
│   └── <change-name>/
│       ├── proposal.md    # зачем и что меняется
│       ├── design.md      # как (технические решения)
│       ├── tasks.md       # чек-лист реализации
│       └── specs/         # дельта-спеки
└── project.md       # автогенерируемый контекст 1С-проекта
```

Команды: `/opsx:propose → /opsx:apply → /opsx:archive`

### Subagent Pipeline (full-cycle задачи):
```
Triage → Plan (1c-planner/architect) → Implement (1c-developer) 
→ Spec-compliance review (parent) → [Code review by user request] 
→ Verification gate
```

Handoff между субагентами — строгий формат с секциями: Artifacts / Public surface / Open TODOs / Locked decisions / Open questions raised.

### Что применимо к нашему поведенческому контракту (тема 5):

1. **CONFUSION-формат** для неоднозначностей (обязателен для всех субагентов)
2. **Разделение путей** по размеру задачи: quick-fix / docs-fix / spec-authoring / full-cycle
3. **Двухслойная память**: строгий long-term (memory.md) + оперативная векторная (recall)
4. **Handoff-формат** для передачи контекста между сессиями — применимо как есть
5. **OpenSpec workflow** — propose → apply → archive — готовый паттерн для spec-driven разработки
6. **Context sources block** в каждом нетривиальном артефакте — принцип прозрачности грунтования
7. **Принцип on-demand**: не грузить все правила сразу, а по триггеру сценария
8. **Языковая политика**: правила на английском (нейтральность), ответы на русском, идентификаторы как есть

---

## 4. Анти-выдумка / заземление

### Из `AGENTS.md` (Persona):
> "always verify built-in functions, methods, and metadata against documentation before using them, and search for code templates before writing"

### Из `AGENTS.md` (Spec-authoring path):
> "every metadata name, attribute, tabular section, public API signature, БСП subsystem, platform-version behaviour, or project convention referenced in the spec must be confirmed through the relevant MCP tools... before it lands in the artifact."

> "A TODO / 'to be clarified' in a spec for a fact that one MCP call could close is a defect — **close it now, do not defer.**"

### Из `AGENTS.md` (MCP A.3):
> "**Skipping a relevant source silently counts as a defect.**"

### Из `sdd-integrations.md` (запреты в OpenSpec артефактах):
> "**Do not invent attribute names** from analogous documents or from memory."

> "**Invented metadata or attribute names.** No `Документ.НачислениеЗарплаты.Реквизит` value without metadata confirmation."

> "**Platform-API signatures written from memory** when the spec is normative... cite the verified source."

> "**Cross-version assumptions without CompatibilityMode check**" — запрещено (если spec опирается на поведение 8.3.21+, проверить CompatibilityMode)

### Из `explorer.md`:
> "**Never** invent metadata names, attribute names, or function signatures. If you cannot verify it via MCP or by reading the file, mark the item as 'unverified' or omit it."

> "AI-based MCP tools (`answer_metadata_question`, `business_search` semantic mode) produce drafts — **cross-check facts against deterministic tools.**"

### `Context sources` block (обязателен в каждом нетривиальном артефакте):
```markdown
## Context sources
Verified via MCP: `Документы.НачислениеЗарплаты.Комментарий` (Строка, 1024); 
БСП `ДлительныеОперации` v3.1.10; БСП `БезопасноеХранилище` available.
```
Отсутствие этого блока = дефект, аналогичный пропущенному `syntaxcheck`.

### Применимость к нашему агенту:
- Принцип "отвечай только из источника" аналогичен: мы ссылаемся на Азимут/справочник, они — на MCP
- Явная маркировка "unverified" вместо выдумки — готовый паттерн
- Context sources block → у нас аналог "список источников" в каждом ответе с фактами
- Запрет на cross-version assumptions → у нас аналог запрета на "думать за конфигурацию"

---

## 5. Карта MCP-серверов vibecoding1c.ru

Все серверы: Docker-контейнеры, HTTP транспорт, локальные. Все опциональны (graceful fallback).

| Сервер | Порт | Область | Ключевые инструменты |
|---|---|---|---|
| **1c-graph-metadata-mcp** | 8006 | Граф объектов конфигурации (Neo4j/Cypher): связи, зависимости, impact-анализ, бизнес-поиск | `get_object_dossier`, `trace_impact` (рекурсивный, depth 1–10), `trace_call_chain`, `search_code` (fulltext/semantic/hybrid, L0–L3), `search_metadata` (JSON templates), `search_metadata_by_description`, `find_objects_using_object`, `business_search`, `answer_metadata_question` |
| **1c-code-metadata-mcp** | 8000 | Поиск кода и метаданных, навигация по модулям, формы, XSD-схемы, XML-валидация | `codesearch`, `metadatasearch` (names_only), `get_metadata_details`, `search_function` (exact+fuzzy), `get_module_structure`, `get_method_call_hierarchy`, `graph_dependencies`, `bsl_scope_members`, `search_forms`, `inspect_form_layout`, `get_xsd_schema`, `verify_xml`, `helpsearch` |
| **1c-syntax-checker-mcp** | 8002 | Синтаксис BSL через BSL Language Server | `syntaxcheck` (лимит 3 вызова на цикл) |
| **1c-templates-mcp** | 8004 | 2000+ шаблонов и паттернов 1С + векторная долговременная память проекта | `templatesearch` (hybrid: vector+fulltext), `remember` (сохранить факт), `recall` (найти по ключевым словам) |
| **1c-ssl-mcp** | 8008 | Библиотека Стандартных Подсистем (БСП/SSL) — готовые API и паттерны | `ssl_search` |
| **1C-docs-mcp** | 8003 | Справка платформы 1С, версионная (критично — поведение меняется между версиями) | `docinfo` (по точному имени), `docsearch` (по описанию) |
| **1c-code-check-mcp** | 8007 | 1С:Напарник (коммерческий сервис) + ИТС-стандарты | `check_1c_code` (синтаксис, логика, производительность), `review_1c_code` (стиль, ИТС, нейминг), `rewrite_1c_code`, `modify_1c_code`, `ask_1c_ai`, `its_help`→`fetch_its`, `search_1c_documentation`, `diff_1c_documentation_versions`, `config_help` (ERP/БП/ЗУП/УТ) |
| **1c-data-mcp** | PUBLISH_URL/hs/mcp | Выполнение в живой ИБ — HTTP-сервис публикуется самой 1С. Нужен анонимный доступ. | `vcexecutecode` (BSL-фрагмент в ИБ), `vcexecutequery` (запрос в ИБ), `validatequery` (парсинг запроса), `vcloggetlasterror` (последняя ошибка из ЖР) |

### Сравнение с нашим "зоопарком":
- У нас: Азимут ≈ их 1c-graph-metadata-mcp (структура + связи)
- У нас: справочник платформы ≈ их 1C-docs-mcp
- У них есть: вектор шаблонов (1c-templates-mcp), живое выполнение (1c-data-mcp) — у нас этого нет
- Их диспетчер чётко разделяет: search по проекту vs. внешние знания — разные цепочки

---

## 6. Лицензия и переиспользование

### Лицензия:
Из README.md (дословно):
> "Никакой лицензии, берите и используйте как хотите"

Файла LICENSE нет. Авторы явно разрешают свободное использование.

### Формат:
- **Основной формат — Markdown**: AGENTS.md, rules/*.md, agents/*.md, skills/*/SKILL.md, commands/*.md, openspec/
- **PowerShell (.ps1)**: `content/skills/1c-metadata-manage/tools/` — инструменты для работы с метаданными (CF, CFE, EPF, EPF, формы, роли, макеты, базы). Это исполняемые скрипты.
- **Python**: img-grid-analysis/scripts/overlay-grid.py, transcribe/scripts/transcribe.py
- **JavaScript/Node.js**: md-to-docx/scripts/md_to_docx.js
- **YAML**: adapters/*.yaml, openspec/config.yaml
- **JSON**: mcp-servers.json, form preset JSON

### Что переиспользуемо:
- ✅ **Fallback-цепочка** (mcp-1c-tools/SKILL.md) — прямой образец для роутинга поиска (тема 2)
- ✅ **CONFUSION-формат** (AGENTS.md) — готовый шаблон для уточнения неоднозначностей
- ✅ **Двухслойная память**: memory.md (строгие критерии) + remember/recall (оперативная) — паттерн для нашей памяти
- ✅ **Context sources block** (sdd-integrations.md) — паттерн явного заземления
- ✅ **On-demand правила** (structure) — паттерн условной загрузки правил
- ✅ **Subagent pipeline** с handoff-форматом — паттерн для многоходовых задач
- ✅ **OpenSpec workflow** (propose → apply → archive) — готовый паттерн для spec-driven разработки
- ✅ **Принцип "unverified"** вместо выдумки — прямой образец для нашего anti-hallucination
- ⚠️ Конкретные правила coding-standards, forms, etc. — переиспользуемы как идеи, но требуют адаптации под наш контекст

---

## Соответствие темам проекта

### Тема 2 (роутинг поиска по коду):
- **Прямой образец**: цепочка graph → code-metadata → grep=true → Grep
- **Триггер перехода**: пусто дважды на разных запросах → fallback
- **Детализация**: L0–L3 в search_code, управление шириной результата
- **Принцип остановки**: stop as soon as sufficient evidence

### Тема 5 (поведенческий контракт):
- **CONFUSION-формат** — обязательный для неоднозначностей
- **Двухслойная память** — строгий + оперативный слой
- **Context sources block** — прозрачность заземления
- **On-demand правила** — загружать по триггеру, не всё сразу
- **Handoff** — передача контекста между сессиями
- **Языковая политика** — правила на нейтральном языке, ответы на целевом

---

## Где не определить

- Реализация MCP-серверов (закрытые, в репо только правила их использования)
- Точная модель векторных эмбеддингов в 1c-graph-metadata-mcp и 1c-templates-mcp
- Схема Neo4j (доступна через инструмент `get_metadata_prompt`, но не в репо)
- Производительность и реальные задержки серверов
