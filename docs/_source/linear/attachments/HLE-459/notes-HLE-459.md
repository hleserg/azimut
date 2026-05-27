# Заметки HLE-459: Глубокий разбор 1c-mcp-metacode + bsl-graph

Дата: 2026-05-26

## Статус
- [ ] 1c-mcp-metacode (Neo4j, Python)
- [ ] bsl-graph (NebulaGraph, Kotlin)

---

## РЕПО 1: ROCTUP/1c-mcp-metacode

### Клонирование
git clone --depth=1 → /tmp/1c-mcp-metacode
Статус: ЗАКРЫТЫЙ ИСХОДНЫЙ КОД. Репо содержит только README.md, MCP_SERVER_CAPABILITIES.md, docker-compose.example.yml, .env.example
Нет Python-файлов. Распространяется как Docker image: roctup/1c-mcp-metacode
1 коммит в истории: "fac2faf Update README.md"

### Секция 1: Полная модель графа (из README.md)

**Узлы (все типы):**
Из Mermaid-диаграммы README.md:
- Project — проект (верхний уровень)
- Configuration — конфигурация 1С
- MetadataCategory — категория метаданных (Справочники/Документы/...)
- MetadataObject — объект метаданных (конкретный справочник/документ/регистр/...)
- Form — форма объекта
- FormControl — элемент управления формы
- FormEvent — событие формы / элемента формы
- FormAttribute — атрибут формы
- Attribute — реквизит объекта
- TabularPart — табличная часть
- Resource — ресурс регистра
- Dimension — измерение регистра
- Module — модуль (ObjectModule, ManagerModule, FormModule, CommonModule...)
- Routine — процедура/функция (ключевой узел кода!)
- Command — команда объекта / формы
- UrlTemplate — шаблон URL (HTTP-сервис)
- UrlMethod — метод HTTP-сервиса
- EventSubscription — подписка на событие
- PredefinedItem — предопределённый элемент
- Layout — макет
- Characteristic — характеристика
- EnumValue — значение перечисления
- JournalGraph — граф журнала документов
- AccountingFlag — признак учёта
- DimensionAccountingFlag — признак учёта субконто

**Рёбра (все типы):** README.md (Mermaid-диаграмма)
- Project →|contains| Configuration
- Configuration →|has| MetadataCategory
- MetadataCategory →|contains| MetadataObject
- MetadataObject →|HAS_FORM| Form
- MetadataObject →|HAS_MODULE| Module
- MetadataObject →|HAS_ATTRIBUTE| Attribute
- MetadataObject →|HAS_TABULAR_PART| TabularPart
- MetadataObject →|HAS_RESOURCE| Resource
- MetadataObject →|HAS_DIMENSION| Dimension
- MetadataObject →|HAS_COMMAND| Command
- MetadataObject →|HAS_URL_TEMPLATE| UrlTemplate
- MetadataObject →|HAS_EVENT_SUBSCRIPTION| EventSubscription
- MetadataObject →|HAS_PREDEFINED| PredefinedItem
- MetadataObject →|HAS_LAYOUT| Layout
- MetadataObject →|HAS_CHARACTERISTIC| Characteristic
- MetadataObject →|HAS_ENUM_VALUE| EnumValue
- MetadataObject →|HAS_GRAPH| JournalGraph
- MetadataObject →|HAS_ACCOUNTING_FLAG| AccountingFlag
- MetadataObject →|HAS_DIMENSION_ACCOUNTING_FLAG| DimensionAccountingFlag
- MetadataObject →|USED_IN| (target object)
- MetadataObject →|DO_MOVEMENTS_IN| Register
- MetadataObject →|GRANTS_ACCESS_TO| AccessTarget
- MetadataObject →|CONTAINS_OBJECT| MetadataObject (подсистемы)
- Module →|DECLARES| Routine
- **Routine →|CALLS| Routine** (граф вызовов!)
- Form →|HAS_CONTROL| FormControl
- Form →|HAS_EVENT| FormEvent
- Form →|HAS_FORM_ATTRIBUTE| FormAttribute
- Form →|HAS_COMMAND| Command
- FormControl →|HAS_EVENT| FormEvent (событие элемента)
- FormControl →|HAS_CHILD| FormControl (иерархия)
- FormControl →|BINDS_TO| (bind target)
- FormControl →|LINKS_TO_COMMAND| Command
- FormEvent →|HAS_HANDLER| Routine (обработчик)
- EventSubscription →|HAS_HANDLER| Routine
- Command →|HAS_HANDLER| Routine
- UrlTemplate →|HAS_URL_METHOD| UrlMethod
- UrlMethod →|HAS_HANDLER| Routine
- PredefinedItem →|HAS_CHILD| PredefinedItem
- TabularPart →|HAS_ATTRIBUTE| Attribute

