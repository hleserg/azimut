# HLE-459: Глубокий разбор графовых аналогов — 1c-mcp-metacode (Neo4j) + bsl-graph (NebulaGraph)

Дата: 2026-05-26  
Статус: DoD выполнен

---

## РЕПО 1: ROCTUP/1c-mcp-metacode (Neo4j, Python)

### 1. Полная модель графа

**Источник данных:** только README.md и MCP_SERVER_CAPABILITIES.md — исходный код ЗАКРЫТЫЙ (Docker image `roctup/1c-mcp-metacode`, LICENSE-файл в репо отсутствует).

**Узлы (~25 типов):** задокументированы в Mermaid-диаграмме README.md

| Узел | Семантика |
|------|-----------|
| Project | Верхний уровень (мультипроектность) |
| Configuration | Конфигурация 1С |
| MetadataCategory | Категория (Справочники / Документы / …) |
| MetadataObject | Конкретный объект метаданных |
| Module | Модуль (объектный / менеджера / формы / общий) |
| **Routine** | **Процедура / функция** |
| Form | Форма объекта |
| FormControl | Элемент управления формы |
| FormEvent | Событие формы или элемента |
| FormAttribute | Атрибут формы |
| Attribute | Реквизит объекта |
| TabularPart | Табличная часть |
| Resource | Ресурс регистра |
| Dimension | Измерение регистра |
| Command | Команда |
| UrlTemplate | Шаблон URL HTTP-сервиса |
| UrlMethod | Метод HTTP-сервиса |
| EventSubscription | Подписка на событие |
| PredefinedItem | Предопределённый элемент |
| Layout | Макет |
| Characteristic | Характеристика |
| EnumValue | Значение перечисления |
| JournalGraph | Граф журнала документов |
| AccountingFlag | Признак учёта |
| DimensionAccountingFlag | Признак учёта субконто |

**Рёбра (~35+ типов):** все задокументированы в README.md (Mermaid-диаграмма)

Ключевые для Азимута:
- `Module →[DECLARES]→ Routine` — процедура принадлежит модулю
- `Routine →[CALLS]→ Routine` — **граф вызовов** (главное!)
- `MetadataObject →[HAS_MODULE]→ Module` — модуль привязан к объекту
- `EventSubscription →[HAS_HANDLER]→ Routine` — подписка → обработчик
- `FormEvent →[HAS_HANDLER]→ Routine` — событие формы → обработчик
- `Command →[HAS_HANDLER]→ Routine` — команда → обработчик
- `UrlMethod →[HAS_HANDLER]→ Routine` — HTTP метод → обработчик

**Свойства узлов/рёбер:** не определить из документации (закрытый код).

**Связь кода с метаданными:** `MetadataObject →[HAS_MODULE]→ Module →[DECLARES]→ Routine`. Routine квалифицирован до конкретного Module (который в свою очередь привязан к MetadataObject) — это подтверждается MCP_SERVER_CAPABILITIES.md: "кто вызывает процедуру X **модуля объекта Y**".

### 2. Резолв имён вызовов

**Частично решён, детали неизвестны (закрытый код).**

Что видно из MCP_SERVER_CAPABILITIES.md:
- Ребро `Routine →[CALLS]→ Routine` — существует как объект графа (не строковый callee)
- Шаблон `resolve_qn` — резолв квалифицированного имени → узел графа (явное разрешение)
- Шаблон `find_routines_by_name` — поиск процедур по имени (возможно, возвращает несколько при совпадении имён)
- MCP пример: "Кто вызывает процедуру ПередЗаписью модуля объекта документа Счёт?" — вопрос с уточнением модуля говорит о полной квалификации Routine через Module через MetadataObject

**Что точно есть:**  
- Routine → Module → MetadataObject — иерархия подтверждена
- `call_graph_subtree` поддерживает N уровней

**Что не определить:**  
- Хранится ли callee в `CALLS` ребре как resolved ссылка на конкретный Routine-узел или как строковое имя + post-resolution
- Алгоритм различения одноимённых процедур (например, `Записать` в 100 модулях)
- Как обрабатываются косвенные вызовы и вызовы через переменные

