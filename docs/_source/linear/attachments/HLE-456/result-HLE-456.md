# HLE-456: Сравнение 4 реализаций индекс/граф 1С BSL

**Дата:** 2026-05-26  
**Репозитории:**
1. `Arman-Kudaibergenov/bsl-atlas` — Python, SQLite + ChromaDB (наш upstream)
2. `ROCTUP/1c-mcp-metacode` — Python + Neo4j (закрытый код)
3. `alkoleft/bsl-graph` — Kotlin, NebulaGraph
4. `feenlace/mcp-1c` — Go, Bleve (полнотекстовый поиск)

---

## 1. Сравнительная таблица

| Ось | bsl-atlas | 1c-mcp-metacode | bsl-graph | mcp-1c |
|-----|-----------|-----------------|-----------|--------|
| **A. Модель графа** | SQLite-таблицы: files, symbols, objects, calls(caller_id, callee_name TEXT) | Neo4j: Project→Configuration→MetadataObject→Module→Routine→CALLS→Routine | NebulaGraph: MDObject (единый тег). EdgeType: CONTAINS/RELATED\_TO/CHILDREN/ATTRIBUTE/ACCESS. **CALLS нет** | Не граф. Bleve BM25, документ = модуль целиком |
| **A. Хранилище** | SQLite (структурный) + ChromaDB (векторный) | Neo4j, 4GB heap | NebulaGraph v3 | Шардированный дисковый индекс Bleve (scorch) |
| **A. Резолв callee** | Строка (`callee_name TEXT`). Нет резолва до модуля (`sqlite_store.py:72`) | Ребро CALLS ведёт к узлу Routine, который DECLARES конкретный Module → резолв до объекта метаданных (`README.md:51-52`) | N/A — BSL не парсится | N/A — нет граф вызовов |
| **B. Глубина обхода** | 1 уровень. `get_function_context()` — 1 JOIN, нет рекурсии (`sqlite_store.py:501-534`) | N уровней. `call_graph_subtree` Cypher `CALLS*1..N` (`MCP_SERVER_CAPABILITIES.md:95`) | Variable-length path `[*1..maxDepth]` по метаданным (код не парсится) (`NebulaRepository.kt:117`) | N/A |
| **B. Защита от циклов** | Нет (не нужна при 1 уровне) | Из кода не определить (закрытый образ) | `WHERE related <> start` — только самопетли | N/A |
| **C. Чанкинг** | Функция-уровень. Тело ≤ 2000 символов → 1 чанк; > 2000 → RecursiveCharacterTextSplitter. Пропуск функций < 5 строк (`vector_indexer.py:460-511`) | Из кода не определить | Не реализован (BSL Parser 0%, `progress.md`) | Модуль целиком = 1 документ. Функции не выделяются (`dump/index.go:loadBSLFiles`) |
| **D. Парсинг BSL** | tree-sitter (alkoleft/tree-sitter-bsl grammar `bsl.so`), fallback на regex. Извлекает: имя, тип, параметры, is\_export, body, calls (`tree_sitter_parser.py:120`) | Из кода не определить. Вход: .bsl + Form.bin + XML + TXT-отчёт | bsl-parser подключён (`libs.versions.toml:0.26.1`), интеграция **0%** | Нет AST-парсинга. `parseModuleName()` — только путь файла. Кастомный анализатор Bleve: unicode → lowercase → BSL-синонимы |
| **D. Метаданные XML** | `metadata_xml.py` — stdlib xml.etree. Поддерживает Catalogs/Documents/Registers/... + cfe/ | XML-выгрузка + TXT-отчёт конфигуратора + EventSubscriptions/*.xml + Predefined.xml | bsl-mdclasses (MDOReader): иерархия, роли, функц. опции, подписки (`MetadataExporterServiceImpl.kt`) | Не парсятся в open source. `formparser.go` — только структура форм |
| **D. ПодпискиНаСобытия** | Упомянуты как тип объекта (`metadata.py:40`), но рёбра НЕ строятся | Да: EventSubscription -HAS\_HANDLER-> Routine (`README.md:57`) | Да: EventSubscription как тип узла, рёбра через MetadataExporter | Нет |
| **E. Скорость** | ThreadPoolExecutor(8) для чанков (`vector_indexer.py:664`). Цифр в README нет | ~30 мин полная загрузка БУХ без эмбеддингов, +30 мин векторизация (`README.md:206`) | Конкретных цифр нет. Тяжёлый стек (Spring Boot + NebulaGraph) | ~7 сек для 13 000+ модулей (`README.md:73`). Параллельная сборка шардов + отключение GC |
| **E. Инкрементальность** | file\_tracker.db, hash-based. Есть function-level hash (`vector_indexer.py:473`) | FULL\_METADATA\_RELOAD=true — полная перезагрузка. Delta не упоминается | Из кода не определить | Manifest-based diff. Пересобирает только изменённые файлы (`dump/index.go:1119`) |
| **F. Расширения .epf/.erf** | Нет | Нет | Нет | Нет |
| **F. Расширения .cfe** | Да: `cfe/ExtName/` обходится как отдельный корень (`metadata_xml.py:421-427`) | Не упоминается | Нет | Платная версия (1 990 ₽/мес). В open source нет |
| **G. Лицензия** | **AGPL-3** ⚠️ Коммерциализация без открытия кода сервиса невозможна | Не указана. Закрытый Docker-образ | **MIT** ✅ | **MIT** ✅ |

---

## 2. Оценка по репозиториям

### bsl-atlas (наш upstream)

**Сильные стороны:**
- Единственный из открытых, кто реально извлекает функции через tree-sitter с fallback на regex
- Функциональный чанкинг с умными порогами (2000 символов, skip < 5 строк) — лучший чанкинг из всех четырёх
- Инкрементальность на уровне функций (function-hash), а не только файлов
- Поддерживает .cfe расширения в парсинге метаданных

**Слабые стороны:**
- **Лицензия AGPL-3 — критическая проблема для «Азимут»**. Форк под MIT невозможен без открытия кода сервиса.
- Граф вызовов поверхностный: callee хранится только как строка без резолва до модуля. Неразличимы одноимённые процедуры в разных модулях.
- Обход: только 1 уровень, нет рекурсии.
- Подписки на события: упомянуты, но рёбра не строятся — потеря важной связи для 1С.

---

### 1c-mcp-metacode

**Сильные стороны:**
- Единственный с **полноценным резолвом callee** до конкретного объекта метаданных (Routine узел в Neo4j)
- Многоуровневый обход (`call_graph_subtree`, `CALLS*1..N`) — это то, что нужно для глубокого анализа зависимостей
- Поддержка подписок на события (EventSubscription -HAS\_HANDLER-> Routine) и событий форм
- Богатая модель: 25+ типов узлов, полная иерархия метаданных с атрибутами

**Слабые стороны:**
- **Полностью закрытый исходный код** — форк или заимствование невозможны
- Тяжёлая инфраструктура: Neo4j требует отдельного процесса, 4 GB heap
- ~30 мин на загрузку БУХ (без эмбеддингов) — неприемлемо для разработческого сценария
- Неизвестна лицензия (образ закрытый)

---

### bsl-graph

**Сильные стороны:**
- MIT-лицензия
- bsl-mdclasses (Java-библиотека 1c-syntax) — проверенный парсер метаданных 1С, поддерживает всю иерархию
- Подписки на события реализованы через MetadataExporter
- Variable-length path в NebulaGraph (`[*1..maxDepth]`) — готовая инфраструктура для глубокого обхода метаданных

**Слабые стороны:**
- **BSL Parser интеграция: 0%.** Граф вызовов не реализован и не планируется в ближайшее время. MCP-поиск (`searchMetadata()`) полностью закомментирован.
- NebulaGraph — экзотическое хранилище, сложное в эксплуатации по сравнению с SQLite/Neo4j
- EdgeType не имеет CALLS — архитектура не предусматривает граф вызовов в текущей схеме
- Kotlin/Spring Boot — JVM-стек тяжелее Go/Python для встраивания

---

### mcp-1c

**Сильные стороны:**
- **Скорость: ~7 сек для 13 000+ модулей** — на порядки быстрее всех остальных
- Конкретные инженерные техники ускорения: отключение GC, FNV-шардирование, параллельная сборка, batch-индексация, дисковый кеш, манифест-diff
- Неблокирующий старт — MCP доступен сразу
- MIT-лицензия
- BSL-синонимный анализатор (рус↔англ, 40 ключевых слов + 180 функций) — отличная идея для поиска
- Готовая интеграция с живой 1С (метаданные, формы, запросы, журнал)

**Слабые стороны:**
- **Не граф.** Нет граф вызовов, нет зависимостей между модулями.
- Чанкинг на уровне модуля — грубо, без выделения функций. Низкое качество BM25-ранжирования для точечных запросов.
- Подписки на события, атрибуты, иерархия метаданных — не моделируются.
- Граф зависимостей и семантический поиск — только в закрытой платной версии.

---

## 3. Рекомендации: что заимствовать

### 3.1 Шардированная индексация (из mcp-1c) — **заимствовать сразу**

Техники сборки индекса для Азимут:

```go
// dump/shard.go:16
func shardCount(totalFiles int) int {
    n := totalFiles / 2000
    return max(1, min(runtime.NumCPU(), n))
}

// dump/index.go:buildShards()
debug.SetGCPercent(-1)          // отключить GC на время сборки
defer debug.SetGCPercent(100)

// Параллельная сборка шардов:
for i := range n {
    go func(shardID int) { ... buildShard(...) }(i)
}

// shard.go:51 — batch-индексация с unsafe_batch:
bleve.NewUsing(path, mapping, "scorch", "scorch", map[string]any{"unsafe_batch": true})
```

**Результат:** ~7 сек на 13k+ модулей vs ~30 мин у metacode. Эти приёмы применимы к нашему Bleve или любому другому движку.

### 3.2 BSL-синонимный анализатор (из mcp-1c) — **заимствовать**

```go
// dump/analyzer.go:65-152
// Двусторонняя карта: СтрНайти ↔ StrFind, Процедура ↔ Procedure, ...
// Pipeline: unicode tokenizer → lowercase → bsl_synonym filter
```

Это позволяет находить код по русским именам при поиске по английским и наоборот. Критично для разработчиков, которые смешивают термины.

### 3.3 Функциональный чанкинг (из bsl-atlas) — **заимствовать логику, переписать на Go**

```python
# vector_indexer.py:460-511
# function-level chunking:
# body <= 2000 chars → 1 chunk
# body > 2000 → RecursiveCharacterTextSplitter(chunk_size, chunk_overlap)
# skip functions < 5 lines
# metadata в чанке: имя функции, module_path, module_type, is_export, параметры
```

Но: нужен tree-sitter парсер или regex-парсер функций на Go. В mcp-1c AST-парсинга нет. Из bsl-atlas берём только **логику** (пороги, метаданные чанка), переписываем на Go без Python-зависимости.

### 3.4 Схема граф-резолва (из 1c-mcp-metacode) — **взять за архитектурный ориентир**

Принципиальная схема хранения вызовов (из README metacode):
```
Module -DECLARES-> Routine -CALLS-> Routine <-DECLARES- Module
                                       ↑
                              EventSubscription -HAS_HANDLER->
```

Callee должен быть **узлом**, не строкой. Только так возможен резолв через одноимённые процедуры.

Для SQLite это выглядит как:
```sql
CREATE TABLE routines (id, name, module_id, is_export, ...);
CREATE TABLE calls (caller_id REFERENCES routines, callee_id REFERENCES routines);
-- callee_id=NULL для неразрешённых вызовов (внешние модули, динамические вызовы)
```

bsl-atlas держит `callee_name TEXT` — это принципиально слабее, но проще для старта.

### 3.5 Подписки на события (из 1c-mcp-metacode и bsl-graph) — **реализовать**

Оба metacode (через DECLARES→HAS_HANDLER) и bsl-graph (через MetadataExporter + bsl-mdclasses) строят рёбра EventSubscription → обработчик. bsl-atlas это игнорирует.

Для Азимут: при парсинге XML-выгрузки конфигурации читать `EventSubscriptions/*.xml`, строить связи `ПодпискаНаСобытие.ИмяОбработчика → Модуль.Процедура`.

### 3.6 Инкрементальное обновление (из mcp-1c) — **заимствовать**

```go
// dump/index.go:1119 — loadFromManifestAndDiff()
// manifest.go — хранит хеши файлов
// Только изменённые файлы перестраиваются
```

bsl-atlas держит function-level hash (более точно), mcp-1c держит file-level manifest (проще). Для старта достаточно file-level.

---

## 4. Итоговые выводы

| Решение | Для Азимут |
|---------|-----------|
| **bsl-atlas** | Upstream нельзя форкать (AGPL-3). Берём только алгоритмы (чанкинг, пороги) — переписываем на Go. |
| **1c-mcp-metacode** | Закрытый код — не заимствуем. Используем как архитектурный эталон граф-резолва. |
| **bsl-graph** | MIT, но слишком сырой (BSL Parser 0%). Не заимствуем код, берём идею bsl-mdclasses для метаданных. |
| **mcp-1c** | MIT. Заимствуем: шардирование, BSL-синонимы, кеш, манифест-diff. Скоростные техники — обязательны. |

**Главный вывод:** ни один из открытых репозиториев не решает задачу комплексно. Азимут строит свой слой:
1. **Скорость индексации** — техники из mcp-1c
2. **Чанкинг на уровне функций** — логика из bsl-atlas, переписать на Go
3. **Граф вызовов** — схема из metacode (Routine-узлы, не строки), хранить в SQLite
4. **Подписки на события** — реализовать самостоятельно по образцу metacode/bsl-graph
5. **BSL-синонимы** — брать из mcp-1c напрямую (MIT, переиспользуем)