**Итого: ~25 типов узлов, ~35+ типов рёбер**

### Секция 2: Резолв имён (по документации)

Из README.md и MCP_SERVER_CAPABILITIES.md:
- Ребро CALLS: Routine →|CALLS| Routine
- В MCP_SERVER_CAPABILITIES.md упомянуты операции call_graph_subtree, list_callees_of_routine, list_callers_of_routine
- Упомянут шаблон `resolve_qn` — "resolve qualified name"
- README: "формирование графа вызовов" при LOAD_BSL_SIGNATURES=true
- НО: Исходный код закрытый → алгоритм резолва НЕИЗВЕСТЕН

Из MCP описания: "кто вызывает процедуру X модуля объекта Y (callers)" — это говорит что Routine ПРИВЯЗАН к Module, а Module ПРИВЯЗАН к MetadataObject. Т.е. квалификация есть: Routine имеет владельца (Module), Module принадлежит объекту. Но способ хранения целевого узла CALLS неизвестен — строка или resolved ссылка?

Шаблон `resolve_qn` — "Поиск и навигация" — предположительно: квалифицированное имя → узел графа. Но деталей нет.

### Секция 3: Обход графа

Из MCP_SERVER_CAPABILITIES.md:
- `call_graph_subtree` — обход вглубь с поддержкой "многоуровневой глубины анализа"
- Упоминается "глубина 2" в примерах: "Кого вызывает процедура ПередЗаписью (глубина 2)?"
- Конкретные Cypher-запросы неизвестны (закрытый код)

### Секция 4: Подписки на события

README.md: "Загрузка подписок на события и привязка к обработчикам" — ЕСТЬ!
- EventSubscription →|HAS_HANDLER| Routine
- `list_event_subscriptions`, `list_event_subscriptions_of_object`, `get_event_subscription_sources`
- LOAD_EVENT_SUBSCRIPTIONS=true (default)
- MCP example: "Подписки на события конфигурации: список всех подписок, подписки для конкретного объекта метаданных (с указанием События и Обработчика), а также Источники подписки"
- ⭐ РЕБРО: EventSubscription →|HAS_HANDLER| Routine — кросс-объектная связь!

### Секция 5: Парсинг и извлечение

Из README.md / .env.example:
- Источники данных:
  - `./data/metadata/*.txt` — "Отчёт по конфигурации" (Конфигуратор → Конфигурация → Отчёт по конфигурации в текстовый файл)
  - `./data/code/` — "Выгрузка конфигурации в файлы (XML-файлы)" (Конфигуратор → Конфигурация → Выгрузить конфигурацию в файлы)
  - Отдельно: `EventSubscriptions/*.xml`, `Form.xml`, `Roles/*/Ext/Rights.xml`, `Predefined.xml`, `Help/ru.html`, `.bsl` файлы
  - Form.bin — обычные формы (добавлено в v1.3.0)
- Язык реализации: Python (по README "Python + Cypher" в названии задачи)
- НО: исходный код закрытый

### Секция 6: Хранилище графа