### 3. Обход графа вглубь

Из MCP_SERVER_CAPABILITIES.md:
- `call_graph_subtree` — обход на N уровней вглубь по цепочке CALLS
- `list_callees_of_routine` / `list_callers_of_routine` — прямые соседи (1 уровень)
- Примеры с явной глубиной: "Кого вызывает процедура X (глубина 2)?"
- Конкретные Cypher-запросы — **не определить** (закрытый код)

### 4. Подписки на события

**Реализованы полностью.**  
README.md: "Загрузка подписок на события и привязка к обработчикам" (LOAD_EVENT_SUBSCRIPTIONS=true, v1.1.0 добавлено 2025-10-07).  
Рёбра: `EventSubscription →[HAS_HANDLER]→ Routine`  
MCP: `list_event_subscriptions_of_object`, `get_event_subscription_sources` — получение источников и обработчиков подписок.  
Это кросс-объектная связь: обработчик находится в одном модуле, подписка объявлена на объект другого типа.

### 5. Парсинг и извлечение

Источники (из README.md + .env.example):
- `./data/metadata/*.txt` — Отчёт по конфигурации из Конфигуратора (LOAD_BSL_SIGNATURES=true — BSL-сигнатуры)
- `./data/code/**/*.bsl` — BSL-файлы (процедуры, функции, тела)
- `./data/code/**/Form.xml` — XML-описания форм (LOAD_FORMS_FROM_XML=true)
- `./data/code/**/EventSubscriptions/*.xml` — XML подписок (LOAD_EVENT_SUBSCRIPTIONS=true)
- `./data/code/**/Roles/*/Ext/Rights.xml` — права ролей
- `./data/code/**/Help/ru.html` — справка объектов
- `./data/code/**/Form.bin` — модули обычных форм (v1.3.0, добавлено 2025-10-29)

Язык: Python (закрытый). LLM в построении графа: **не участвует** (режим TEMPLATE_MODE_ONLY=true по умолчанию). LLM используется опционально только для преобразования natural-language запросов в Cypher (TEMPLATE_MODE_ONLY=false).

### 6. Хранилище

Neo4j (порты 7474/7687). Причина выбора — не документирована.  
Возможности: полнотекстовые индексы (по описаниям), векторные индексы (embeddings, опционально), Cypher-запросы с переменной глубиной. Cypher-обходы типа `MATCH p=(a)-[*1..N]->(b)` нативно поддерживаются. Конфигурация: heap 4096m, timeout 300s.

### 7. Лицензия и язык

- **Лицензия:** ОТСУТСТВУЕТ в репо. Код закрытый — только Docker image.
- **Язык:** Python (закрытый), Docker image `roctup/1c-mcp-metacode`
- **Переиспользуемость схемы:** ВЫСОКАЯ (схема задокументирована в README), переиспользуемость кода: НУЛЕВАЯ (закрытый)

---

## РЕПО 2: alkoleft/bsl-graph (NebulaGraph, Kotlin)

### 1. Полная модель графа

**Источник:** полный исходный код (MIT).

**Единый тег вершин:** `MDObject` (SchemaInitializer.kt:54)  
Все объекты хранятся под одним тегом, тип закодирован в свойстве `type`.

**Свойства каждого узла:** (QueryMapper.kt:24-26)
- `uid`: UUID объекта (например, `8f1c2d34-5678-4abc-9def-0123456789ab`)
- `name`: техническое имя (например, `Контрагенты`)
- `synonym`: синоним/русское название
- `type`: строка NodeType.name() (например, `CATALOG`)

**ID узла в NebulaGraph:** UUID без дефисов (32 символа) — `nodeId(uuid)` в Mapper.kt:15

