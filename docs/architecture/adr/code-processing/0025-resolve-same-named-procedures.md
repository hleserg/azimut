---
status: proposed
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-414"
basis: "`_source/notion/hle-459-graph-analogs--36c0c905e62681a8b351c0b629af870e.md` (разбор metacode + bsl-graph); `_source/notion/hle-456-four-implementations--36c0c905e626817a9727ee1708e2d8c2.md` (SQLite-схема + вывод «алгоритм нашей инженерной задачи»)"
implemented-in: "`docs/architecture/05-building-block-view.md` §«Граф вызовов»; наш код (запланировано — открытая инженерная задача)"
related-to: "[0011](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md), [0024](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md), [0026](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/code-processing/0026-code-search-routing.md)"
supersedes: ""
superseded-by: ""
---

# Алгоритм резолва одноимённых процедур — открытая инженерная задача

> ⚠️ **`proposed` — алгоритм не написан.** Схема хранения зафиксирована (ниже). Сам алгоритм резолва — открытая инженерная задача: в открытом коде её не решил никто; готового решения мы не унаследуем. Утверждаем ADR вместе с реализацией при работе над темой 2 (HLE-414).

## Context and Problem Statement

В 1С разные модули могут содержать процедуры с одинаковыми именами: `ОбщийМодуль.ОбработатьДокумент` и `МодульОбъекта.ОбработатьДокумент` — это два разных объекта кода. Азимут (форк `bsl-atlas`) хранит граф вызовов в SQLite как `calls(caller_id, callee_name TEXT)` — плоская строка без квалификатора. При поиске «кто вызывает `ОбработатьДокумент`» граф не может различить, из какого модуля вызов. Агент получает смешанный список и может дать неверный ответ.

Research HLE-459 подтвердил: `1c-mcp-metacode` (Neo4j, закрытый) решил эту задачу (граф квалифицированных ссылок Routine → Module), но алгоритм резолва спрятан. `bsl-graph` (MIT, Kotlin) дошёл до метаданных, граф вызовов — в roadmap на «Этап 1». В открытом коде эту проблему не решил никто.

## Decision Drivers

* Приоритет №1 требует понимания цепочек вызовов; омонимия процедур делает граф непригодным для навигации.
* Не наследовать закрытый алгоритм metacode — только архитектурный ориентир (схема узлов/рёбер).
* Схема хранения должна быть зафиксирована сейчас, чтобы разблокировать ADR 0024 (чанкинг) и ADR 0026 (роутинг поиска).
* Алгоритм должен быть детерминированным — LLM для резолва недопустима (недетерминированность = галлюцинации в графе).

## Considered Options

* **`callee_name TEXT` (текущий bsl-atlas)** — плоская строка, омонимия не разрешается.
* **Квалифицированный `callee_id` в `calls`** — ссылка на resolved Routine-узел (`caller_id → callee_id`), `callee_id = NULL` для неразрешённых вызовов (внешние/динамические).
* **Граф в графовой БД (Neo4j/NebulaGraph)** — архитектурно избыточно для старта (SQLite + adjacency table тянет тот же объём).

## Decision Outcome

Chosen option: **«Квалифицированный `callee_id` в `calls`»**, because только resolved-ссылка на узел устраняет омонимию: квалификатор `OwnerType.OwnerName.ModuleType.RoutineName` однозначно идентифицирует процедуру. SQLite достаточно на старте; при добавлении кода (~50K Routine, ~500K CALLS) миграция на Neo4j оправдывается (Cypher ближе к metacode, документирован лучше NebulaGraph).

**Зафиксированная схема хранения** (из HLE-456, разблокирует реш. 2.2):

```sql
CREATE TABLE routines (
    id        INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,        -- имя процедуры/функции
    module_id INTEGER NOT NULL,     -- ссылка на модуль (квалификатор)
    is_export BOOLEAN NOT NULL,
    ...                             -- сигнатура, тип, позиция в файле
);

CREATE TABLE calls (
    caller_id INTEGER REFERENCES routines,
    callee_id INTEGER REFERENCES routines,  -- NULL для неразрешённых вызовов
    callee_name_raw TEXT                    -- исходная строка для отладки
);
```

