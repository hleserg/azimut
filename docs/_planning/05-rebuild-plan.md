# 05 — Карта переноса и список ADR (план пересборки документации)

> Задача Linear: [HLE-495](https://linear.app/hleserg/issue/HLE-495).
>
> **Что это.** План перехода от сырой выгрузки в [`docs/_source/`](../_source/) к настоящей документации в `docs/`. После утверждения Сергеем этот документ становится управляющим для всех дальнейших задач: каждый кусок источников знает свой целевой документ или ADR, каждый ADR знает своё место в архитектуре.
>
> **Предусловия (выполнены).** [HLE-494](https://linear.app/hleserg/issue/HLE-494) Done; [`_source/_crosscheck.md`](../_source/_crosscheck.md) заполнен; [`_source/_resolutions.md`](../_source/_resolutions.md) применён; методичка [`_source/specs/_howto.md`](../_source/specs/_howto.md) на месте.
>
> **Источник истины** — `docs/_source/` (зафиксировано в `_resolutions.md`). Notion/Linear не пересинхронизируются.

## Содержание

1. [Целевое дерево `docs/`](#1-целевое-дерево-docs)
2. [Карта переноса (источник → целевой документ/ADR)](#2-карта-переноса-источник--целевой-документадр)
3. [Список ADR с шапками](#3-список-adr-с-шапками)
4. [Сводка для отчёта в Linear](#4-сводка-для-отчёта-в-linear)

---

## 1. Целевое дерево `docs/`

Структура опирается на [`_source/specs/_howto.md`](../_source/specs/_howto.md): arc42 (выборочные секции 1/3/4/5/6/8/9/12), MADR для ADR, C4 (Context + Container обязательно, Component точечно), Mermaid для всех диаграмм.

```
docs/
├── index.md                                # arc42 §1 Introduction & Goals + §4 Solution Strategy
│                                           # + точка входа со схемой-картой документов и кратким индексом ADR
├── architecture/
│   ├── 01-context.md                       # arc42 §3 Context and Scope + C4 Level 1 (System Context)
│   ├── 02-containers.md                    # arc42 §5 Building Block View + C4 Level 2 (Container);
│   │                                       # отдельные C4 Component поддиаграммы — только для нетривиальных
│   │                                       # контейнеров (Азимут-ядро, поисковый стек) внутри файла
│   ├── 03-pipelines.md                     # arc42 §6 Runtime View — Mermaid sequenceDiagram по сценариям:
│   │                                       # индексация, запрос, обновление, фолбэк (Р7), судья (Р3)
│   ├── 04-blind-spots.md                   # arc42 §11 Risks & Technical Debt — слепые зоны bsl-atlas
│   │                                       # (подписки/асинхрон/.epf/.erf/МенеджерВременныхТаблиц),
│   │                                       # граница «доказуемо статически vs runtime»
│   └── 05-crosscutting.md                  # arc42 §8 Crosscutting Concepts — анти-галлюцинации (Р1–Р7,
│                                           # П1–П3), мониторинг/канарейка, безопасность/приватность,
│                                           # лицензии/AGPL §13, правило источников (реш. 1.10)
├── decisions/                              # arc42 §9 — каталог MADR-ADR; локальный индекс в README
│   ├── README.md                           # индекс ADR с фильтрами по теме/статусу
│   ├── 0001-р1-metric-contradiction.md
│   ├── …                                   # см. раздел 3 этого документа
│   └── 0033-r1-contradiction-detection-mechanics.md
├── glossary.md                             # arc42 §12 — термины 1С, проектные, технические (ISCF, BSL,
│                                           # АГРЕГАТ, ПодпискаНаСобытие, МенеджерВременныхТаблиц, RRF,
│                                           # Self-RAG, Faithfulness, BGE-M3, Cohere, AGPL §13, FastMCP, …)
├── cases/                                  # эталонные кейсы (для eval и поведенческого контракта)
│   └── 01-document-changed-account.md      # «почему документ сменил счёт» — 3 слоя (см. _resolutions.md #6)
└── roadmap.md                              # фазы со ссылками на HLE-XXX: тема 1→2→3→4→5→6→7;
                                            # перечень открытых рисков (дымовой прогон, резолв одноимённых,
                                            # Sentry × AGPL)
```

**Что НЕ создаём сейчас (явно):**

- `architecture/07-deployment.md` — arc42 §7 (Deployment View) не нужен до темы 7 (HLE-419). Когда дойдём — добавим.
- `architecture/06-quality.md` — arc42 §10 (Quality) появится при работе над темой 6 (HLE-418, eval/метрики).
- C4 Level 3 (Component) — только если внутри контейнера >2-3 нетривиальных компонента (правило из `_howto.md` §2). Под кандидатами: Азимут-ядро (граф+чанкер+эмбеддер) и MCP-оркестратор (Р5+Р6+судья). Решаем при написании `02-containers.md`.
- C4 Level 4 (Code), System Landscape, Dynamic — `_howto.md` явно говорит «не делаем».

**Где лежит arc42 §4 (Solution Strategy).** В `index.md`. По `_howto.md` секция жирёт в «главный документ» — у нас это `index.md` (точка входа + intro + strategy + карта).

---

## 2. Карта переноса (источник → целевой документ/ADR)

**Цель таблицы — 100 % покрытие.** Каждая страница в `_source/notion/`, каждый issue в `_source/linear/`, все вложения и сырые служебные файлы — учтены.

Колонки:
- **Источник** — путь в `_source/`.
- **Куда** — целевой документ в `docs/` (или «остаётся в `_source/` как архив» / «ADR NNNN»).
- **Тип** — `arc42` / `ADR` / `case` / `glossary` / `roadmap` / `archive` / `meta`.
- **Примечание** — что переносим/чем подкрепляем, особые оговорки.

### 2.1 Notion (17 страниц)

| Источник в `_source/notion/` | Куда | Тип | Примечание |
|---|---|---|---|
| `hub-1c-assistent--*.md` | `index.md` (§1 Introduction & Goals) + `glossary.md` | arc42 + glossary | Назначение системы (агент-консультант для Сергея/мамы), базовый стек, цели качества. Хаб уже обновлён под текущие реш. 1.7a/1.8 (`_resolutions.md` #5) — переносим как актуальный. |
| `decisions--*.md` | ADR 0001–0010 (Р1–Р7 + П1–П3) + `architecture/05-crosscutting.md` | ADR + arc42 | Прямой исходник для 9 принятых/предложенных ADR анти-галлюцинаций. Р4 → отдельный ADR со `status: superseded by 0007`. Термины («ретривер», «агент-генератор», «MCP-сервер») → `glossary.md`. |
| `runbook--*.md` | `architecture/05-crosscutting.md` (§«Операционный регламент») + ссылка из `index.md` | arc42 | Операционное руководство для руководителя (как запускать/обновлять/диагностировать). Контент логически = crosscutting concern, отдельный документ `operations/runbook.md` пока не делаем — материал умещается в раздел crosscutting. Если разрастётся при работе над темой 6 (HLE-418, наблюдаемость/регламент) — выделим. |
| `design-system-v2--*.md` | ADR 0011–0023 + `index.md` (§4 Solution Strategy) + `architecture/02-containers.md` + `architecture/05-crosscutting.md` | ADR + arc42 | Главный исходник по фундаменту (тема 1). Все реш. 1.1–1.10 + 1.7a + 1.8a + Название «Азимут» → отдельные ADR. Раздел «Что НЕ меняется» → `index.md` (наследие v1.1). Раздел «📂 Что bsl-atlas реально делает» → `architecture/04-blind-spots.md` + ADR 0024 (чанкинг). Реестр доноров → `architecture/02-containers.md` (раздел «Compositional choices»). Журнал решений по темам 3–7 (пока пустые) → пропускаем, наполнится при HLE-415..419. |
| `solutions-registry-summary--*.md` | `roadmap.md` + `index.md` (индекс ADR со статусами) + ADR 0027 (Реш. 2.4) | roadmap + ADR | Оценки 1–10 → `roadmap.md` как «вес» решений и перечень открытых рисков (дымовой прогон, резолв одноимённых, Sentry × AGPL). «Три действия перед ТЗ» — действия 1 (FSerg-лицензия) и 2 (дубли HLE-460/464) выполнены в `_resolutions.md` #3/#4; действие 3 (реш. 2.4 «Go → Python») закреплено отдельным ADR 0027. |
| `questions--*.md` | `cases/01-document-changed-account.md` + ADR 0028–0033 (открытые) + `architecture/05-crosscutting.md` (мульти-аренда) | case + ADR | Эталонный кейс «почему документ сменил счёт» (3 слоя по `_resolutions.md` #6) → `cases/`. Раздел мульти-аренды (4 развилки из `_resolutions.md` #9) → 4 отдельных open-ADR (0029–0032). Открытые хвосты Р1 (метрика противоречивости) → ADR 0033 со `status: proposed`. Раздел про ISCF — см. отдельный пункт ниже. **Раздел про устное разрешение лицензии bsl-atlas уже удалён** (`_resolutions.md` #1) — переносить нечего. |
| `iscf-analysis--*.md` | `architecture/02-containers.md` (раздел «Приём ИТС») + `glossary.md` (ISCF, Data.cab, Data.dir, CFHD) | arc42 + glossary | Целевой документ темы 4 (HLE-416) пока не существует — материал ИТС пойдёт частью в `02-containers.md` (где описаны pipeline-контейнеры), частью в глоссарий. Когда будет писаться тема 4 — основной материал переедет в её документ; до тех пор живёт в общей архитектуре. |
| `researches--*.md` | `_source/` (архив, не мигрируем) + `roadmap.md` (ссылкой) | archive | Контент уже растащен по другим страницам (см. `_crosscheck.md` «что пропущено и почему»). File-attachment `RAG_dlya_1C_ERP_obzor.md` Notion MCP не качал — потери для решений не выявлено. В `roadmap.md` — ссылка как «история исследований». |
| `bsl-atlas-opensource-research--*.md` | `architecture/02-containers.md` (реестр компонентов) + `architecture/04-blind-spots.md` (пробелы) + `roadmap.md` | arc42 + roadmap | Систематический обзор «10 пробелов и кандидатов». В `02-containers.md` — состав готовых компонентов с ролями; в `04-blind-spots.md` — пробелы (асинхрон, мульти-аренда — Пробел 9); в `roadmap.md` — фазовое внедрение. |
| `hle-456-four-implementations--*.md` | ADR 0024 (чанкинг — раздел «факты из bsl-atlas») + ADR 0027 (Реш. 2.4 — портирование feenlace в Python) + `architecture/02-containers.md` (сравнительная таблица) | ADR + arc42 | Прямой источник реш. 2.4 (`_resolutions.md` #2 переформулировал на Python). Реестр доноров (feenlace, метаcode, bsl-graph) и сравнение по 5 осям → подкрепляет 0024/0027 и раздел «реестр доноров» в `architecture/02-containers.md`. |
| `hle-459-graph-analogs--*.md` | ADR 0025 (резолв одноимённых) + `architecture/02-containers.md` (раздел «Граф вызовов») | ADR + arc42 | Главный источник реш. 2.2: «резолв одноимённых = открытый алгоритм, схема зафиксирована». ADR 0025 статус `proposed` — алгоритм ещё не написан. |
| `hle-461-search-routing--*.md` | ADR 0026 (роутинг поиска: graph → metadata → grep) + `architecture/02-containers.md` (диспетчер MCP) + `architecture/03-pipelines.md` (runtime-сценарий «Запрос по коду») | ADR + arc42 | Реш. 2.3. ADR 0026 статус `proposed` (требует утверждения Сергеем при работе над темой 2). |
| `hle-463-bsl-ls-wrappers--*.md` | `architecture/02-containers.md` (раздел реестра доноров) + `glossary.md` (BSL entry-points) + ADR 0011 (Реш. 1.1) как референс | arc42 + glossary | Сам факт «BSL LS отложить, для v1 берём tree-sitter» — это поддержка ADR 0011/0024. 25+ BSL entry-points (`ПриЗаписи`, `ПриПроведении`, …) → отдельный справочник в `glossary.md` (или отдельный файл `glossary/bsl-entry-points.md` если разрастётся). |
| `hle-457-prompt-engineering-xml--*.md` | `architecture/05-crosscutting.md` (раздел «Промт-инжиниринг») + `glossary.md` (типы объектов 1С) | arc42 + glossary | Выводы cc-1c-skills для темы 5. Конкретный системный промпт появится в теме 5 (HLE-417); сейчас идёт фактура (абстракции XML, тэгирование `<config>`/`<query>`). |
| `hle-460-fserg-chunking-qdrant--*.md` | ADR 0024 (чанкинг — payload-схема Qdrant) + `architecture/02-containers.md` (раздел «Хранилище») | ADR + arc42 | Идеи payload-схемы и RRF-слияния. Архитектурно код не переиспользуется (см. ADR 0014 / Реш. 1.3); берём только лекало. |
| `hle-464-runtime-live-1c--*.md` | `architecture/04-blind-spots.md` (раздел «runtime-данные») + ADR 0029–0032 (мульти-аренда) + `cases/01-document-changed-account.md` (2-й и 3-й слой кейса) | arc42 + ADR + case | 5 репо runtime-доступа к живой 1С. Классификация А/Б → в blind-spots (что доказуемо статически vs только через 1c_mcp). `1c-mcp-toolkit` (anti-pattern, лицензии нет) → негативный реестр в `architecture/05-crosscutting.md`. |
| `hle-458-mini-ai-1c-competitors--*.md` | `architecture/02-containers.md` (реестр инструментов) + ADR 0018/0019 (клиент по ролям) | arc42 + ADR | mini-ai-1c как клиент для Сергея (захват кода из Конфигуратора) — поддержка ADR 0019 (Реш. 1.7a). 1c-buddy / EDT-MCP — в реестр компонентов как референсы. |

### 2.2 Linear — проект «Переписываем ТЗ» (16 issue + вложения)

| Источник в `_source/linear/perepisyvaem-tz/` | Куда | Тип | Примечание |
|---|---|---|---|
| `HLE-413.md` (тема 1 — фундамент, Done) | `roadmap.md` (фаза 1) + ADR 0011–0023 (как basis) | roadmap + ADR | Чат Сергея, на основе которого синтезирован раздел «Тема 1» в design-system-v2. Все ADR фундамента ссылаются на HLE-413 в поле `basis:`. Inline-пометка «MIT, см. реш. 1.3/1.10» уже добавлена (`_resolutions.md` #3). |
| `HLE-414.md` (тема 2 — обработка кода) | `roadmap.md` (фаза 2) + ADR 0024–0027 (basis) | roadmap + ADR | Чат темы 2. Дочерние HLE-456..464 — конкретные исследования. ADR 0024–0027 ссылаются на HLE-414 в `basis:`. |
| `HLE-415.md` (тема 3 — поисковый стек, Backlog) | `roadmap.md` (фаза 3, placeholder) | roadmap | Решения темы 3 ещё не приняты. ADR появятся при работе над HLE-415; в `roadmap.md` — placeholder с известными переменными (BGE-M3, RRF, Cohere Rerank, Self-RAG, long-context vs RAG). |
| `HLE-416.md` (тема 4 — приём документации, Backlog) | `roadmap.md` (фаза 4, placeholder) | roadmap | Заделка под ISCF/OCR/мультимодал. См. также `iscf-analysis--*.md` — фактура есть, решений пока нет. |
| `HLE-417.md` (тема 5 — анти-галлюцинации и контракт, Backlog) | `roadmap.md` (фаза 5, placeholder) + ADR 0033 (метрика противоречивости — basis) | roadmap + ADR | Закрытие открытого хвоста Р1 запланировано здесь (`_resolutions.md` #11). |
| `HLE-418.md` (тема 6 — eval и метрики, Backlog) | `roadmap.md` (фаза 6, placeholder) | roadmap | Закрепление RAGAS-харнесса, faithfulness/correctness, Langfuse/Sentry. |
| `HLE-419.md` (тема 7 — онлайн-деплой и мульти-аренда, Backlog) | `roadmap.md` (фаза 7, placeholder) + ADR 0028–0032 (basis) | roadmap + ADR | 5 открытых ADR (Sentry × AGPL + 4 развилки мульти-аренды) формально привязаны к HLE-419. |
| `HLE-456.md` + `attachments/HLE-456/{result,notes}-HLE-456.md` | ADR 0024/0027 (basis) + `architecture/02-containers.md` (сравнительная таблица 4 реализаций) | ADR + arc42 | Вложения = первичные отчёты сравнения, синтез лёг в `hle-456-four-implementations.md`. В ADR ссылка идёт на сводную Notion-страницу + на attachments как первоисточник. |
| `HLE-457.md` + `attachments/HLE-457/*` | `architecture/05-crosscutting.md` (промт-инжиниринг) + `glossary.md` | arc42 + glossary | Аналогично HLE-456 — синтез в Notion `hle-457-prompt-engineering-xml.md`. |
| `HLE-458.md` + `attachments/HLE-458/*` | `architecture/02-containers.md` (реестр клиентов/MCP) | arc42 | Синтез в `hle-458-mini-ai-1c-competitors.md`. |
| `HLE-459.md` + `attachments/HLE-459/*` | ADR 0025 (basis) + `architecture/02-containers.md` (граф) | ADR + arc42 | Синтез в `hle-459-graph-analogs.md`. |
| `HLE-460.md` + `attachments/HLE-460/*` | ADR 0024 (basis для payload-схемы) + ADR 0014 (basis для «MIT, идеи берём, код нет») | ADR | Синтез в `hle-460-fserg-chunking-qdrant.md`. |
| `HLE-461.md` + `attachments/HLE-461/*` | ADR 0026 (basis) + `architecture/02-containers.md` (диспетчер) | ADR + arc42 | Синтез в `hle-461-search-routing.md`. |
| `HLE-462.md` (Backlog — onec-help-mcp, гибрид BM25+вектор) | `roadmap.md` (фаза 3, отложен) | roadmap | Дочерний к HLE-415 (тема 3). Решение по гибриду BM25+вектор примем в теме 3. Сейчас — placeholder. |
| `HLE-463.md` + `attachments/HLE-463/*` | `architecture/02-containers.md` (реестр доноров) + `glossary.md` (BSL entry-points) | arc42 + glossary | Синтез в `hle-463-bsl-ls-wrappers.md`. |
| `HLE-464.md` + `attachments/HLE-464/*` | `architecture/04-blind-spots.md` + ADR 0029–0032 (basis) + `cases/01-document-changed-account.md` | arc42 + ADR + case | Синтез в `hle-464-runtime-live-1c.md`. |

### 2.3 Linear — проект «Агент-консультант по 1С ERP» (45 issue, групповой перенос)

Это **старая декомпозиция v1.x** до перехода на v2.0. Перенос — групповой с точечными исключениями.

| Группа источников в `_source/linear/agent-konsultant-po-1s-erp/` | Куда | Тип | Примечание |
|---|---|---|---|
| HLE-292, 295, 297–312 (1.x декомпозиция: каркас, ADR-стек, парсер XML, индексатор, поисковый слой, MCP-сервер, контракт, CLI, BGE-менеджер, онбординг, эксперименты, судья, Cohere-адаптеры, упаковка, мониторинг релизов, живые процедуры, ежемесячное обновление) | `roadmap.md` (раздел «Архив v1.x: старая декомпозиция») | archive | Не мигрируем дословно — декомпозиция v1.x пересобирается заново исходя из решений v2.0 (форк bsl-atlas + готовые библиотеки + конкурентное ядро). В roadmap.md — ссылка как «исторический контекст» с одной фразой про каждый issue. При работе над фазами v2.0 — сверяться, чтобы не упустить требования (например, healthcheck папки из HLE-337, get_procedure из HLE-311). |
| HLE-313, 316, 317, 318, 319 (bootstrap — In Progress: репо/CI/Devin-ревьювер, реальные данные, cc-1c-skills, Sentry workflow, Sentry-ревью) | `architecture/05-crosscutting.md` (мониторинг/инструментация) + ADR 0028 (Sentry × AGPL — basis) + `roadmap.md` (фаза 0) | arc42 + ADR | Bootstrap-задачи реально влияют на crosscutting (Sentry, логирование, репо-структура). Из HLE-317 (cc-1c-skills) фактура уже растащена в `hle-457-prompt-engineering-xml.md`. HLE-318/319 (Sentry workflow) — переориентируются по результату ADR 0028. |
| HLE-314 (Sentry-грант — Done) | ADR 0028 (basis: история согласования) | ADR | Done со ссылкой на исходное согласование гранта; теперь конфликтует с AGPL — см. ADR 0028. |
| HLE-315 (Sentry-инструментация — In Progress) | `architecture/05-crosscutting.md` (мониторинг) | arc42 | Технически не отменена; зависит от ADR 0028 (если план Б — мигрирует на GlitchTip/self-host). |
| HLE-320 (repo-template — In Progress) | `roadmap.md` (фаза 0) | roadmap | Шаблон репо для будущих проектов — не часть этого ТЗ напрямую, упоминание в roadmap как параллельная инициатива. |
| HLE-321, 322, 323 (agent-playbook — Backlog/In Progress) | `roadmap.md` (фаза 0) | roadmap | Изучение agent-playbook и перенос полезного в правила проекта. Фактура для CLAUDE.md / правил агентов; в архитектуру и ADR напрямую не входит. |
| HLE-324 (adapter-агностичная архитектура MCP + install() — Backlog) | `architecture/02-containers.md` (раздел адаптеров) + ADR 0020 (Реш. 1.8 — basis) | arc42 + ADR | Тема адаптера уже учтена в Реш. 1.8 (адаптер к разговорной модели в фундаменте); HLE-324 — конкретизация для install(). |
| HLE-332, 333, 334, 335 (Canceled — Document Registry, парсер личных документов, адаптивный контекст, семантический кеш) | `_source/` (отметка «отменены»; не переносим) | archive | Явно Canceled. Дубликаты в HLE-336, 337, 338, 339 (Backlog) — содержательные требования уже там. |
| HLE-336, 337, 338, 339, 340 (1a/3a/11a/6a/4a — пересобранная декомпозиция: Document Registry, парсер личных документов, адаптивный контекст, семантический кеш, PII-фильтр) | `roadmap.md` (раздел «Архив v1.x: пересобранная декомпозиция») | archive | Параллельный набор задач, который тоже отомрёт при v2.0-пересборке. PII-фильтр (HLE-340) → попадёт в `architecture/05-crosscutting.md` (приватность). |
| HLE-341..346 (КТ1..КТ6 — контрольные точки приёмки v1.x) | `_source/` (архив) | archive | Контрольные точки v1.x. Аналоги для v2.0 будут перепроектированы при работе над фазами. |

**Итог по группе:** все 45 issue учтены. Большая часть → `roadmap.md` как «исторический контекст». Те, что содержательно работают (bootstrap, инструментация, adapter-агностика) → точечно в `architecture/05-crosscutting.md` или basis-ссылки в ADR. Canceled — отметка «архив», не переносим.

### 2.4 Linear-вложения, проектные документы и служебные файлы

| Источник | Куда | Тип | Примечание |
|---|---|---|---|
| `_source/linear/_manifest.json`, `_projects.json` | `_source/` (остаётся) | meta | Манифесты выгрузки; пути к файлам и метаданные. Не мигрируем — это служебный индекс. |
| `_source/linear/attachments/HLE-{456..464}/{result,notes}-HLE-NNN.md` | basis-ссылки в соответствующих ADR + поддержка `architecture/*` | ADR + arc42 | Уже учтены в строках 2.2 рядом со своими issue. |
| `_source/linear/attachments/_project-docs/_project2_description.md` | `index.md` (§1 — целевые пользователи, контекст) | arc42 | Полное описание проекта «Переписываем ТЗ» — справочный материал, частично перекрывается с `hub-1c-assistent.md`. |
| `_source/linear/attachments/_project-docs/agent-konsultant-po-1s-erp-polnoe-opisanie-proekta.md` | `roadmap.md` (раздел «Архив v1.x») | archive | Полное описание проекта v1.x — переносим только как исторический контекст. |
| `_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md` | `roadmap.md` + проверка на потери при сверке с design-system-v2 | archive | Карта задач v1.x — справочно. Сверить с design-system-v2, чтобы не упустить требования. **Флаг для Сергея:** проверить, нет ли тут архитектурных решений, не отражённых в design-system-v2 (см. секцию «Флаги» ниже). |
| `_source/linear/attachments/_project-docs/tasks-polnaya-karta-zadach-i-zavisimostej.md` | `roadmap.md` (раздел «Архив v1.x») | archive | Граф задач v1.x с зависимостями. Справочно. |

### 2.5 Спецификации и meta-документация

| Источник | Куда | Тип | Примечание |
|---|---|---|---|
| `_source/specs/_howto.md` | `_source/specs/` (остаётся) | meta | Методичка — вход для проектирования, а не контент. **Не мигрируется.** Ссылка из `index.md`: «как написана документация — см. `_source/specs/_howto.md`». |
| `_source/specs/_links.md` | `_source/specs/` (остаётся) | meta | Индекс ссылок на источники спек. Не мигрируется. |
| `_source/specs/arc42/`, `c4/`, `madr/`, `mermaid/` | `_source/specs/` (остаётся) | meta | Скачанные канонические спецификации. Не мигрируются. Используются как референс при написании документов. |
| `_source/_crosscheck.md` | `_source/` (остаётся) | meta | Летопись сверки HLE-494. Не мигрируется. |
| `_source/_resolutions.md` | `_source/` (остаётся) | meta | Летопись применённых решений HLE-494. Не мигрируется. |
| `_source/notion/_manifest.json` | `_source/` (остаётся) | meta | Манифест Notion-выгрузки. Не мигрируется. |
| Корневые `LICENSE` (AGPL-3.0), `COPYRIGHT` | Корень репо (без изменений) | meta | Не относится к `docs/`. Упоминается в `architecture/05-crosscutting.md` (раздел «Лицензии»). |

### 2.6 Флаги (что обсудить с Сергеем перед утверждением)

1. **`karta-zadach-i-arhitekturnye-resheniya-aktualno.md`** в `_project-docs/` — сверять с `design-system-v2.md` перед архивированием. Возможно, там есть архитектурные решения, которые не попали в синтез v2.0. Не блокер плана, но при сверке (отдельный шаг при заполнении фаз roadmap) надо просмотреть.
2. **Темы 3–7 — пустые в design-system-v2 («🔲 ожидает обсуждения»).** При работе над HLE-415..419 будут возникать новые ADR. Сейчас в плане учтены только placeholders в `roadmap.md` + 5 open-ADR (Sentry, мульти-аренда). При утверждении плана это нормально — план фиксирует точку Т0, дальнейшие ADR — итеративно.
3. **Дочерние Notion-страницы по темам 3–7** в Notion-хабе НЕТ (в выгрузке только страницы по фундаменту и теме 2). Если Сергей в будущем заведёт новые страницы — карту переноса дополнить.
4. **`researches.md` file-attachment `RAG_dlya_1C_ERP_obzor.md`** не выгружен (Notion MCP не качает бинарники). По `_crosscheck.md` потерь решений нет, но если когда-нибудь понадобится — придётся качать руками.

---

## 3. Список ADR с шапками

**Нумерация.** Сквозная по всем темам, 4 разряда (`NNNN`). Сейчас фиксируем 33 ADR (`0001`–`0033`); при работе над темами 3–7 нумерация продолжится с 0034.

**Файл и имя.** `docs/decisions/NNNN-kebab-case-title.md`. Подпапки внутри `decisions/` пока **не делаем** — 33 ADR в плоском списке читаются нормально; делим, если перевалит за ~50–60.

**Поля шапки.** По `_howto.md` §3 + маппинг полей из HLE-493:
- `status` — `proposed` / `accepted` / `rejected` / `deprecated` / `superseded by NNNN`
- `date` — дата принятия (для accepted) или открытия (для proposed)
- `decision-makers` — обычно `[Сергей]`, для предложенных П1/П2/П3 — Сергей + согласование с агентом-консультантом
- `linear-task` — задача Linear, в рамках которой принято
- `basis` — на чём основано (HLE-XXX, файл в `_source/`)
- `implemented-in` — компонент архитектуры (контейнер C4 или модуль): для решений уровня дизайна — `index.md §4` или ссылка на раздел `architecture/`
- `related-to` — связанные ADR
- `supersedes` / `superseded-by` — где применимо

### 3.1 Анти-галлюцинации и поведенческий контракт (фон)

#### `0001-р1-metric-contradiction.md`
- **status:** `accepted` (с открытым подвопросом — см. ADR 0033)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** [`_source/notion/decisions--*.md`](../_source/notion/decisions--36b0c905e62681019228dfcc7ec2a1cb.md) Р1
- **implemented-in:** `architecture/05-crosscutting.md` §«Метрика противоречивости»; реализация — MCP-сервер (контроль ретривинга, Р5)
- **related-to:** [0006 (Р6 — иерархия источников)](#0006-р6-source-hierarchy), [0033 (механика детектирования)](#0033-r1-contradiction-detection-mechanics)
- **Заголовок:** Метрика противоречивости источников ПЕРЕД выдачей

#### `0002-р2-faithfulness-vs-relevance.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-418 (тема 6)
- **basis:** `_source/notion/decisions--*.md` Р2
- **implemented-in:** `architecture/05-crosscutting.md` §«Метрики качества»; реализация — eval-харнесс (RAGAS) + LLM-судья
- **related-to:** [0003 (Р3)](#0003-р3-llm-judge-spans), [0008 (П1)](#0008-п1-groundedness-detector)
- **Заголовок:** Faithfulness и relevance ретривера — разные метрики

#### `0003-р3-llm-judge-spans.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5) + HLE-306 (LLM-судья из v1.x)
- **basis:** `_source/notion/decisions--*.md` Р3
- **implemented-in:** `architecture/02-containers.md` §«LLM-судья» (отдельный контейнер); `architecture/03-pipelines.md` §«Запрос → судья»
- **related-to:** [0002 (Р2)](#0002-р2-faithfulness-vs-relevance), [0008 (П1)](#0008-п1-groundedness-detector)
- **Заголовок:** LLM-судья со спан-привязкой (Claude как арбитр)

#### `0004-р4-honest-deadend-retired.md`
- **status:** `superseded by 0007`
- **date:** 2026-05-25 (открыт) → 2026-05-26 (снят)
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` (явная пометка «Р4 снят 2026-05-26 — заменён на Р7»)
- **implemented-in:** —
- **superseded-by:** 0007
- **related-to:** [0007 (Р7)](#0007-р7-fallback-mode-switch)
- **Заголовок:** «Честный тупик» как фолбэк (снято)
- **Примечание:** короткий ADR-надгробие, чтобы при чтении decisions/ было видно, что Р4 не «потерялся». Тело: «Р4 предлагал «не нашёл — честно ответь не знаю». Признан недостаточным: пользователь остаётся без помощи. Заменён на Р7 (фолбэк = смена режима, дип-ресёрч с тем же контрактом).»

#### `0005-р5-server-controlled-retrieval.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5) + HLE-299 (поисковый слой из v1.x)
- **basis:** `_source/notion/decisions--*.md` Р5
- **implemented-in:** `architecture/02-containers.md` §«MCP-сервер: контроль ретривинга»; `architecture/03-pipelines.md` §«Запрос → добор → ответ»
- **related-to:** [0006 (Р6)](#0006-р6-source-hierarchy), [0009 (П2)](#0009-п2-re-retrieval)
- **Заголовок:** Контроль ретривинга — на сервере (планка релевантности, триггер добора, потолок окна)

#### `0006-р6-source-hierarchy.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` Р6
- **implemented-in:** `architecture/02-containers.md` §«MCP-сервер: иерархия источников»; `architecture/05-crosscutting.md`
- **related-to:** [0001 (Р1)](#0001-р1-metric-contradiction), [0005 (Р5)](#0005-р5-server-controlled-retrieval)
- **Заголовок:** Иерархия источников при конфликте: код → справка → ИТС

#### `0007-р7-fallback-mode-switch.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` Р7
- **implemented-in:** `architecture/03-pipelines.md` §«Фолбэк-сценарий: дип-ресёрч»
- **supersedes:** 0004
- **related-to:** [0004 (Р4 — снят)](#0004-р4-honest-deadend-retired)
- **Заголовок:** Фолбэк = смена режима (дип-ресёрч в интернете с тем же контрактом)

#### `0008-п1-groundedness-detector.md`
- **status:** `proposed`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` П1
- **implemented-in:** `architecture/02-containers.md` §«LLM-судья» (3 уровня действий)
- **related-to:** [0003 (Р3)](#0003-р3-llm-judge-spans), [0002 (Р2)](#0002-р2-faithfulness-vs-relevance)
- **Заголовок:** Детектор «relevance высокий / groundedness низкий» — 3 уровня действий

#### `0009-п2-re-retrieval.md`
- **status:** `proposed`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` П2
- **implemented-in:** `architecture/02-containers.md` §«MCP-сервер: повторный ретривинг»; `architecture/03-pipelines.md`
- **related-to:** [0005 (Р5)](#0005-р5-server-controlled-retrieval)
- **Заголовок:** Второй проход ретривера при неуверенности (открытый триггер)

#### `0010-п3-query-sufficiency.md`
- **status:** `proposed`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` П3
- **implemented-in:** `architecture/02-containers.md` §«MCP-сервер: оценка запроса»
- **related-to:** [0005 (Р5)](#0005-р5-server-controlled-retrieval)
- **Заголовок:** Оценка достаточности запроса + подсказки агенту что переспросить

### 3.2 Фундамент (тема 1, HLE-413)

#### `0011-fork-bsl-atlas-as-core.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.1; `_source/notion/bsl-atlas-opensource-research--*.md`; `LICENSE` (AGPL-3.0)
- **implemented-in:** `architecture/02-containers.md` §«Азимут-ядро»
- **related-to:** [0012 (имя)](#0012-name-azimut), [0013 (роль форка)](#0013-fork-role-code-engine), [0015 (миграция стека)](#0015-stack-migration-smoke-then-qdrant), [0023 (лицензии)](#0023-license-checklist-and-source-rule), [0028 (Sentry × AGPL)](#0028-sentry-vs-agpl)
- **Заголовок:** Основа — форк `bsl-atlas` (AGPL-3.0) как ядро понимания кода 1С

#### `0012-name-azimut.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` §«Название проекта/форка»
- **implemented-in:** README репо
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core)
- **Заголовок:** Имя форка/проекта — «Азимут» / `azimuth`
- **Примечание:** короткий ADR (~10 строк), фиксирующий имя и логику («навигационное» направление, атрибуция автору bsl-atlas — отдельно в README+NOTICE).

#### `0013-fork-role-code-engine.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.2
- **implemented-in:** `architecture/02-containers.md` §«Азимут-ядро»; граница «форк vs наш код» подробно в ADR 0022
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0015](#0015-stack-migration-smoke-then-qdrant), [0022](#0022-boundary-fork-vs-own-code)
- **Заголовок:** Роль `bsl-atlas`: только «движок понимания кода» (берём парсер BSL + граф вызовов + каркас MCP + docker; меняем хранилище/эмбеддер/реранк; дописываем поведенческий контракт и оркестрацию)

#### `0014-fserg-mcp-1c-as-reference-only.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.3; `_source/notion/hle-460-fserg-chunking-qdrant--*.md` (MIT подтверждён)
- **implemented-in:** `architecture/02-containers.md` §«Хранилище» (заимствуем payload-схему и RRF)
- **related-to:** [0024 (чанкинг)](#0024-code-chunking-deterministic-structural)
- **Заголовок:** `FSerg/mcp-1c-v1` — референс архитектуры, не кодовая основа (берём идеи payload-схемы и RRF, код не копируем)

#### `0015-stack-migration-smoke-then-qdrant.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.4
- **implemented-in:** `architecture/02-containers.md` §«Хранилище»; `roadmap.md` фаза 2 (дымовой прогон → миграция)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0014](#0014-fserg-mcp-1c-as-reference-only)
- **Заголовок:** Миграция стека: гибрид по времени — один дымовой прогон `bsl-atlas` на ChromaDB, затем сразу Qdrant+BGE-M3 (ни строчки нового кода под Chroma)
- **Подкреплено риском:** дымовой прогон на реальной ERP не выполнен — см. `roadmap.md` «Открытые риски».

#### `0016-onec-mcp-universal-deferred.md`
- **status:** `accepted` (с пометкой `deferred`)
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413 (отложен до HLE-419)
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.5
- **implemented-in:** —
- **related-to:** [0029](#0029-multitenancy-qdrant-embedded-vs-server), [0032](#0032-multitenancy-tenant-storage-isolation)
- **Заголовок:** MCP-шлюз `onec-mcp-universal` — отложен до темы 7 (на локальном сценарии не нужен; Claude Desktop тянет несколько MCP-серверов напрямую)

#### `0017-mcp-bsl-platform-context-included.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.6
- **implemented-in:** `architecture/02-containers.md` §«MCP-серверы рядом — справочник платформы»
- **related-to:** —
- **Заголовок:** `alkoleft/mcp-bsl-platform-context` берём в фундамент (drop-in вторым MCP, MIT, бесплатно)

#### `0018-mcp-client-no-own-ui.md`
- **status:** `superseded by 0019`
- **date:** 2026-05-26 (открыт) → 2026-05-26 (уточнён в 1.7a)
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.7
- **implemented-in:** —
- **superseded-by:** 0019
- **related-to:** [0019](#0019-cherry-studio-default-client)
- **Заголовок:** UX и клиент — свой UI не строим, берём готовый MCP-клиент с облачной разговорной моделью (общий принцип — без конкретики клиента; уточнено в ADR 0019)

#### `0019-cherry-studio-default-client.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.7a; `_source/notion/hle-458-mini-ai-1c-competitors--*.md`
- **implemented-in:** `architecture/02-containers.md` §«Клиент»
- **supersedes:** 0018
- **related-to:** [0021 (модель DeepSeek)](#0021-default-model-deepseek-v4)
- **Заголовок:** Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода)

#### `0020-cloud-llm-via-adapter.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.8
- **implemented-in:** `architecture/02-containers.md` §«Adapter-слой к разговорной модели»
- **related-to:** [0021](#0021-default-model-deepseek-v4), [0008 (П1)](#0008-п1-groundedness-detector)
- **Заголовок:** Разговорная модель — облачная и подключаемая через адаптер; внутри MCP-сервера нет разговорной LLM; лёгкие модели (BGE/реранкер/судья) — локально по умолчанию, грант Cohere — опциональный апгрейд

#### `0021-default-model-deepseek-v4.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.8a
- **implemented-in:** `architecture/02-containers.md` §«Adapter-слой» + конфиг
- **related-to:** [0020](#0020-cloud-llm-via-adapter), [0019](#0019-cherry-studio-default-client)
- **Заголовок:** Дефолт разговорной модели — DeepSeek V4 (Flash основной, Pro для тяжёлого кода); запас — Claude/Qwen/Yandex; финал валидируем eval-ом в теме 6

#### `0022-boundary-fork-vs-own-code.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.9
- **implemented-in:** `architecture/02-containers.md` (вся структура); `index.md` §4 (Solution Strategy)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0013](#0013-fork-role-code-engine), [0017](#0017-mcp-bsl-platform-context-included), [0014](#0014-fserg-mcp-1c-as-reference-only)
- **Заголовок:** Граница «форк/готовые библиотеки vs наш код» — форк даёт понимание кода, библиотеки дают механику RAG, наш код — поведение, гарантии, оркестрацию

#### `0023-license-checklist-and-source-rule.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.10; `LICENSE` (AGPL-3.0); `COPYRIGHT`
- **implemented-in:** `architecture/05-crosscutting.md` §«Лицензии и атрибуция»; CI (`pip-licenses` или аналог)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0014](#0014-fserg-mcp-1c-as-reference-only), [0028](#0028-sentry-vs-agpl)
- **Заголовок:** Лицензионный чек-лист OSS под AGPL-3.0 + правило источников («✅ проверено: \<файл/url\>» или «⚠️ предположение»)

### 3.3 Обработка кода 1С (тема 2, HLE-414)

#### `0024-code-chunking-deterministic-structural.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/design-system-v2--*.md` реш. 2.1; `_source/notion/hle-460-fserg-chunking-qdrant--*.md`; `_source/notion/hle-456-four-implementations--*.md` (факты из `bsl-atlas` vector_indexer.py)
- **implemented-in:** `architecture/02-containers.md` §«Чанкер»; `architecture/03-pipelines.md` §«Индексация»
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0013](#0013-fork-role-code-engine), [0027 (портирование feenlace)](#0027-port-feenlace-techniques-to-python)
- **Заголовок:** Детерминированная структурная резка кода поверх Азимута — функция = чанк (≤ порога), иначе режем по top-level блокам (`Если`/`Цикл`/`Попытка`/`Область`) с шапкой контекста; запросы в строках режутся по `|;`; LLM для резки не используем

#### `0025-resolve-same-named-procedures.md`
- **status:** `proposed` (схема зафиксирована, алгоритм не написан)
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/hle-459-graph-analogs--*.md`; `_source/notion/hle-456-four-implementations--*.md`
- **implemented-in:** `architecture/02-containers.md` §«Граф вызовов»; запланировано — наш код (открытая инженерная задача)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0024](#0024-code-chunking-deterministic-structural), [0026](#0026-code-search-routing)
- **Заголовок:** Алгоритм резолва одноимённых процедур (одинаковые имена в разных модулях) — открытый алгоритм поверх схемы из metacode (в открытом коде эту проблему не решил никто; готового не унаследуем)

#### `0026-code-search-routing.md`
- **status:** `proposed`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/hle-461-search-routing--*.md`
- **implemented-in:** `architecture/02-containers.md` §«Диспетчер MCP»; `architecture/03-pipelines.md` §«Запрос по коду»
- **related-to:** [0005 (Р5)](#0005-р5-server-controlled-retrieval), [0024](#0024-code-chunking-deterministic-structural), [0025](#0025-resolve-same-named-procedures)
- **Заголовок:** Роутинг поиска по коду — fallback-цепочка graph → metadata → grep (по образцу `comol/ai_rules_1c`)

#### `0027-port-feenlace-techniques-to-python.md`
- **status:** `accepted` (переформулировано 2026-05-27, см. `_source/_resolutions.md` #2)
- **date:** 2026-05-26 (исходно: «переписать на Go») → 2026-05-27 (переформулировано: «портировать технику в Python»)
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/hle-456-four-implementations--*.md` (реш. 2.4 после правки); `_source/notion/solutions-registry-summary--*.md` (противоречие №3 — действие выполнено); `_source/_resolutions.md` #2
- **implemented-in:** `architecture/02-containers.md` §«Индексатор» (техники: GC-off-аналог, шардирование, кеш по SHA, манифест-diff, BSL-синонимы)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0022](#0022-boundary-fork-vs-own-code), [0024](#0024-code-chunking-deterministic-structural)
- **Заголовок:** Портировать технику `mcp-1c` (feenlace) в наш Python-код (НЕ переписывать на Go — фундамент остаётся Python+FastMCP; берём идеи, не язык)

### 3.4 Открытые вопросы (proposed/open)

#### `0028-sentry-vs-agpl.md`
- **status:** `proposed` (ждём ответ Sentry)
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413 (исходно) + HLE-314, HLE-318, HLE-319 (Sentry-инфраструктура)
- **basis:** `_source/notion/design-system-v2--*.md` §«Открытый вопрос — Конфликт AGPL × Sentry for Open Source»; `_source/linear/agent-konsultant-po-1s-erp/HLE-314.md`; [sentry.io/for/open-source](https://sentry.io/for/open-source)
- **implemented-in:** `architecture/05-crosscutting.md` §«Мониторинг» (план Б — GlitchTip/self-host Sentry/Prometheus+Grafana)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0023](#0023-license-checklist-and-source-rule)
- **Заголовок:** Конфликт AGPL × Sentry for Open Source — ждём ответ Sentry; если откажут — план Б (без Sentry, форк bsl-atlas НЕ переоткрывается)

#### `0029-multitenancy-qdrant-embedded-vs-server.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25 (поднят в `questions.md`)
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419 (тема 7)
- **basis:** `_source/notion/questions--*.md` §«Влияние мульти-аренды на ранее принятые решения»; `_source/_resolutions.md` #9; `_source/notion/bsl-atlas-opensource-research--*.md` Пробел 9
- **implemented-in:** `architecture/02-containers.md` §«Хранилище» (выбор режима по конфигурации)
- **related-to:** [0015 (миграция стека)](#0015-stack-migration-smoke-then-qdrant), [0030](#0030-multitenancy-canary-vs-watchdog), [0031](#0031-multitenancy-push-via-web-frontend), [0032](#0032-multitenancy-tenant-storage-isolation)
- **Заголовок:** Мульти-аренда: Qdrant embedded vs server (embedded — локально, server — VDS) — развилка по режиму, не глобальное решение

#### `0030-multitenancy-canary-vs-watchdog.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419
- **basis:** `_source/notion/questions--*.md` §«Влияние мульти-аренды»; `_source/_resolutions.md` #9; HLE-310 (мониторинг релизов из v1.x)
- **implemented-in:** `architecture/02-containers.md` §«Мониторинг релизов» + `architecture/03-pipelines.md` §«Обновление»
- **related-to:** [0029](#0029-multitenancy-qdrant-embedded-vs-server), [0032](#0032-multitenancy-tenant-storage-isolation)
- **Заголовок:** Канарейка-в-потоке vs фоновый сторож для VDS (как разбудить «протухшее в покое» у незаходящих контор)

#### `0031-multitenancy-push-via-web-frontend.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419
- **basis:** `_source/notion/questions--*.md` §«Влияние мульти-аренды»; `_source/_resolutions.md` #9
- **implemented-in:** `architecture/02-containers.md` §«Веб-морда» (тема 7)
- **related-to:** [0019 (клиент по ролям)](#0019-cherry-studio-default-client), [0029](#0029-multitenancy-qdrant-embedded-vs-server)
- **Заголовок:** Push к пользователю через веб-морду как замена отсутствующего push в MCP (уведомить контору о готовности переиндексации)

#### `0032-multitenancy-tenant-storage-isolation.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419
- **basis:** `_source/notion/bsl-atlas-opensource-research--*.md` Пробел 9; `_source/_resolutions.md` #9
- **implemented-in:** `architecture/02-containers.md` §«Хранилище» + `architecture/05-crosscutting.md` §«Безопасность/изоляция»
- **related-to:** [0029](#0029-multitenancy-qdrant-embedded-vs-server), [0023 (license/auth)](#0023-license-checklist-and-source-rule)
- **Заголовок:** Изоляция файлового хранилища по тенантам (`/data/{tenant_id}/...` + FastAPI-зависимость с tenant_id из JWT в фильтры Qdrant и таблицы PostgreSQL)

#### `0033-r1-contradiction-detection-mechanics.md`
- **status:** `proposed` (open — закрываем в теме 5)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` Р1 (открытый хвост); `_source/_resolutions.md` #11
- **implemented-in:** `architecture/05-crosscutting.md` §«Метрика противоречивости» — детальная механика
- **related-to:** [0001 (Р1)](#0001-р1-metric-contradiction), [0003 (Р3)](#0003-р3-llm-judge-spans)
- **Заголовок:** Механика детектирования противоречивости (как технически детектировать, порог, поведение при множестве конфликтов)

---

## 4. Сводка для отчёта в Linear

- **Целевых документов:** 10
  - `index.md` (1) + `architecture/01..05` (5) + `decisions/README.md` (1, индекс) + `glossary.md` (1) + `cases/01-document-changed-account.md` (1) + `roadmap.md` (1).
- **ADR в плане:** 33 (полный список с шапками — раздел 3).
  - Анти-галлюцинации/фон: 10 (Р1, Р2, Р3, Р4 как «надгробие», Р5, Р6, Р7, П1, П2, П3).
  - Фундамент (тема 1): 13 (реш. 1.1, имя «Азимут», 1.2, 1.3, 1.4, 1.5, 1.6, 1.7→superseded, 1.7a, 1.8, 1.8a, 1.9, 1.10).
  - Обработка кода (тема 2): 4 (реш. 2.1, 2.2, 2.3, 2.4).
  - Открытые/proposed: 6 (Sentry × AGPL, 4 развилки мульти-аренды, механика Р1).
- **Источников полностью покрыто:** все 17 страниц Notion + все 61 issue Linear (16 «Переписываем ТЗ» + 45 «Агент-консультант по 1С ERP») + все вложения (HLE-456..464/result+notes) + 4 проектных документа в `_project-docs/`. Спецификации (`_source/specs/`) и meta-летопись (`_crosscheck.md`, `_resolutions.md`, манифесты) явно помечены как «остаются в `_source/`, не мигрируются».
- **Флаги для Сергея:**
  1. Перед архивированием `karta-zadach-i-arhitekturnye-resheniya-aktualno.md` (v1.x) — сверить с `design-system-v2`, чтобы не упустить требований.
  2. Темы 3–7 пока имеют только placeholder-и в `roadmap.md` + 5 open-ADR. Дополнительные ADR появятся при работе над HLE-415..419.
  3. ADR 0025 (резолв одноимённых) и 0026 (роутинг поиска) — `proposed`; нуждаются в явном утверждении при работе над темой 2 (HLE-414).
  4. Сейчас в `decisions/` плоский список 33 ADR. Подпапки (`decisions/foundation/`, `decisions/code-processing/`) добавляем, если станет >50–60.

*Создано 2026-05-27 для HLE-495. После утверждения Сергеем — `Done`. Без утверждения — `In Review`.*
