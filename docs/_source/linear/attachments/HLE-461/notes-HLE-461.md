# Заметки по HLE-461: comol/ai_rules_1c

## Репо: https://github.com/comol/ai_rules_1c
## Дата: 2026-05-26
## ~227 звёзд, портативные правила для ИИ-агентов разработки на 1С (BSL)

---

## Структура репо

```
AGENTS.md                    # always-on контекст (персона, процедура, MCP-дисциплина)
USER-RULES.md                # пользовательские правила (пустой по умолчанию)
memory.md                    # строгая долговременная память (только глобальные критичные правила)
install.ps1                  # PowerShell установщик
.dev.env.example             # параметры проекта
adapters/                    # адаптеры под инструменты (cursor, claude-code, codex, opencode, kilocode)
content/
  rules/                     # on-demand правила (загружаются по задаче)
  agents/                    # 13 специализированных субагентов
  commands/                  # слэш-команды
  skills/                    # SKILL-пакеты
    mcp-1c-tools/SKILL.md    # <-- ГЛАВНЫЙ файл: диспетчер MCP
    mcp-1c-tools/docs/       # per-server документация
    1c-metadata-manage/      # управление метаданными
    caveman/                 # стиль общения
    handoff/                 # передача контекста
  openspec-bundle/           # снапшоты OpenSpec для каждого инструмента
  mcp-servers.json           # каталог MCP-серверов
openspec/                    # OpenSpec-воркспейс (specs/, changes/, project.md)
```

---

## НАХОДКИ: fallback-цепочка (ГЛАВНОЕ)

### Источник: `content/skills/mcp-1c-tools/SKILL.md` + `AGENTS.md`

#### Полная цепочка (4 шага, только для поиска по проекту):

**Шаг 1: `1c-graph-metadata-mcp`** (высший приоритет)
- Инструменты: `search_code`, `search_metadata`, `search_metadata_by_description`, `get_object_dossier`, `trace_impact`, `trace_call_chain`
- Это граф (Neo4j/Cypher), самый мощный

**Шаг 2: `1c-code-metadata-mcp`** (fallback когда граф недоступен или вернул пусто)
- Инструменты: `codesearch`, `metadatasearch`, `search_function`, `search_forms`, `get_module_structure`, etc.
- Семантический + FTS индекс

**Шаг 3: `1c-code-metadata-mcp` с `grep=true`** (substring retry внутри MCP-индекса)
- Применяется ТОЛЬКО ПОСЛЕ индексированный/семантический/exact search не нашёл достаточно
- Работает только для инструментов с параметром `grep`: `codesearch`, `metadatasearch`, `search_function`, `helpsearch`, `search_forms`
- Сценарии: точный идентификатор, фрагмент запроса, путь метаданных, имя обработчика события, текст ошибки, строковый литерал

**Шаг 4: `Grep`/`rg`** (только в самом конце)
- ОБЯЗАТЕЛЬНАЯ пометка в ответе: какие MCP-попытки были и почему не помогли

#### Триггер перехода с шага 1 на шаг 2 (из AGENTS.md):
> "If `1c-graph-metadata-mcp` returns empty / non-actionable results **twice on substantially different queries** for the same target, fall back to `1c-code-metadata-mcp` (hybrid → `grep=true`) instead of further graph attempts."

#### Правило "стоп когда достаточно":
> "Stop as soon as the collected evidence is sufficient. Before each call, check that it closes a concrete context gap and is not a duplicate of an earlier call."

---

## НАХОДКИ: диспетчер MCP

### Quick map (из `mcp-1c-tools/SKILL.md`):

| Задача | Первый выбор (граф) | Fallback (code-metadata) |
|---|---|---|
| Поиск BSL кода | `search_code` | `codesearch` |
| Структура метаобъекта | `get_object_dossier` | `get_metadata_details` |
| Impact-анализ | `trace_impact` | `graph_dependencies` |
| Граф вызовов | `trace_call_chain` | `get_method_call_hierarchy` |
| Поиск по имени/структуре | `search_metadata` (JSON templates) | `metadatasearch` |
| Где используется объект | `find_objects_using_object`/`find_usages_of_object` | `graph_dependencies` (direction="reverse") |
| Поиск по описанию/синониму | `search_metadata_by_description` | `metadatasearch` (names_only=true) |

### Отдельная ветвь: внешние знания (без Grep-эквивалента):
1. `1c-templates-mcp` — шаблоны + векторная память (remember/recall)
2. `1c-ssl-mcp` — БСП/SSL API
3. `1C-docs-mcp` — справка платформы (версионная!)
4. `1c-code-check-mcp` — 1С:Напарник + ИТС
5. `1c-syntax-checker-mcp` — синтаксис BSL после правок
6. `1c-data-mcp` — выполнение в живой ИБ (нет offline-замены)

**Важно**: сервер считается доступным ТОЛЬКО если его инструменты реально экспонированы в сессии (наличие в mcp-servers.json не считается).