**NodeType enum (MDObjectNode.kt:26-106) — ~75 типов:**  
Метаданные-объекты: `CATALOG`, `DOCUMENT`, `ENUM`, `CONSTANT`, `COMMON_MODULE`, `INFORMATION_REGISTER`, `ACCUMULATION_REGISTER`, `ACCOUNTING_REGISTER`, `CALCULATION_REGISTER`, `REPORT`, `DATA_PROCESSOR`, `CHART_OF_ACCOUNTS`, `CHART_OF_CHARACTERISTIC_TYPES`, `EXCHANGE_PLAN`, `BUSINESS_PROCESS`, `TASK`, `DOCUMENT_JOURNAL`, `ROLE`, `SUBSYSTEM`, `HTTP_SERVICE`, `WEB_SERVICE`, `SCHEDULED_JOB`, `EVENT_SUBSCRIPTION`, `FUNCTIONAL_OPTION`, `COMMON_ATTRIBUTE`, `COMMON_COMMAND`, `COMMON_FORM`, `SEQUENCE` и др.  
Детальные типы: `ATTRIBUTE`, `DIMENSION`, `RESOURCE`, `FORM`, `COMMAND`, `TABULAR_SECTION`, `ENUM_VALUE`, `ACCOUNTING_FLAG`, `EXT_DIMENSION_ACCOUNTING_FLAG` и др.  
Нет: `MODULE`, `ROUTINE` — процедуры/функции не представлены.

**EdgeType (MDObjectNode.kt:173-179) — 5 типов:**

| Ребро | Свойства | Семантика | Кто строит |
|-------|----------|-----------|------------|
| `CONTAINS` | нет | containment: подсистема→объект, функц.опция→объект, план обмена→объект, подписка→источник | MetadataExporter.kt:92-113 |
| `CHILDREN` | нет | иерархия подсистем: подсистема→подподсистема | MetadataExporter.kt:139-143 |
| `RELATED_TO` | нет | общая связь (fallback) | не строится напрямую |
| `ATTRIBUTE` | `name: string` (имя реквизита) | объект A имеет реквизит типа объект B | MetadataExporter.kt:158-181 |
| `ACCESS` | `name: string` (список прав через запятую) | роль → объект (с указанием разрешённых прав) | MetadataExporter.kt:193-204 |

**⚠️ КРИТИЧНО: граф вызовов BSL НЕ РЕАЛИЗОВАН.** Нет ни Routine-узлов, ни CALLS-рёбер. Это запланировано как "Этап 1" в roadmap (README.md:73-83), но в коде отсутствует.

### 2. Резолв имён вызовов

**НЕ РЕАЛИЗОВАН.**

Однако в коде есть детерминированный резолв для ATTRIBUTE-рёбер (MetadataExporter.kt:183-191):
```kotlin
fun ValueTypeDescription.MDObjects(configuration: Configuration) =
    types.filterIsInstance<MetadataValueType>()
        .mapNotNull { it.findMD(configuration) }

fun MetadataValueType.findMD(configuration: Configuration): MD? {
    val chunks = name.split(".")
    return configuration.findChild(MdoReference.create("${kind.getName()}.${chunks[1]}")).getOrNull()
}
```
Это резолв типов реквизитов: "в реквизите Контрагент справочника ПокупкиПродажи тип = Справочник.Контрагенты" → ребро ATTRIBUTE из ПокупкиПродажи в Контрагенты. Механизм deterministic (через bsl-mdclasses API `configuration.findChild(MdoReference)`).

Применительно к процедурам: проблема одноимённых процедур (`Записать` в 100 модулях) — **не решена и не начата**.

### 3. Обход графа вглубь

Реальные nGQL запросы из кода (NebulaRepository.kt):

