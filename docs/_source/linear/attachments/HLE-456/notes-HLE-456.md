# Заметки HLE-456: Сравнение 4 реализаций индекс/граф 1С

## Репозитории
1. `Arman-Kudaibergenov/bsl-atlas` — Python, SQLite + ChromaDB
2. `ROCTUP/1c-mcp-metacode` — Python + Neo4j
3. `alkoleft/bsl-graph` — Kotlin, NebulaGraph
4. `feenlace/mcp-1c` — Go, быстрая индексация

---

## 1. bsl-atlas (Arman-Kudaibergenov/bsl-atlas)

### Клонирование и структура

Файлы (без .git): models.py, parsers/code.py, parsers/tree_sitter_parser.py, parsers/metadata.py, parsers/metadata_xml.py, storage/sqlite_store.py, indexer/vector_indexer.py, search/hybrid.py, main.py

---

### A. Модель графа

**Узлы (таблицы SQLite):**
- `files` — BSL-файлы: path, file_hash, module_type (`storage/sqlite_store.py:44-51`)
- `symbols` — функции/процедуры: name, type, params, is_export, line_start, line_end, file_id (`sqlite_store.py:52-68`)
- `objects` — метаданные: name, object_type, synonym, full_name (`sqlite_store.py:76-82`)
- `attributes`, `tab_parts`, `tab_part_attributes`, `register_movements` — реквизиты и движения

**Рёбра:**
- `calls(caller_id REFERENCES symbols, callee_name TEXT)` — граф вызовов (`sqlite_store.py:71-75`)
- `attributes.type_ref` — ссылки типов между объектами метаданных

**Главное — резолв имён:** callee хранится ТОЛЬКО как строка (`callee_name TEXT`). Нет резолва до модуля. Одноимённые процедуры неразличимы. (`models.py:25: calls: list[str]`)

**Связь код↔метаданные:** только через module_path (путь файла). Явной FK между `symbols` и `objects` нет.

**Хранилище:** SQLite (структурный) + ChromaDB (векторный). Обоснование в README: SQLite для мгновенного поиска без эмбеддингов.

---

### B. Обход графа

**Глубина:** только 1 уровень. `get_function_context` (`sqlite_store.py:501-534`) делает один JOIN к `calls`. Нет рекурсии, нет CTE.

**МСР-инструменты:**
- `get_function_context(function_name)` → {function, calls: list[str], called_by: list[str]} (`main.py:272-301`)

**Защита от циклов:** нет (не нужна при 1 уровне).

В тестах упоминается `ReverseCallIndex` (`tests/test_reverse_call_index.py`), но в текущих исходниках его нет — возможно, удалён или не смержен.

---

### C. Чанкинг

**Стратегия:** функция-уровень. Каждая процедура/функция = 1 чанк. (`vector_indexer.py:460-511`)

**Пороги:** body <= 2000 символов → 1 чанк; больше → RecursiveCharacterTextSplitter(chunk_size=config.chunk_size, chunk_overlap=config.chunk_overlap, separators=["\n\n", "\n", ". ", " ", ""]) (`vector_indexer.py:499-503`, `vector_indexer.py:72-76`)

**Фильтр мелких:** функции < 5 строк пропускаются (`vector_indexer.py:467`)

**Контекст в чанке:** имя функции, module_path, module_type, is_export, параметры (`vector_indexer.py:488-495`)

**Запросы в строках:** спец-обработки нет. Длинные If/Цикл не разрезаются особо.

---

### D. Парсинг BSL

**Инструмент:** tree-sitter с grammar alkoleft/tree-sitter-bsl (bsl.so), fallback на regex. (`tree_sitter_parser.py:12`, `code.py:233`)

**Точка входа:** `tree_sitter_parser.parse_functions(file_path, src_bytes)` → возвращает list[dict] с name/type/params/calls/body/line_start/line_end (`tree_sitter_parser.py:120`)

**Метаданные XML:** `metadata_xml.py:332` — парсит XML-дамп конфигуратора через stdlib `xml.etree`. Поддерживает Catalogs/Documents/Registers/... + расширения (cfe/).

**Метаданные TXT:** `metadata.py:139` — собственный парсер текстового отчёта метаданных 1С.