---

## НАХОДКИ: структура правил агента

### AGENTS.md (always-on)
- Персона: опытный 1С разработчик (senior, 10+ лет), осторожный с документацией
- Процедура: Triage → Think → Simplify → Surgical → Verify → Deliver
- 4 пути: quick-fix / docs-fix / spec-authoring / full-cycle
- MCP-дисциплина (разделы A, B, C)
- Coding standards, Skills & Subagents, Additional rules

### memory.md (строгий долговременный слой)
- Только правила с признаками: global + critical + stable + non-derivable
- НЕ хранить: TODO, временные договорённости, стилевые заметки
- Пустой по умолчанию в поставке

### `1c-templates-mcp` remember/recall (векторная память)
- Первичный слой для проектных фактов, корректировок, нетривиальных решений
- Одна самодостаточная заметка на запись, на английском, с оригинальными 1С-идентификаторами

### On-demand правила (`content/rules/`)
- Frontmatter: `alwaysApply: false`, `category: <...>`
- Загружаются только при совпадении сценария задачи
- Важные для нас: tooling-playbooks.md, subagents.md, subagent-pipeline.md, sdd-integrations.md

### openspec/ workspace
- specs/ — текущее поведение (source of truth)
- changes/<id>/ — активные предложения (proposal.md + design.md + tasks.md + delta specs/)
- project.md — автогенерируемый контекст 1С проекта (из Configuration.xml)
- Слэш-команды: /opsx:propose, /opsx:apply, /opsx:archive, /opsx:explore

### content/agents/ — 13 субагентов
explorer, analytic, planner, architect, arch-reviewer, developer, metadata-manager, refactoring, performance-optimizer, error-fixer, tester, code-reviewer, doc-writer

### content/skills/ — SKILL-пакеты
Ключевой: mcp-1c-tools (диспетчер)
Другие: 1c-metadata-manage, caveman, handoff, mermaid-diagrams, powershell-windows, md-to-docx, prompt-enhancer, transcribe

### Handoff-документы
- `handoffs/handoff-<timestamp>.md` в корне проекта
- Ссылается на durable-артефакты (openspec/, memory.md, коммиты), не дублирует
- Содержит: Current State, Open Questions, Files Changed, Verification State, Next Steps, What To Load Next Session

### Subagent Pipeline (full-cycle)
Triage → Plan (1c-planner/architect) → Implement (1c-developer/metadata-manager) → Spec-compliance review (parent) → [Code-quality review (user-triggered)] → Verification gate

Handoff-формат между субагентами с секциями: Artifacts, Public surface, Open TODOs, Locked decisions, Open questions raised

---

## НАХОДКИ: anti-выдумка / заземление

### Из AGENTS.md (Persona):
> "always verify built-in functions, methods, and metadata against documentation before using them, and search for code templates before writing"

### Из AGENTS.md (Spec-authoring path):
> "every metadata name, attribute, tabular section, public API signature, БСП subsystem, platform-version behaviour, or project convention referenced in the spec must be confirmed through the relevant MCP tools... before it lands in the artifact. A TODO / 'to be clarified' in a spec for a fact that one MCP call could close is a defect — close it now, do not defer."

### Из AGENTS.md (MCP A.3):
> "Skipping a relevant source silently counts as a defect."

### Из AGENTS.md (CONFUSION format):
> "Silently picking one interpretation without using the format is forbidden."
(обязателен для субагентов тоже)

### Из sdd-integrations.md (OpenSpec spec authoring):
> "Do not invent attribute names from analogous documents or from memory."
> "Invented metadata or attribute names. No `Документ.Xyz.Реквизит` value without metadata confirmation."
> "Platform-API signatures written from memory when the spec is normative... cite the verified source."
> "Cross-version assumptions without CompatibilityMode check" — запрещено

### Из explorer.md:
> "Never invent metadata names, attribute names, or function signatures. If you cannot verify it via MCP or by reading the file, mark the item as 'unverified' or omit it."
> "AI-based MCP tools (answer_metadata_question, business_search semantic mode) produce drafts — cross-check facts against deterministic tools."

### Context sources block (sdd-integrations.md):
В каждом нетривиальном OpenSpec-артефакте обязателен блок `## Context sources` — что проверено через MCP. Отсутствие = дефект.

---

## НАХОДКИ: карта MCP-серверов vibecoding1c.ru

### Из mcp-servers.json + SKILL docs:

| Сервер | Порт | Назначение | Ключевые инструменты |
|---|---|---|---|
| `1c-graph-metadata-mcp` | 8006 | Граф метаданных (Neo4j/Cypher) — структурный паспорт, impact-анализ, граф вызовов, бизнес-поиск | get_object_dossier, trace_impact, trace_call_chain, search_code (fulltext/semantic/hybrid, L0-L3), search_metadata (JSON templates), search_metadata_by_description |
| `1c-code-metadata-mcp` | 8000 | Поиск кода и метаданных, навигация по модулям, формы, XSD, валидация | codesearch, metadatasearch, search_function, get_module_structure, get_method_call_hierarchy, graph_dependencies, inspect_form_layout, get_xsd_schema, verify_xml |
| `1c-syntax-checker-mcp` | 8002 | Синтаксис BSL через BSL Language Server | syntaxcheck |
| `1c-templates-mcp` | 8004 | Библиотека 2000+ шаблонов + векторная память проекта | templatesearch, remember, recall |
| `1c-ssl-mcp` | 8008 | Библиотека Стандартных Подсистем (БСП/SSL) | ssl_search |
| `1C-docs-mcp` | 8003 | Справка платформы 1С (версионная) | docinfo, docsearch |
| `1c-code-check-mcp` | 8007 | 1С:Напарник (коммерческий) + ИТС-стандарты | check_1c_code, review_1c_code, rewrite_1c_code, modify_1c_code, ask_1c_ai, its_help→fetch_its, search_1c_documentation, diff_1c_documentation_versions |
| `1c-data-mcp` | {PUBLISH_URL}/hs/mcp | Выполнение в живой ИБ (HTTP-сервис в 1С) | vcexecutecode, vcexecutequery, validatequery, vcloggetlasterror |

**Все серверы**: Docker-контейнеры, HTTP транспорт, локальные. Все опциональны (graceful fallback).
**Важная деталь 1c-data-mcp**: URL автодетектится из `.dev.env` → `INFOBASE_PUBLISH_URL`. Нужен анонимный доступ (иначе 401/403).

---

## НАХОДКИ: лицензия и формат

### Лицензия (из README.md):
> "Никакой лицензии, берите и используйте как хотите"

Нет файла LICENSE. Это не ошибка — авторы явно написали в README.

### Формат:
- **В основном Markdown** (AGENTS.md, rules/*.md, agents/*.md, skills/*/SKILL.md, commands/*.md, openspec/)
- **PowerShell скрипты** (.ps1) в `content/skills/1c-metadata-manage/tools/` — инструменты для работы с метаданными 1С
- **Python и JS**: `img-grid-analysis/scripts/overlay-grid.py`, `md-to-docx/scripts/md_to_docx.js`, `transcribe/scripts/transcribe.py`
- YAML: `adapters/*.yaml` — адаптеры под инструменты
- JSON: `content/mcp-servers.json`, `openspec/config.yaml`

---

## ДОПОЛНИТЕЛЬНЫЕ НАБЛЮДЕНИЯ

1. **Языковая политика**: правила пишутся на английском (для нейтральности), ответы агента — на русском, BSL-код — на русском.

2. **Важная ссылка**: в `tooling-playbooks.md` сказано:
   > "The MCP server catalog, fallback order (graph → code-metadata → grep=true retry → Grep for project-source search)..."
   Т.е. официальная формулировка цепочки именно такая: `graph → code-metadata → grep=true retry → Grep`

3. **detail_level у search_code** (1c-graph-metadata-mcp):
   - L0 — полный код процедуры (без усечения)
   - L1 — сигнатура + описание + вызываемые (default)
   - L2 — карточка (имя, владелец, модуль, export, директива)
   - L3 — только имя и score (минимум токенов)
   Наш роутинг может учитывать это: для обзора → L3 с высоким top_k, для полного кода → L0.

4. **search_code поддерживает типы**: `fulltext` (Lucene), `semantic` (по смыслу), `hybrid` (оба, default)
   Т.е. сначала hybrid, если мало результатов — fallback на другой тип или code-metadata.

5. **grep=true работает только для**: codesearch, metadatasearch, search_function, helpsearch, search_forms. НЕ для graph-сервера.

6. **Дисциплина вызовов (AGENTS.md, раздел C)**:
   - "No-change repeats are forbidden" — нельзя повторять тот же запрос с теми же параметрами
   - "Every call must add information that is not already available"

7. **Лимиты валидации**:
   - syntaxcheck: до 3 вызовов на цикл (одна логическая правка)
   - check_1c_code: до 3 вызовов на цикл
   - review_1c_code: до 3 вызовов на цикл
   - Повтор только при "substantive defect" (логика, метаданные, транзакции, безопасность, производительность)

8. **Caveman skill** — режим краткого общения для разработческих задач. Включён для implementation/debug/deploy; ВЫКЛЮЧЕН для analysis/review/audit/documentation.

9. **Subagent explorer** (explorer.md) явно прописывает строгую fallback цепочку как обязательную с уровнями thoroughness (quick 1-3 calls, medium 4-10, thorough 10-25).

---

## ЧТО НЕ ОПРЕДЕЛИТЬ

- Точная реализация MCP-серверов (они закрытые, на vibecoding1c.ru); в репо только правила их использования
- Версия Neo4j, векторная модель (не раскрываются в правилах)
- Как именно устроена индексация в 1c-code-metadata-mcp (не в репо)