```nGQL
-- Поиск по типу (NebulaRepository.kt:79)
MATCH (n:MDObject) WHERE n.type == "CATALOG" RETURN n

-- Обход глубины 1 (NebulaRepository.kt:439-442)
MATCH (related)-[ref]-(start)
WHERE id(start) == "8f1c2d345678..."
RETURN DISTINCT related, ref

-- Обход глубины N (NebulaRepository.kt:447-452)
MATCH (start)
WHERE id(start) == "8f1c2d345678..."
WITH start
MATCH p = (start)-[*1..3]-(related)
WHERE related <> start
RETURN DISTINCT related

-- Рёбра между найденными узлами (NebulaRepository.kt:378-385)
MATCH (n)-[e:CONTAINS|CHILDREN]->(m)
WHERE id(n) IN ['id1','id2'] AND id(m) IN ['id1','id2']
RETURN e
```

REST API: `GET /api/graph/related/{id}?depth=N` (GraphRestController.kt:51-58)  
Защита от циклов: только `DISTINCT` в nGQL. Нет явных стоп-листов. Глубина лимитирована параметром.

### 4. Подписки на события

MetadataExporter.kt:109-113:
```kotlin
configuration.eventSubscriptions.forEach { subscription ->
    subscription.valueType.MDObjects(configuration)
        .forEach { GraphEdge.contains(nodeId(subscription.uuid), nodeId(it.uuid)) }
}
```
**Частичная реализация:**
- ✅ EventSubscription-узел создаётся (NodeType.EVENT_SUBSCRIPTION)
- ✅ CONTAINS ребро: EventSubscription → MDObject (на КАКОЙ тип объекта подписана)
- ❌ Нет ребра к процедуре-обработчику (handler routine) — т.к. нет Routine-узлов вообще

### 5. Парсинг и извлечение

MetadataExporterServiceImpl.kt:38:
```kotlin
MDOReader.readConfiguration(configurationPath) as Configuration
```

Библиотека: `bsl-mdclasses` версия `feature-valueTypes-814fc7b` (кастомный feature-бранч! не стабильный релиз).  
Поддерживаемые форматы: Designer (XML-файлы конфигуратора) + EDT (MDO-файлы EDT).  
Автодетект: по наличию `Configuration.xml` или `src/Configuration/Configuration.mdo`.

Что берётся из bsl-mdclasses (MetadataExporter.kt):
- `Configuration.children` — все MD-объекты конфигурации
- `Configuration.subsystems`, `.roles`, `.functionalOptions`, `.exchangePlans`, `.eventSubscriptions`
- `MD.uuid`, `.name`, `.synonym.any`, `.mdoType` → NodeType via `MDOType.toNodeType()`
- `AttributeOwner.allAttributes` → тип каждого → ATTRIBUTE рёбра
- `TabularSectionOwner.tabularSections` → их атрибуты
- `Role.data.objectRights` → ACCESS рёбра
- `configuration.findChild(MdoReference)` — детерминированный резолв ссылок

`bsl-parser` объявлен в зависимостях (libs.versions.toml:24) но **НЕ ИСПОЛЬЗУЕТСЯ** ни в одном Kotlin-файле. LLM в построении графа — отсутствует полностью.

**Детерминированность подтверждена по коду: ДА.**

### 6. Хранилище

NebulaGraph 3.0.0. Явного обоснования в репо нет.  
Схема: 1 тег (`MDObject`), 5 типов рёбер. VID = UUID без дефисов (FIXED_STRING(32)).  
Запросы: nGQL с MATCH-синтаксисом (openCypher-совместимый).  
Использование возможностей: базовые MATCH, INSERT, DELETE. Нет аналитических возможностей (аггрегации, алгоритмы на графе не используются).

Объективная оценка: для текущего набора данных (только метаданные, ~1000-5000 узлов для типовой конфигурации, нет кода/процедур) NebulaGraph — избыточный инфраструктурный компонент. Тот же граф покрывается SQLite + adjacency table.

### 7. Лицензия и язык

- **Лицензия:** MIT (LICENSE: Copyright 2025 Koryakin Aleksey)
- **Язык:** Kotlin 2.1.20, Spring Boot 3.5.0, JVM 17
- **Зависимости 1c-syntax:** лицензия не проверялась отдельно, но 1c-syntax/bsl-mdclasses — open source Apache 2.0
- **Переиспользуемость:** ВЫСОКАЯ — MIT, полный исходник, чистая архитектура (Clean Architecture + DDD)