`callee_id = NULL` — честная пометка «вызов есть, но резолв не удался» (внешний модуль, динамический вызов, `Выполнить(...)`) — лучше честного NULL, чем неверного resolved-ссылки.

**Алгоритм резолва — открытая инженерная задача:**

Схема зафиксирована (блокер снят). Сам алгоритм — как строить `callee_id` из `callee_name_raw` с учётом области видимости — не написан. Ориентиры из research:
- Эталон: `metacode` использует Cypher-запрос `resolve_qn` (qualified name → узел) + `find_routines_by_name`, алгоритм закрыт.
- Стартовая точка: `configuration.findChild(MdoReference)` из `bsl-graph` (MIT) — детерминированный lookup для метаданных; аналог нужен для BSL-вызовов через `bsl-parser`.
- Подписки на события: `EventSubscription → [HAS_HANDLER] → Routine` по образцу metacode — рёбра нужно достраивать сверх bsl-atlas (частичная слепая зона: тип `ПодпискаНаСобытие` индексируется, рёбра `событие → обработчик` отсутствуют).

### Consequences

* Good, because схема хранения зафиксирована → ADR 0024 (чанкинг) и ADR 0026 (роутинг) могут строиться на ней уже сейчас.
* Good, because `callee_id = NULL` — честная граница покрытия; агент знает «граф не полный» вместо «граф полный, но с ошибками».
* Bad, because алгоритм резолва не написан — это открытый инженерный риск; ADR 0026 (роутинг graph→metadata→grep) полноценно заработает только когда резолв будет реализован.
* Bad, because подписки на события требуют дополнительного разбора XML (`EventSubscriptions/*.xml`) поверх того, что есть в bsl-atlas.

### Confirmation

ADR переходит в `accepted` когда:
1. Реализован алгоритм резолва и покрыт тестами на реальном корпусе ERP.
2. `calls.callee_id` заполнен > 80% вызовов (остаток — честные NULL для внешних/динамических).
3. Рёбра `ПодпискаНаСобытие → Routine` строятся для именованных обработчиков.

## Pros and Cons of the Options

### Квалифицированный `callee_id` (выбрано — схема)

* Good, because однозначно идентифицирует процедуру в любом модуле.
* Good, because `NULL` — честный маркер нераспознанных вызовов.
* Bad, because алгоритм резолва — наша инженерная задача, готового в открытом коде нет.

### `callee_name TEXT` (текущий bsl-atlas)

* Good, because уже работает, ноль новой реализации.
* Bad, because омонимия не разрешается → граф бесполезен для навигации по сложным модулям.

### Граф в GraphDB (Neo4j) с самого старта

* Good, because Cypher мощнее SQLite для многоуровневого обхода.
* Bad, because архитектурно преждевременно: metacode с Neo4j стартует 30 мин на БУХ без эмбеддингов, 4GB heap — слишком тяжело для «мама не ставит лишнее». SQLite → Neo4j миграция — естественный следующий шаг.

## More Information

* `_source/notion/hle-459-graph-analogs--*.md` — детальный разбор metacode (Neo4j, закрытый) и bsl-graph (Kotlin, MIT). Вывод: в открытом коде резолв одноимённых не решён ни у кого.
* `_source/notion/hle-456-four-implementations--*.md` — SQLite-схема `routines` + `calls(caller_id, callee_id)` как стартовый каркас; вывод «HLE-456 снял неопределённость по схеме хранения».
* ADR 0024 — детерминированный чанкинг (резолв влияет на граф вызовов, не на резку).
* ADR 0026 — роутинг поиска graph → metadata → grep; graph-ветвь полноценно заработает только после реализации резолва.
* Хранилище двухфазно: старт на SQLite (метаданные + BFS по коду) → миграция на Neo4j при подключении кода (~50K Routine, ~500K CALLS).