**ПодпискиНаСобытие:** упомянуты в `metadata.py:40` как тип объекта метаданных. Кросс-объектные рёбра (событие → обработчик) **НЕ строятся**.

---

### E. Скорость / масштаб

**Параллелизм:** ThreadPoolExecutor(max_workers=8) при сборе чанков (`vector_indexer.py:664-702`)

**Инкрементальность:** file_tracker.db (SQLite), hash-based. Есть уровень функций: function-hash (`vector_indexer.py:473-478`)

**Числа:** конкретных цифр (время/размер корпуса) в README нет.

---

### F. Внешние обработки / расширения

**.epf/.erf:** не упоминаются, не поддерживаются.

**Расширения (cfe):** `metadata_xml.py:421-427` — директория `cfe/ExtName/` обходится как отдельный корень поиска XML.

---

### G. Лицензия

**AGPL-3** (`LICENSE:1`). Несовместима с коммерциализацией без открытия кода сервиса. ⚠️ Критично для «Азимут».

---

## 2. 1c-mcp-metacode (ROCTUP/1c-mcp-metacode)

**⚠️ ИСХОДНЫЙ КОД ЗАКРЫТ** — репо содержит только README.md, MCP_SERVER_CAPABILITIES.md, .env.example, docker-compose.example.yml. Распространяется как Docker-образ `roctup/1c-mcp-metacode`. Из кода ничего не определить.

### A. Модель графа (из README диаграммы)

**Узлы** (Neo4j): Project, Configuration, MetadataCategory, MetadataObject, Form, FormControl, FormEvent, FormAttribute, Attribute, TabularPart, Resource, Dimension, Module, Routine, Command, UrlTemplate, UrlMethod, EventSubscription, PredefinedItem, Layout, Characteristic, EnumValue, JournalGraph, AccountingFlag, DimensionAccountingFlag (`README.md:25-78`)

**Рёбра:**
- Project -contains-> Configuration -has-> MetadataCategory -contains-> MetadataObject
- MetadataObject -HAS_MODULE-> Module -DECLARES-> Routine
- Routine -CALLS-> Routine ← **граф вызовов с узлами Routine** (`README.md:51-52`)
- EventSubscription -HAS_HANDLER-> Routine — подписки на события с привязкой к процедуре (`README.md:57`)
- FormEvent -HAS_HANDLER-> Routine — события форм → обработчики
- MetadataObject -USED_IN-> Object, -DO_MOVEMENTS_IN-> Register, -GRANTS_ACCESS_TO-> AccessTarget

**Главное — резолв имён:** Ребро CALLS ведёт к узлу Routine, который DECLARES конкретный Module, который принадлежит MetadataObject. То есть callee **резолвится до конкретного объекта метаданных**. MCP_CAPABILITIES: "Кто вызывает процедуру ПередЗаписью модуля объекта документа Счёт?" → квалифицированный поиск (`MCP_SERVER_CAPABILITIES.md:66`).

**Хранилище:** Neo4j. Обоснования выбора в публичных файлах нет.

### B. Обход графа

**Многоуровневый обход!** Операции: `call_graph_subtree` — поддерево вызовов на N уровней. Пример: "Кого вызывает ПередЗаписью... (глубина 2)?" (`MCP_SERVER_CAPABILITIES.md:95, 84`). Реализовано через Cypher: `MATCH (r)-[:CALLS*1..N]->()` — из кода не определить, но Neo4j нативно поддерживает variable-length paths.

**MCP-инструменты для обхода:**
- `list_callees_of_routine` — прямые вызовы
- `list_callers_of_routine` — кто вызывает
- `call_graph_subtree` — поддерево на N уровней
- `find_calls_between_owners` — вызовы между объектами
- `find_unused_routines` — неиспользуемые процедуры
- (`MCP_SERVER_CAPABILITIES.md:84`)

**Защита от циклов:** из кода не определить.

### C. Чанкинг

Из кода не определить (закрытый образ). README: "Загрузка описания и тела всех процедур и функций" — вероятно, процедура = 1 единица хранения в Neo4j.

### D. Парсинг BSL