---

## Сопоставление двух схем графа (таблица)

| Аспект | 1c-mcp-metacode (Neo4j) | bsl-graph (NebulaGraph) |
|--------|------------------------|------------------------|
| **Исходный код** | Закрытый (Docker only) | Открытый (MIT) |
| **Язык** | Python | Kotlin + Spring Boot |
| **Узлы метаданных** | ~25 специализированных типов | 1 тег MDObject, ~75 типов в свойстве |
| **Свойства узлов** | Не определить | uid, name, synonym, type |
| **Routine / Procedure** | ✅ ДА — отдельный тип узла | ❌ НЕТ (запланировано) |
| **Module** | ✅ ДА — отдельный тип узла | ❌ НЕТ |
| **Граф вызовов (CALLS)** | ✅ ДА — ребро Routine→Routine | ❌ НЕТ |
| **Формы (Form/FormControl)** | ✅ ДА | ❌ НЕТ как отдельные узлы |
| **EventSubscription → handler** | ✅ ДА (HAS_HANDLER → Routine) | ❌ НЕТ handler-связи |
| **EventSubscription → source** | Не определить | ✅ ДА (CONTAINS → MDObject) |
| **ATTRIBUTE ребра (тип реквизита)** | Есть (USED_IN семантика) | ✅ ДА с именем реквизита |
| **ACCESS ребра (права)** | ✅ ДА (GRANTS_ACCESS_TO) | ✅ ДА (с перечислением прав) |
| **Подсистемы (иерархия)** | ✅ CONTAINS_OBJECT | ✅ CHILDREN |
| **HTTP сервисы** | ✅ UrlTemplate / UrlMethod | ❌ как узлы не выделяются |
| **Обход вглубь** | `call_graph_subtree` (N уровней) | `findRelatedNodes(maxDepth)` (N уровней) |
| **Защита от циклов** | Не определить | Только DISTINCT, нет стоп-листов |
| **MCP-инструментов** | 3 (search_metadata, search_by_description, search_code) | 1 рабочий (readMetadata) |
| **LLM в построении графа** | ❌ НЕТ (только в NL→Cypher) | ❌ НЕТ |
| **Детерминированность** | ДА | ДА |
| **Граф. БД** | Neo4j | NebulaGraph |
| **Необходимость графовой БД** | Оправдана (N-level Cypher обходы) | Избыточна (только метаданные без кода) |

---

## Ключевой вывод по резолву одноимённых процедур

**Ни один из проектов не решил проблему полностью в открытом коде.**

**bsl-graph:** граф вызовов не реализован вообще (Routine-узлов нет). Проблема ещё не поставлена.

**1c-mcp-metacode:** граф вызовов есть (Routine→CALLS→Routine), Routine квалифицирован через Module через MetadataObject. Это означает, что при условии корректного построения ребра CALLS, callee-Routine однозначно идентифицируется через цепочку `Routine.id → Module.id → MetadataObject.id`. Проблема одноимённых процедур теоретически **решена архитектурой**: квалификатор есть. Однако:
- Детали алгоритма резолва имени → конкретный узел — **не определить** (закрытый код)
- Как именно из BSL-кода `ОбщийМодуль.Записать()` строится ребро до конкретного Routine узла — неизвестно
- Шаблон `resolve_qn` существует, что подтверждает наличие механизма, но реализация закрыта

**Вывод для Азимута:** схема metacode правильная — Routine → Module → MetadataObject даёт полную квалификацию. При реализации нужно хранить ребро CALLS как ссылку на resolved Routine-узел (не строку), а для резолва использовать аналог `find(ModuleType.OwnerType + "." + OwnerName + "." + RoutineName)`.

---

## Рекомендация по схеме графа для Азимута

### Что брать и откуда

**Схема узлов и рёбер метаданных: от bsl-graph (MIT-код)**