Из README.md:
- Neo4j: порты 7474 (browser), 7687 (bolt)
- Причина выбора: не задокументирована в репо
- Конфигурация: heap max 4096m, transaction max 4096m
- Поддерживает Cypher-запросы и full-text индексы
- Поддерживает векторные индексы (для embeddings)
- Загрузка конфигурации ~30 мин для типовой Бухгалтерии

### Секция 7: Лицензия и язык

- Лицензионный файл: ОТСУТСТВУЕТ в репо (нет LICENSE файла)
- Язык: Python (закрытый, Docker-образ: roctup/1c-mcp-metacode)
- ⚠️ Переиспользуемость: ОЧЕНЬ ОГРАНИЧЕНА — нет исходного кода, только Docker image

---

## РЕПО 2: alkoleft/bsl-graph

### Клонирование
git clone --depth=1 → /tmp/bsl-graph
Статус: ОТКРЫТЫЙ ИСХОДНЫЙ КОД. Kotlin/Spring Boot, полный исходник.

### Файловая структура

Источники:
- src/main/kotlin/ru/alkoleft/context/domain/graph/MDObjectNode.kt — модель узлов/рёбер
- src/main/kotlin/ru/alkoleft/context/infrastructure/graph/SchemaInitializer.kt — DDL NebulaGraph
- src/main/kotlin/ru/alkoleft/context/infrastructure/graph/MetadataExporter.kt — построение графа
- src/main/kotlin/ru/alkoleft/context/infrastructure/metadata/Mapper.kt — маппинг MDOType → NodeType
- src/main/kotlin/ru/alkoleft/context/infrastructure/metadata/MetadataExporterServiceImpl.kt — точка входа
- src/main/kotlin/ru/alkoleft/context/infrastructure/graph/NebulaRepository.kt — nGQL запросы
- src/main/kotlin/ru/alkoleft/context/infrastructure/graph/NebulaGraphService.kt — сырые INSERT/SELECT
- src/main/kotlin/ru/alkoleft/context/presentation/mcp/ContextMcpController.kt — MCP инструменты
- src/main/kotlin/ru/alkoleft/context/presentation/rest/GraphRestController.kt — REST API
- gradle/libs.versions.toml — зависимости

### Секция 1: Полная модель графа

**ЕДИНЫЙ тег вершин:** `MDObject` (SchemaInitializer.kt:54)
Все вершины хранятся под одним тегом, тип различается свойством `type`.

**Свойства узла MDObject:** (QueryMapper.kt:24-26)
- uid: string — UUID объекта
- name: string — техническое имя
- synonym: string — синоним (русское название)
- type: string — NodeType.name() из enum

**NodeType enum — полный перечень:** (MDObjectNode.kt:26-106)
Метаданные 1С:
CONFIGURATION, CATALOG, DOCUMENT, ENUM, CONSTANT, REGISTER, BUSINESS_PROCESS, TASK, COMMON_MODULE,
COMMAND_GROUP, COMMAND, ATTRIBUTE, DIMENSION, RESOURCE, FORM, TABLE, QUERY, REPORT, DATA_PROCESSOR,
EXTERNAL_DATA_SOURCE, EXCHANGE_PLAN, CHART_OF_ACCOUNTS, CHART_OF_CHARACTERISTIC_TYPES, CHART_OF_CALCULATION_TYPES,
FILTER_CRITERION, INFORMATION_REGISTER, ACCUMULATION_REGISTER, ACCOUNTING_REGISTER, CALCULATION_REGISTER,
DOCUMENT_JOURNAL, ROLE, SUBSYSTEM, LANGUAGE, STYLE_ITEM, STYLE,
ACCOUNTING_FLAG, BOT, COLUMN, COMMON_ATTRIBUTE, COMMON_COMMAND, COMMON_FORM, COMMON_PICTURE, COMMON_TEMPLATE,
DEFINED_TYPE, DOCUMENT_NUMERATOR, ENUM_VALUE, EVENT_SUBSCRIPTION, EXTERNAL_DATA_PROCESSOR,
EXTERNAL_DATA_SOURCE_TABLE, EXTERNAL_DATA_SOURCE_TABLE_FIELD, EXTERNAL_REPORT, EXT_DIMENSION_ACCOUNTING_FLAG,
FUNCTIONAL_OPTION, FUNCTIONAL_OPTIONS_PARAMETER, HTTP_SERVICE, HTTP_SERVICE_METHOD, HTTP_SERVICE_URL_TEMPLATE,
INTEGRATION_SERVICE, INTEGRATION_SERVICE_CHANNEL, INTERFACE, PALETTE_COLOR, RECALCULATION, SCHEDULED_JOB,
SEQUENCE, SESSION_PARAMETER, SETTINGS_STORAGE, STANDARD_ATTRIBUTE, STANDARD_TABULAR_SECTION, TABULAR_SECTION,
TASK_ADDRESSING_ATTRIBUTE, TEMPLATE, WEB_SERVICE, WS_OPERATION, WS_OPERATION_PARAMETER, WS_REFERENCE,
XDTO_PACKAGE, UNKNOWN