Из кода не определить. Входные данные: `.bsl` файлы из выгрузки конфигуратора + `Form.bin` (обычные формы, v1.3.0). Метаданные: TXT-отчёт конфигуратора + XML-выгрузка. Подписки: `EventSubscriptions/*.xml`. Предопределённые: `Predefined.xml`.

ПодпискиНаСобытие: **да**, поддерживаются, EventSubscription -HAS_HANDLER-> Routine.

### E. Скорость / масштаб

- Полная загрузка (без эмбеддингов): ~30 минут для Бухгалтерии (`README.md:206`)
- Параллелизация загрузки добавлена в v1.3.0 (~2× ускорение)
- Векторная индексация: ~30 минут на Qwen3-4B_Q8 на RTX 5070Ti
- Инкрементальность: `FULL_METADATA_RELOAD=true` — полная перезагрузка, delta не упоминается явно

### F. Внешние обработки

- Form.bin (обычные формы): да, v1.3.0 (`README.md:274`)
- .epf/.erf: не упоминаются
- Расширения (cfe): не упоминаются

### G. Лицензия

**Не указана** в публичных файлах. Закрытый код. Использование только через Docker-образ. Коммерциализация производного — не определить.

---

## 3. bsl-graph (alkoleft/bsl-graph)

### A. Модель графа

**Хранилище:** NebulaGraph v3 (`gradle/libs.versions.toml:nebula-java = "3.0.0"`).

**Узлы:** единый тег `MDObject` для всех объектов метаданных. NodeType enum (`domain/graph/MDObjectNode.kt:75`): CONFIGURATION, SUBSYSTEM, COMMON_MODULE, CATALOG, DOCUMENT, ENUM, REPORT, PROCESSING, INFORMATION_REGISTER, ACCUMULATION_REGISTER, ACCOUNTING_REGISTER, ROLE, EVENT_SUBSCRIPTION, SCHEDULED_JOB и др. Процедур/функций как отдельных узлов **нет**.

**Рёбра:** EdgeType enum (`MDObjectNode.kt`): CONTAINS, RELATED_TO, CHILDREN, ATTRIBUTE, ACCESS. **Ребра CALLS нет — граф вызовов не реализован и не планируется в текущей архитектуре.**

**Резолв имён:** N/A — BSL код не парсится.

**Связь:** EventSubscription → обработчик строится через MetadataExporter (`infrastructure/graph/MetadataExporter.kt`), использует bsl-mdclasses.

---

### B. Обход графа

**Глубина:** `findRelatedNodes(nodeId, maxDepth)` (`infrastructure/graph/NebulaRepository.kt:117`):
```kotlin
"MATCH p = (start)-[*1..$maxDepth]-(related) WHERE related <> start RETURN DISTINCT related"
```
Variable-length path поддерживается, но только по метаданным (не по коду).

**MCP-инструменты:** `searchMetadata()` в `ContextMcpController.kt:42-67` **полностью закомментирован**. Работает только `readMetadata()`. Поиск нефункционален.

**Защита от циклов:** `WHERE related <> start` — защита только от самопетель, не от циклов длиной > 1.

---

### C. Чанкинг

BSL Parser интеграция: **0%** (`memory-bank/progress.md`: "Настроить интеграцию с BSL Parser - Не начато"). Чанкинг не реализован, из кода не определить.

---

### D. Парсинг BSL

**Зависимости:** `bsl-mdclasses = "feature-valueTypes-814fc7b"`, `bsl-parser = "0.26.1"` подключены (`gradle/libs.versions.toml`), но bsl-parser не используется (`progress.md`: 0%).

**Метаданные:** `MDOReader.readConfiguration(configurationPath)` (`infrastructure/metadata/MetadataExporterServiceImpl.kt`). Читает конфигурацию 1С: иерархия подсистем, права ролей, функциональные опции, подписки на события, атрибуты объектов.

**ПодпискиНаСобытие:** да, рёбра строятся через MetadataExporter.

**BSL код:** не парсится.

---

### E. Скорость / масштаб

Spring Boot 3.5.0 + NebulaGraph — тяжёлая инфраструктура. Конкретных цифр нет. Стадия: Stage 1 (Code Analysis) в roadmap, не начата.

---

### F. Внешние обработки / расширения