Конкретно:
- `NodeType` enum из MDObjectNode.kt:26-106 — полный, покрывает все типы 1С, 1:1 маппинг через MDOType
- `ATTRIBUTE` ребро с property `name` (имя реквизита) — элегантный способ хранить тип-связь
- `ACCESS` ребро с property `name` (список прав) — аналогично
- Логика MetadataExporter.kt — сам алгоритм обхода дерева конфигурации через bsl-mdclasses: переиспользовать напрямую
- `MDOReader.readConfiguration()` как единая точка входа

**Схема кода (Routine/Module): от 1c-mcp-metacode (структура из документации)**

Конкретно:
- Добавить узел `Module` с типами (OBJECT_MODULE, MANAGER_MODULE, FORM_MODULE, COMMON_MODULE, etc.)
- Добавить узел `Routine` (procedure/function) с привязкой к Module
- Ребро `Module →[DECLARES]→ Routine`
- Ребро `MetadataObject →[HAS_MODULE]→ Module`
- Ребро `Routine →[CALLS]→ Routine` (с resolved ссылкой, не строкой!)

**Граф подписок: от 1c-mcp-metacode (полная схема)**

- `EventSubscription →[HAS_HANDLER]→ Routine` — ключевое кросс-объектное ребро
- Источник (на какой объект) через отдельный тип ребра (аналог bsl-graph CONTAINS)

**Механизм обхода: от bsl-graph (открытый код)**

- `findRelatedNodes(nodeId, maxDepth)` — прямой шаблон
- Добавить: защита от циклов (visited set), стоп-лист на слишком общих узлах

### Нужна ли отдельная графовая БД?

**Вывод: НЕТ для текущего этапа (только метаданные). ДА для следующего (с кодом).**

Аргументы:
- Только метаданные (bsl-graph уровень) — SQLite с таблицей edges(src_id, dst_id, edge_type, properties) + BFS в коде полностью достаточно. Типовая конфигурация даёт ~5000 узлов, ~20000 рёбер.
- С кодом (metacode уровень) — добавляются Routine-узлы (~50K процедур для типовой Бухгалтерии), CALLS рёбра (сотни тысяч). N-уровневые Cypher-обходы `(start)-[*1..5]-(end)` начинают давать преимущество перед BFS в коде. Но даже здесь SQLite с recursive CTE справится.
- NebulaGraph / Neo4j оправданы при: нужен интерактивный UI (Neo4j Browser), или если команда уже знает Cypher, или при > миллиона рёбер. Для Азимута на старте — добавляют операционный overhead без пропорциональной пользы.

**Конкретная рекомендация для Азимута:** хранить граф в SQLite (edges + nodes таблицы), обходить через Python BFS с visited set. При росте > 500K рёбер или необходимости UI — мигрировать на Neo4j (т.к. у metacode схема задокументирована, Cypher переносится).

### Итоговый вывод по каждому пункту задачи

1. **Схема узлов/рёбер** → брать из bsl-graph (MIT, открытый код), дополнить Module+Routine по образцу metacode
2. **Механизм обхода** → bsl-graph `findRelatedNodes`, дополнить защитой от циклов
3. **Резолв имён** → архитектуру берём из metacode (Routine квалифицирован через Module→MetadataObject), детали реализуем сами через bsl-mdclasses + bsl-parser
4. **Подписки на события** → схему из metacode (EventSubscription →[HAS_HANDLER]→ Routine), данные из bsl-mdclasses `eventSubscriptions`
5. **Граф. БД** → на старте SQLite, не NebulaGraph

---

## Где не определить

- 1c-mcp-metacode: всё за пределами документации (алгоритмы резолва, свойства узлов, Cypher-запросы) — закрытый код
- 1c-mcp-metacode: точный алгоритм построения ребра CALLS при одноимённых процедурах
- 1c-mcp-metacode: лицензия (LICENSE-файл отсутствует)
- bsl-graph: почему именно NebulaGraph (явного обоснования нет)

---

*Файлы: notes-HLE-459.md (сырые заметки), result-HLE-459.md (этот отчёт)*