Итого: ~75 типов NodeType

**Типы рёбер EdgeType:** (MDObjectNode.kt:173-179)
- CONTAINS — содержит (конфигурация→объекты, подсистема→состав, функц.опция→состав, план обмена→состав)
- CHILDREN — дочерние (подсистема→подподсистемы)
- RELATED_TO — общая связь
- ATTRIBUTE — связь по типу реквизита: MetadataObject→MetadataObject через тип реквизита (с property name = имя реквизита)
- ACCESS — права доступа: Role → MetadataObject (с property name = список прав через запятую)

**Свойства рёбер:**
- ATTRIBUTE: name (string) = prefixedAttributeName (QueryMapper.kt:27-28, MetadataExporter.kt:163-178)
- ACCESS: name (string) = rights string (QueryMapper.kt:29-30, MetadataExporter.kt:196-203)
- CONTAINS, CHILDREN, RELATED_TO: без свойств

**⚠️ НЕТ узлов для процедур/функций!** Нет CALLS рёбер. Граф вызовов не реализован.
Roadmap README.md: "Этап 1: Анализ кода" — в планах (не реализован).

### Секция 2: Резолв имён вызовов — КРИТИЧНО

**⚠️ НЕ РЕАЛИЗОВАН В bsl-graph.**

- В bsl-graph нет узлов Routine/Procedure/Function вообще
- Нет рёбер CALLS вообще
- Граф вызовов BSL — это "Stage 1" в roadmap (планируется, не реализовано)

Что есть из "подобия резолва":
- ATTRIBUTE ребро: sourceId=nodeId(ownerUUID), targetId=nodeId(typeObjectUUID), property name = "атрибутName"
  Резолв: MetadataExporter.kt:183-191 — attribute.valueType.MDObjects(configuration) → types.filterIsInstance<MetadataValueType>().findMD(configuration)
  Это резолв ТИПОВ РЕКВИЗИТОВ (не процедур!): из MDOType + имя объекта ищем MD через configuration.findChild(MdoReference)
  MetadataExporter.kt:228-238 — MetadataValueType.findMD() и MdoReference.findMD() — детерминированный lookup по UUID/имени в bsl-mdclasses

### Секция 3: Обход графа вглубь

NebulaRepository.kt:117-148 — findRelatedNodes(nodeId, maxDepth):
- Глубина 1: `MATCH (related)-[ref]-(start) WHERE id(start) == "$nodeId" RETURN DISTINCT related, ref`
- Глубина N: `MATCH p = (start)-[*1..$maxDepth]-(related) WHERE related <> start RETURN DISTINCT related`

Реальные nGQL запросы:
- Поиск по типу: `MATCH (n:MDObject) WHERE n.type == "CATALOG" RETURN n` (NebulaRepository.kt:79)
- Поиск по свойствам: `MATCH (n:MDObject) WHERE n.uid == "..." RETURN n` (NebulaRepository.kt:100)
- Рёбра между узлами: `MATCH (n)-[e:CONTAINS|CHILDREN]->(m) WHERE id(n) IN [...] RETURN e` (NebulaRepository.kt:381-384)