**.epf/.erf:** не упоминаются.
**Расширения (.cfe):** не упоминаются.

---

### G. Лицензия

**MIT** ✅

---

## 4. mcp-1c (feenlace/mcp-1c)

### A. Модель графа

**Не граф.** Полнотекстовый поиск на Bleve (Go, BM25 через scorch engine). Хранилище: шардированный дисковый индекс (`~/.cache/mcp-1c/<sha256-dump-path>/shard_N`).

**Узлы:** `bslDocument{Name, Category, Module, Content}` (`dump/index.go`) — модуль целиком как документ. Например: `"Документ.РеализацияТоваров.МодульОбъекта"`.

**Рёбра:** отсутствуют — граф не строится вообще. В платной версии "Профессиональная" (4 990 ₽/мес, закрытый код) упомянут "граф зависимостей модулей (10 типов связей, SQLite)" (`README.md:59`), но это закрытая функциональность.

**Резолв имён:** N/A.

---

### B. Обход графа

Отсутствует (не граф). `search_code` — только полнотекстовый поиск. Три режима: smart (BM25), regex (Go regexp), exact (регистронезависимая подстрока) (`tools/search.go:76-84`).

---

### C. Чанкинг

**Уровень: модуль целиком.** Каждый .bsl файл = 1 документ. Функции не выделяются, не разрезаются. `loadBSLFiles()` читает весь файл в `contentByName` (`dump/index.go:573`).

---

### D. Парсинг BSL

**Нет AST-парсинга.** Имя модуля: `parseModuleName(name)` (`dump/index.go`) — только разбор пути/имени файла, не кода.

**Анализатор Bleve:** кастомный `"bsl"` (`dump/analyzer.go:154-202`): unicode-токенайзер → lowercase → BSL-синонимный фильтр.

**BSL-синонимы** (`dump/analyzer.go:65-152`): двусторонняя карта ~40 ключевых слов BSL + 180 встроенных функций платформы. `StrFind ↔ СтрНайти`, `Процедура ↔ Procedure` и т.д. При поиске по английскому имени находит русское и наоборот.

**Метаданные XML:** не парсятся. `dump/formparser.go` — парсит структуру форм из XML.

**ПодпискиНаСобытие:** не поддерживаются.

`bsl/functions.go` — статическая таблица 180 встроенных функций платформы (для инструмента `bsl_syntax_help`, не для индексации).

---

### E. Скорость / масштаб

**Заявлено:** ~7 сек для 13 000+ модулей (`README.md:73`).

**Техники ускорения:**
1. `debug.SetGCPercent(-1)` — отключение GC на время сборки (`dump/index.go:buildShards()`)
2. `runtime.NumCPU()` горутин для параллельного чтения файлов (`loadBSLFiles()`)
3. FNV-32a шардирование: `totalFiles / 2000` шардов, clamped [1, NumCPU] (`dump/shard.go:16`)
4. Пакетная индексация: 5000 документов/батч + `unsafe_batch: true` (`dump/shard.go:59`)
5. Дисковый кеш: SHA-256 от пути дампа → повторный запуск мгновенный (`dump/cache.go:18`)
6. Инкрементальность по манифесту: пересобирает только изменённые файлы (`dump/index.go:1119`)
7. Неблокирующий старт: индекс строится в фоне, MCP готов сразу (`README.md:74`)

Конкретных цифр в коде нет (benchmark требует реального дампа по пути `/Users/igoroot/GolandProjects/mcp/dumps/dump_2`, `bench_test.go:17`).

**Параллелизм:** два уровня — горутины для чтения файлов + горутины для параллельной сборки шардов.

---

### F. Внешние обработки / расширения

**.epf/.erf:** не поддерживаются в open source версии.

**Расширения (.cfe):** в платной версии "Расширенная" (1 990 ₽/мес, `README.md:24`). В open source недоступны.

**Интеграция с живой 1С:** `onec/client.go` — HTTP-клиент к 1С-сервису. Расширение устанавливается командой `--install` через `go:embed` + DESIGNER. Инструменты для живой базы: метаданные, формы, запросы, журнал регистрации.

---

### G. Лицензия

**MIT** ✅ (`README.md:247`)