Ограничение обхода:
- Параметр maxDepth (default = 1) передаётся в GraphRestController.kt:52 (`@RequestParam depth: Int`)
- Нет защиты от циклов в запросе (DISTINCT применяется, но рекурсия может зациклиться)
- Нет стоп-листов

MCP инструменты: ContextMcpController.kt — только readMetadata() и searchMetadata() (searchMetadata закомментирован)

### Секция 4: Подписки на события

MetadataExporter.kt:109-113:
```kotlin
configuration.eventSubscriptions.forEach { subscription ->
    subscription.valueType.MDObjects(configuration)
        .forEach { GraphEdge.contains(nodeId(subscription.uuid), nodeId(it.uuid)) }
}
```
⚠️ НЕПОЛНАЯ реализация:
- Создаётся только CONTAINS ребро: EventSubscription → MDObject (источник подписки, т.е. НА КАКОЙ тип объекта подписан)
- НЕТ ребра к обработчику (handler routine)
- В bsl-graph EventSubscription есть как узел (NodeType.EVENT_SUBSCRIPTION), но связь к процедуре-обработчику НЕ СТРОИТСЯ (т.к. нет узлов для процедур)

### Секция 5: Парсинг и извлечение

MetadataExporterServiceImpl.kt:38:
```kotlin
MDOReader.readConfiguration(configurationPath) as Configuration
```
Единая точка входа: `MDOReader` из `bsl-mdclasses` (версия `feature-valueTypes-814fc7b` — кастомный feature-бранч!)

Определение формата: автоматически из наличия `Configuration.xml` (Designer) или `src/Configuration/Configuration.mdo` (EDT)

Что используется из bsl-mdclasses (MetadataExporter.kt):
- `Configuration` — корень, .children, .subsystems, .roles, .functionalOptions, .exchangePlans, .eventSubscriptions
- `MD.uuid`, `.name`, `.synonym.any`, `.mdoType` — свойства узла
- `AttributeOwner.allAttributes` — все реквизиты объекта
- `Attribute.valueType` → `ValueTypeDescription.types` → `MetadataValueType.findMD()` — тип реквизита
- `TabularSectionOwner.tabularSections` → их `.attributes`
- `Role.data.objectRights` → права доступа
- `Subsystem.subsystems`, `.content`
- `EventSubscription.valueType.MDObjects()`
- `configuration.findChild(MdoReference)` — основной метод резолва объектов

Что НЕ используется из bsl-mdclasses: bsl-parser для BSL-кода (объявлен в зависимостях, но не используется в коде!)

Детерминированность: **ДА, полностью детерминированная** — MDOReader читает XML файлы конфигурации, нет LLM нигде.

### Секция 6: Хранилище графа

README.md: "NebulaGraph для хранения связей"
Явного технического обоснования в репо нет.
Что видно из кода:
- VID = UUID без тире (FIXED_STRING(32)) — SchemaInitializer.kt:26
- Partition = 10, replica_factor = 1
- Язык запросов: nGQL (MATCH-синтаксис, совместимый с openCypher)
- Нет аналитических возможностей поверх Nebula в коде — только CRUD + простые MATCH

Объективно: NebulaGraph — избыточный выбор для данного объёма. Граф строится только из метаданных (без кода), что умещается в SQLite/DuckDB. Nebula выбран, по всей видимости, из интереса к технологии.

### Секция 7: Лицензия и язык

LICENSE: MIT (alkoleft = Koryakin Aleksey)
Язык: Kotlin 2.1.20, Spring Boot 3.5.0, OpenJDK 17
Зависимости bsl-syntax: MIT или Apache 2.0 (библиотеки 1c-syntax)
Переиспользуемость: ВЫСОКАЯ — открытый MIT-код, схема графа и логика экспорта полностью доступны

---

## Статус: ОБА РЕПО ИЗУЧЕНЫ
