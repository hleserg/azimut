# 05 — Карта переноса и список ADR (план пересборки документации)

> Задача Linear: [HLE-495](https://linear.app/hleserg/issue/HLE-495).
>
> **Что это.** План перехода от сырой выгрузки в [`docs/_source/`](../_source/) к настоящей документации в `docs/`. После утверждения Сергеем этот документ становится управляющим для всех дальнейших задач: каждый кусок источников знает свой целевой документ или ADR, каждый ADR знает своё место в архитектуре.
>
> **Предусловия (выполнены).** [HLE-494](https://linear.app/hleserg/issue/HLE-494) Done; [`_source/_crosscheck.md`](../_source/_crosscheck.md) заполнен; [`_source/_resolutions.md`](../_source/_resolutions.md) применён; методичка [`_source/specs/_howto.md`](../_source/specs/_howto.md) на месте.
>
> **Источник истины** — `docs/_source/` (зафиксировано в `_resolutions.md`). Notion/Linear не пересинхронизируются.

## Содержание

1. [Целевое дерево репозитория](#1-целевое-дерево-репозитория)
2. [Карта переноса (источник → целевой документ/ADR)](#2-карта-переноса-источник--целевой-документадр)
3. [Список ADR с шапками](#3-список-adr-с-шапками)
4. [Процесс и автоматизация](#4-процесс-и-автоматизация)
5. [Сводка для отчёта в Linear](#5-сводка-для-отчёта-в-linear)

---

## 1. Целевое дерево репозитория

Структура опирается на [`_source/specs/_howto.md`](../_source/specs/_howto.md) и сами скачанные спецификации в [`_source/specs/`](../_source/specs/): arc42 (выборочные секции 1/3/4/5/6/8/9/12 + §2/§7/§10/§11 точечно), MADR 4.0.0 для ADR, **C4 через Architecture-as-Code (Structurizr DSL)** для статичных диаграмм Context/Container/Component, Mermaid для runtime-сценариев (sequenceDiagram).

**Главный сдвиг подхода (2026-05-27).** Раньше планировалось C4 через Mermaid внутри markdown-файлов. Решение: переходим на **Structurizr DSL** — единая текстовая модель в `workspace.dsl` в корне репо, из которой Structurizr Lite (Docker) рендерит views для уровней Context/Container/Component с auto-layout. Связь DSL ↔ ADR — через `properties { "adr-link" "..." }` на элементах DSL (см. ADR 0034). Mermaid остаётся для §6 Runtime View (sequenceDiagram читается лучше DSL Dynamic-views в git diff).

```
azimuth/                                            # корень репо
├── workspace.dsl                                   # ⭐ Architecture-as-Code: единая C4-модель
│                                                   # (Context + Container + Component); ADR 0034.
│                                                   # Properties { adr-link / open-issues } на элементах
│                                                   # дают трассировку: компонент ↔ ADR ↔ research.
│                                                   # Локальный просмотр: `docker run -it --rm -p 8080:8080
│                                                   # -v .:/usr/local/structurizr structurizr/lite`
├── .github/
│   └── prompts/                                    # ⭐ Промпты для ИИ-агентов (PR-ревьюер + ресерч)
│       ├── pr-architecture-lint.md                 # промпт 1: архитектурный линтер
│       ├── pr-adr-check.md                         # промпт 2: ADR-контролер
│       ├── pr-lead-manual-check.md                 # промпт 3: контроль главы 13
│       └── research-with-llm.md                    # протокол ресерчей с LLM (см. раздел 4 этого плана)
└── docs/
    ├── index.md                                    # короткий мини-README со ссылкой
    │                                               # «начни с docs/architecture/01-introduction-and-goals.md»
    ├── architecture/                               # arc42 — полный 12-главный шаблон + глава 13
    │   ├── README.md                               # 🧭 путеводитель: как читать эту папку,
    │   │                                           # ссылка на workspace.dsl и Structurizr Lite,
    │   │                                           # инструкция ИИ-агентам куда дописывать новое
    │   ├── 01-introduction-and-goals.md            # arc42 §1: назначение, стейкхолдеры (Сергей, мама,
    │   │                                           # будущий публичный OSS), top quality goals
    │   ├── 02-architecture-constraints.md          # arc42 §2: технические и оргограничения —
    │   │                                           # AGPL-3.0 (наследие форка), Python ≥3.11, on-prem
    │   │                                           # для мамы, локальный запуск, mini-ai-1c как клиент
    │   │                                           # Сергея, правило источников (реш. 1.10), 152-ФЗ
    │   │                                           # фолбэки для коммерции (тема 7)
    │   ├── 03-context-and-scope.md                 # arc42 §3 + C4 view `systemContext` (из workspace.dsl):
    │   │                                           # пользователь → клиент (Cherry/Claude/mini-ai-1c) →
    │   │                                           # MCP-серверы (Азимут + mcp-bsl-platform-context) →
    │   │                                           # облачная LLM (DeepSeek/Claude) + внешние источники
    │   │                                           # (ИТС, портал платформы); чего НЕ делаем
    │   ├── 04-solution-strategy.md                 # arc42 §4: ключевые архитектурные решения одним
    │   │                                           # списком — форк bsl-atlas + Cherry Studio + DeepSeek
    │   │                                           # + Qdrant + BGE-M3 + Cohere по запросу; граница
    │   │                                           # форк vs наш код (реш. 1.9). Подробности — в ADR
    │   ├── 05-building-block-view.md               # arc42 §5 + C4 views `container`/`component`:
    │   │                                           # whitebox-обзор + blackbox-таблица контейнеров;
    │   │                                           # Component-view только для Азимут-ядра
    │   │                                           # (граф+чанкер+эмбеддер) и MCP-оркестратора
    │   │                                           # (Р5+Р6+судья). Реестр доноров — здесь же таблицей
    │   ├── 06-runtime-view.md                      # arc42 §6: Mermaid sequenceDiagram —
    │   │                                           # индексация, запрос, обновление, фолбэк (Р7),
    │   │                                           # судья (Р3). Mermaid выбран вместо DSL Dynamic-views
    │   │                                           # — лучше читается в git diff (ADR 0034)
    │   ├── 07-deployment-view.md                   # arc42 §7: локальный сценарий (Python+uv+FastMCP
    │   │                                           # + Qdrant embedded локально); VDS/мульти-аренда —
    │   │                                           # отложен до темы 7 (HLE-419, ADR 0029–0032)
    │   ├── 08-cross-cutting-concepts.md            # arc42 §8: анти-галлюцинации (Р1–Р7, П1–П3),
    │   │                                           # мониторинг/канарейка, безопасность/приватность
    │   │                                           # (PII, GDPR), лицензии/AGPL §13, правило источников
    │   │                                           # (реш. 1.10), процесс разработки (DoD, см. главу 13)
    │   ├── 09-architectural-decisions.md           # arc42 §9: глава-обзор со ссылкой на adr/.
    │   │                                           # Сюда — только индекс по темам/статусам;
    │   │                                           # сами ADR — в adr/<подпапка>/NNNN-*.md
    │   ├── 10-quality-requirements.md              # arc42 §10: NFR — faithfulness ≥ 0.80 с реранком
    │   │                                           # (порог из solutions-registry), latency,
    │   │                                           # отказоустойчивость, локальная установка для мамы
    │   ├── 11-technical-risks.md                   # arc42 §11: слепые зоны bsl-atlas (подписки/
    │   │                                           # асинхрон/.epf/.erf/МенеджерВременныхТаблиц),
    │   │                                           # граница «доказуемо статически vs runtime»,
    │   │                                           # открытые риски (дымовой прогон bsl-atlas на ERP,
    │   │                                           # резолв одноимённых, Sentry × AGPL)
    │   ├── 12-glossary.md                          # arc42 §12: термины 1С (АГРЕГАТ, ПодпискаНаСобытие,
    │   │                                           # МенеджерВременныхТаблиц, …), проектные
    │   │                                           # (Азимут-ядро, MCP-оркестратор), технические
    │   │                                           # (ISCF, BSL, RRF, Self-RAG, Faithfulness, BGE-M3,
    │   │                                           # Cohere, AGPL §13, FastMCP, …); 25+ BSL entry-points
    │   ├── 13-lead-operating-manual.md             # ⭐ Lead Operating Manual (НЕ arc42, наше расширение):
    │   │                                           # регламент Сергея — еженедельный чек-лист, метрики
    │   │                                           # по компонентам, инструкции триажа алертов,
    │   │                                           # протокол LLM-ресерчей, пул задач лида.
    │   │                                           # Шаблон — в разделе 4.5 этого плана.
    │   │                                           # Кодинг-агенты ОБЯЗАНЫ дополнять при добавлении
    │   │                                           # инфраструктурных элементов (см. промпт 3)
    │   ├── adr/                                    # каталог MADR-ADR (детализация для §9)
    │   │   ├── template.md                         # шаблон MADR + наши поля (linear-task, basis,
    │   │   │                                       # implemented-in — может ссылаться на DSL-элемент
    │   │   │                                       # через properties; related-to, supersedes/
    │   │   │                                       # superseded-by). НЕ ADR — не считается в нумерации
    │   │   ├── anti-hallucinations/                # Р1–Р7 + П1–П3 (фон) + ADR-«надгробие» Р4
    │   │   │   ├── 0001-р1-metric-contradiction.md
    │   │   │   ├── 0002-р2-faithfulness-vs-relevance.md
    │   │   │   ├── 0003-р3-llm-judge-spans.md
    │   │   │   ├── 0004-р4-honest-deadend-retired.md
    │   │   │   ├── 0005-р5-server-controlled-retrieval.md
    │   │   │   ├── 0006-р6-source-hierarchy.md
    │   │   │   ├── 0007-р7-fallback-mode-switch.md
    │   │   │   ├── 0008-п1-groundedness-detector.md
    │   │   │   ├── 0009-п2-re-retrieval.md
    │   │   │   └── 0010-п3-query-sufficiency.md
    │   │   ├── foundation/                         # тема 1: фундамент
    │   │   │   ├── 0011-fork-bsl-atlas-as-core.md
    │   │   │   ├── 0012-name-azimut.md
    │   │   │   ├── 0013-fork-role-code-engine.md
    │   │   │   ├── 0014-fserg-mcp-1c-as-reference-only.md
    │   │   │   ├── 0015-stack-migration-smoke-then-qdrant.md
    │   │   │   ├── 0016-onec-mcp-universal-deferred.md
    │   │   │   ├── 0017-mcp-bsl-platform-context-included.md
    │   │   │   ├── 0018-mcp-client-no-own-ui.md
    │   │   │   ├── 0019-cherry-studio-default-client.md
    │   │   │   ├── 0020-cloud-llm-via-adapter.md
    │   │   │   ├── 0021-default-model-deepseek-v4.md
    │   │   │   ├── 0022-boundary-fork-vs-own-code.md
    │   │   │   └── 0023-license-checklist-and-source-rule.md
    │   │   ├── code-processing/                    # тема 2: обработка кода 1С
    │   │   │   ├── 0024-code-chunking-deterministic-structural.md
    │   │   │   ├── 0025-resolve-same-named-procedures.md
    │   │   │   ├── 0026-code-search-routing.md
    │   │   │   └── 0027-port-feenlace-techniques-to-python.md
    │   │   ├── tooling/                            # инструментарий и процесс
    │   │   │   └── 0034-architecture-as-code-structurizr-dsl.md
    │   │   └── open/                               # открытые/proposed
    │   │       ├── 0028-sentry-vs-agpl.md
    │   │       ├── 0029-multitenancy-qdrant-embedded-vs-server.md
    │   │       ├── 0030-multitenancy-canary-vs-watchdog.md
    │   │       ├── 0031-multitenancy-push-via-web-frontend.md
    │   │       ├── 0032-multitenancy-tenant-storage-isolation.md
    │   │       └── 0033-r1-contradiction-detection-mechanics.md
    │   └── research/                               # исследования с трассировкой из DSL properties
    │       └── .gitkeep                            # пусто на старте; наполняется при HLE-415..419
    ├── cases/                                      # эталонные кейсы (для eval и поведенческого контракта)
    │   └── 01-document-changed-account.md          # «почему документ сменил счёт» — 3 слоя
    │                                               # (см. _resolutions.md #6)
    └── roadmap.md                                  # фазы со ссылками на HLE-XXX: тема 1→2→3→4→5→6→7;
                                                    # перечень открытых рисков; архив v1.x-декомпозиции
```

**Что изменилось относительно прошлой версии (после расширения 2026-05-27 вечером):**

1. **arc42 — 5 файлов → 12 + глава 13.** Раньше `01-context`, `02-containers`, `03-pipelines`, `04-blind-spots`, `05-crosscutting`. Теперь — полный шаблон arc42 (`01..12`) + наша 13-я глава `lead-operating-manual.md` (регламент Сергея). Главная мотивация — четкое назначение каждой главы упрощает работу ИИ-агентов (они знают, куда класть требования к безопасности, ограничения и т.д.) и автогенерацию документации Structurizr Lite, который встраивает arc42-главы в свой портал.
2. **`docs/index.md`** теперь — короткий мини-README. Точка входа для людей и ИИ-агентов — `docs/architecture/01-introduction-and-goals.md`.
3. **`docs/architecture/README.md`** заменяет ранее планировавшийся `architecture/index.md` — путеводитель + инструкция ИИ-агентам.
4. **§2 Constraints, §7 Deployment, §10 Quality — теперь отдельные файлы.** Раньше §2 был «растворён», §7 и §10 — «отложены». Сейчас под полную arc42-схему — отдельные файлы заводим сразу (даже если содержимое минимально), потому что (а) шаблон arc42 предполагает, (б) Structurizr Lite ожидает фиксированные имена для встраивания, (в) ИИ-агент знает, куда дописать новое требование.
5. **§9 Architectural Decisions** — теперь это глава-обзор `09-architectural-decisions.md` со ссылкой на `adr/` (индекс по темам/статусам). Сами ADR — в `adr/<подпапка>/`.
6. **`docs/glossary.md`** удаляется как отдельный артефакт — переезжает в `architecture/12-glossary.md` (так и должно по arc42).
7. **Новый раздел `.github/prompts/`** — промпты для ИИ-агента-ревьюера (3 промпта: архитектурный линтер, ADR-контролер, контроль главы 13) + промпт для протокола ресерчей с LLM. Содержание — в разделе 4 этого плана.
8. **Глава 13 (Lead Operating Manual)** — НЕ из arc42, наше расширение. Регламент Сергея + точка обновления для ИИ-агентов: при добавлении нового сервиса/БД они обязаны вписать метрики и инструкции триажа. Шаблон — в разделе 4.5 этого плана.
9. **ADR-нумерация НЕ меняется** (0001–0034 как было). Только `implemented-in:` ссылки переезжают на новые пути.

**Соответствие arc42 — файлы плана (явный mapping):**

| arc42 § | Файл | Чем наполнен | Статус |
|---|---|---|---|
| §1 | `architecture/01-introduction-and-goals.md` | назначение системы, стейкхолдеры (Сергей, мама, будущий OSS), top quality goals | обязателен; точка входа для людей и ИИ-агентов |
| §2 | `architecture/02-architecture-constraints.md` | AGPL-3.0 (наследие форка), Python ≥3.11, on-prem, mini-ai-1c-как-клиент-Сергея, правило источников (реш. 1.10), 152-ФЗ | отдельный файл (раньше планировал растворять — переход на полный arc42 требует выделить) |
| §3 | `architecture/03-context-and-scope.md` + view `systemContext` в `workspace.dsl` | пользователь → клиент → MCP-серверы → облачная LLM + внешние источники; что НЕ делаем | обязателен; текст + DSL-диаграмма (ADR 0034) |
| §4 | `architecture/04-solution-strategy.md` | ключевые архитектурные решения одним списком (форк bsl-atlas + Cherry Studio + DeepSeek + Qdrant + BGE-M3 + Cohere on demand; граница форк vs наш код); подробности — в ADR | обязателен |
| §5 | `architecture/05-building-block-view.md` + views `container`/`component` в `workspace.dsl` | whitebox-обзор + blackbox-таблица; Component-view для Азимут-ядра и MCP-оркестратора; реестр доноров таблицей | обязателен по arc42 (mandatory); текст + DSL-диаграмма |
| §6 | `architecture/06-runtime-view.md` | Mermaid sequenceDiagram — индексация, запрос, обновление, фолбэк (Р7), судья (Р3) | Mermaid выбран вместо DSL Dynamic-views — лучше git diff (ADR 0034) |
| §7 | `architecture/07-deployment-view.md` | локальный сценарий (Python+uv+FastMCP + Qdrant embedded локально); VDS/мульти-аренда отложен до темы 7 | отдельный файл, минимально заполнен сейчас; расширяется при HLE-419 |
| §8 | `architecture/08-cross-cutting-concepts.md` | анти-галлюцинации (Р1–Р7, П1–П3), мониторинг/канарейка, безопасность/приватность, лицензии/AGPL §13, правило источников, процесс разработки (DoD — см. главу 13) | обязателен |
| §9 | `architecture/09-architectural-decisions.md` (глава-обзор) + `architecture/adr/<подпапка>/NNNN-*.md` (детали в MADR) + `architecture/adr/template.md` | обзор индексирует ADR по темам и статусам; сами ADR — в `adr/` | обязателен |
| §10 | `architecture/10-quality-requirements.md` | NFR — faithfulness ≥ 0.80 с реранком, latency, отказоустойчивость, локальная установка | отдельный файл, минимально заполнен сейчас; расширяется при HLE-418 (тема 6) |
| §11 | `architecture/11-technical-risks.md` | слепые зоны bsl-atlas; граница доказуемо статически vs runtime; открытые риски (дымовой прогон, резолв одноимённых, Sentry × AGPL) | обязателен |
| §12 | `architecture/12-glossary.md` | термины 1С + проектные + технические; 25+ BSL entry-points | обязателен |
| §13 (наше) | `architecture/13-lead-operating-manual.md` | регламент Сергея: чек-листы, метрики, триаж алертов, LLM-протокол, пул задач лида | наше расширение; обязательно дополняется ИИ-агентами при добавлении сервисов |

**Зачем полный arc42, если многие главы пусты на старте.** (а) ИИ-агентам нужен предсказуемый адрес для каждого вида знания (требование безопасности → §8; ограничение → §2; нефункциональное требование → §10). (б) Structurizr Lite встраивает Markdown-главы рядом со схемами по фиксированным именам — пустые заголовки сигнализируют «здесь будет дописано», а не «об этом не подумали». (в) Когда глава пуста — пишем одну фразу «здесь пока нечего сказать, см. ADR <ссылка>» (правило из `_howto.md` §1).

**Нумерация файлов и arc42-номера совпадают.** `01..12` в именах файлов = arc42 §1..§12. Глава 13 — наше расширение, идёт следом по той же логике.

**Что НЕ создаём сейчас (явно):**

- C4 Level 3 (Component) view — только для Азимут-ядра (граф+чанкер+эмбеддер) и MCP-оркестратора (Р5+Р6+судья). Для других контейнеров — Container-view достаточно.
- C4 Level 4 (Code), System Landscape, Dynamic-view — пока не делаем (Dynamic — экспериментальный, Runtime закрывается Mermaid в §6).
- **Mermaid C4Context/C4Container/C4Component — НЕ используем.** Статичные C4-диаграммы живут только в `workspace.dsl` (ADR 0034). Mermaid остаётся для §6 Runtime (sequenceDiagram), flowchart-ов и крайних случаев одиночных диаграмм вне модели.
- **Пустые главы — оставляем с заголовком и одной фразой** «здесь пока нечего сказать, см. ADR <ссылка>» (правило `_howto.md` §1). Не удаляем: это сигнал «об этом подумали и решили не разворачивать».

**Где живут ключевые секции:**

- arc42 §4 (Solution Strategy) — в `docs/architecture/04-solution-strategy.md` (отдельный файл, не в `docs/index.md`).
- `docs/index.md` — короткий мини-README со ссылкой на `docs/architecture/01-introduction-and-goals.md`.
- `docs/architecture/README.md` — путеводитель по папке: как читать, ссылки на `workspace.dsl` и Structurizr Lite, инструкция для ИИ-агентов куда дописывать новое.

**Локальная сборка/просмотр Structurizr.** Для рендера view'ев из `workspace.dsl` в браузере:

```
docker run -it --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite
```

Открыть `http://localhost:8080`. Это инструмент разработчика. Автоматический рендер для PR/main — два варианта в разделе 4.1 (CI/CD).

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
| `hub-1c-assistent--*.md` | `architecture/01-introduction-and-goals.md` + `architecture/12-glossary.md` | arc42 + glossary | Назначение системы (агент-консультант для Сергея/мамы), базовый стек, цели качества. Хаб уже обновлён под текущие реш. 1.7a/1.8 (`_resolutions.md` #5) — переносим как актуальный. |
| `decisions--*.md` | ADR 0001–0010 (Р1–Р7 + П1–П3) + `architecture/08-cross-cutting-concepts.md` | ADR + arc42 | Прямой исходник для 9 принятых/предложенных ADR анти-галлюцинаций. Р4 → отдельный ADR со `status: superseded by 0007`. Термины («ретривер», «агент-генератор», «MCP-сервер») → `architecture/12-glossary.md`. |
| `runbook--*.md` | `architecture/13-lead-operating-manual.md` (основа — у нас уже есть прямой регламент для Сергея, см. шаблон главы 13 в разделе 4.5) + `architecture/08-cross-cutting-concepts.md` (общие операционные принципы) | arc42 + наше | Операционное руководство для руководителя. С введением главы 13 (Lead Operating Manual) контент попадает туда напрямую: метрики, инструкции триажа, чек-листы. Сквозные концепции (например, мониторинг как принцип) — в §8. |
| `design-system-v2--*.md` | ADR 0011–0023 + `architecture/04-solution-strategy.md` + `architecture/02-architecture-constraints.md` + `architecture/05-building-block-view.md` + `architecture/08-cross-cutting-concepts.md` | ADR + arc42 | Главный исходник по фундаменту (тема 1). Все реш. 1.1–1.10 + 1.7a + 1.8a + Название «Азимут» → отдельные ADR. Раздел «Что НЕ меняется» → §2 Constraints (`02-architecture-constraints.md`). Solution Strategy одной фразой по каждому решению → §4. Раздел «📂 Что bsl-atlas реально делает» → `11-technical-risks.md` + ADR 0024. Реестр доноров → §5 Building Block View (раздел «Compositional choices»). Журнал решений по темам 3–7 (пока пустые) → пропускаем, наполнится при HLE-415..419. |
| `solutions-registry-summary--*.md` | `roadmap.md` + `architecture/09-architectural-decisions.md` (индекс ADR со статусами) + ADR 0027 (Реш. 2.4) | roadmap + arc42 + ADR | Оценки 1–10 → `roadmap.md` как «вес» решений и перечень открытых рисков. Индексная глава §9 цитирует таблицу статусов. «Три действия перед ТЗ» — 1 и 2 выполнены в `_resolutions.md` #3/#4; действие 3 (реш. 2.4 «Go → Python») закреплено отдельным ADR 0027. |
| `questions--*.md` | `cases/01-document-changed-account.md` + ADR 0028–0033 (открытые) + `architecture/08-cross-cutting-concepts.md` (мульти-аренда) | case + ADR | Эталонный кейс «почему документ сменил счёт» (3 слоя по `_resolutions.md` #6) → `cases/`. Раздел мульти-аренды (4 развилки из `_resolutions.md` #9) → 4 отдельных open-ADR (0029–0032). Открытые хвосты Р1 (метрика противоречивости) → ADR 0033 со `status: proposed`. Раздел про ISCF — см. отдельный пункт ниже. **Раздел про устное разрешение лицензии bsl-atlas уже удалён** (`_resolutions.md` #1) — переносить нечего. |
| `iscf-analysis--*.md` | `architecture/05-building-block-view.md` (раздел «Приём ИТС») + `architecture/12-glossary.md` (ISCF, Data.cab, Data.dir, CFHD) | arc42 + glossary | Целевой документ темы 4 (HLE-416) пока не существует — материал ИТС пойдёт частью в `02-containers.md` (где описаны pipeline-контейнеры), частью в глоссарий. Когда будет писаться тема 4 — основной материал переедет в её документ; до тех пор живёт в общей архитектуре. |
| `researches--*.md` | `_source/` (архив, не мигрируем) + `roadmap.md` (ссылкой) | archive | Контент уже растащен по другим страницам (см. `_crosscheck.md` «что пропущено и почему»). File-attachment `RAG_dlya_1C_ERP_obzor.md` Notion MCP не качал — потери для решений не выявлено. В `roadmap.md` — ссылка как «история исследований». |
| `bsl-atlas-opensource-research--*.md` | `architecture/05-building-block-view.md` (реестр компонентов) + `architecture/11-technical-risks.md` (пробелы) + `roadmap.md` | arc42 + roadmap | Систематический обзор «10 пробелов и кандидатов». В `02-containers.md` — состав готовых компонентов с ролями; в `04-blind-spots.md` — пробелы (асинхрон, мульти-аренда — Пробел 9); в `roadmap.md` — фазовое внедрение. |
| `hle-456-four-implementations--*.md` | ADR 0024 (чанкинг — раздел «факты из bsl-atlas») + ADR 0027 (Реш. 2.4 — портирование feenlace в Python) + `architecture/05-building-block-view.md` (сравнительная таблица) | ADR + arc42 | Прямой источник реш. 2.4 (`_resolutions.md` #2 переформулировал на Python). Реестр доноров (feenlace, метаcode, bsl-graph) и сравнение по 5 осям → подкрепляет 0024/0027 и раздел «реестр доноров» в `architecture/05-building-block-view.md`. |
| `hle-459-graph-analogs--*.md` | ADR 0025 (резолв одноимённых) + `architecture/05-building-block-view.md` (раздел «Граф вызовов») | ADR + arc42 | Главный источник реш. 2.2: «резолв одноимённых = открытый алгоритм, схема зафиксирована». ADR 0025 статус `proposed` — алгоритм ещё не написан. |
| `hle-461-search-routing--*.md` | ADR 0026 (роутинг поиска: graph → metadata → grep) + `architecture/05-building-block-view.md` (диспетчер MCP) + `architecture/06-runtime-view.md` (runtime-сценарий «Запрос по коду») | ADR + arc42 | Реш. 2.3. ADR 0026 статус `proposed` (требует утверждения Сергеем при работе над темой 2). |
| `hle-463-bsl-ls-wrappers--*.md` | `architecture/05-building-block-view.md` (раздел реестра доноров) + `architecture/12-glossary.md` (BSL entry-points) + ADR 0011 (Реш. 1.1) как референс | arc42 + glossary | Сам факт «BSL LS отложить, для v1 берём tree-sitter» — это поддержка ADR 0011/0024. 25+ BSL entry-points (`ПриЗаписи`, `ПриПроведении`, …) → отдельный справочник в `architecture/12-glossary.md` (или отдельный файл `glossary/bsl-entry-points.md` если разрастётся). |
| `hle-457-prompt-engineering-xml--*.md` | `architecture/08-cross-cutting-concepts.md` (раздел «Промт-инжиниринг») + `architecture/12-glossary.md` (типы объектов 1С) | arc42 + glossary | Выводы cc-1c-skills для темы 5. Конкретный системный промпт появится в теме 5 (HLE-417); сейчас идёт фактура (абстракции XML, тэгирование `<config>`/`<query>`). |
| `hle-460-fserg-chunking-qdrant--*.md` | ADR 0024 (чанкинг — payload-схема Qdrant) + `architecture/05-building-block-view.md` (раздел «Хранилище») | ADR + arc42 | Идеи payload-схемы и RRF-слияния. Архитектурно код не переиспользуется (см. ADR 0014 / Реш. 1.3); берём только лекало. |
| `hle-464-runtime-live-1c--*.md` | `architecture/11-technical-risks.md` (раздел «runtime-данные») + ADR 0029–0032 (мульти-аренда) + `cases/01-document-changed-account.md` (2-й и 3-й слой кейса) | arc42 + ADR + case | 5 репо runtime-доступа к живой 1С. Классификация А/Б → в blind-spots (что доказуемо статически vs только через 1c_mcp). `1c-mcp-toolkit` (anti-pattern, лицензии нет) → негативный реестр в `architecture/08-cross-cutting-concepts.md`. |
| `hle-458-mini-ai-1c-competitors--*.md` | `architecture/05-building-block-view.md` (реестр инструментов) + ADR 0018/0019 (клиент по ролям) | arc42 + ADR | mini-ai-1c как клиент для Сергея (захват кода из Конфигуратора) — поддержка ADR 0019 (Реш. 1.7a). 1c-buddy / EDT-MCP — в реестр компонентов как референсы. |

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
| `HLE-456.md` + `attachments/HLE-456/{result,notes}-HLE-456.md` | ADR 0024/0027 (basis) + `architecture/05-building-block-view.md` (сравнительная таблица 4 реализаций) | ADR + arc42 | Вложения = первичные отчёты сравнения, синтез лёг в `hle-456-four-implementations.md`. В ADR ссылка идёт на сводную Notion-страницу + на attachments как первоисточник. |
| `HLE-457.md` + `attachments/HLE-457/*` | `architecture/08-cross-cutting-concepts.md` (промт-инжиниринг) + `architecture/12-glossary.md` | arc42 + glossary | Аналогично HLE-456 — синтез в Notion `hle-457-prompt-engineering-xml.md`. |
| `HLE-458.md` + `attachments/HLE-458/*` | `architecture/05-building-block-view.md` (реестр клиентов/MCP) | arc42 | Синтез в `hle-458-mini-ai-1c-competitors.md`. |
| `HLE-459.md` + `attachments/HLE-459/*` | ADR 0025 (basis) + `architecture/05-building-block-view.md` (граф) | ADR + arc42 | Синтез в `hle-459-graph-analogs.md`. |
| `HLE-460.md` + `attachments/HLE-460/*` | ADR 0024 (basis для payload-схемы) + ADR 0014 (basis для «MIT, идеи берём, код нет») | ADR | Синтез в `hle-460-fserg-chunking-qdrant.md`. |
| `HLE-461.md` + `attachments/HLE-461/*` | ADR 0026 (basis) + `architecture/05-building-block-view.md` (диспетчер) | ADR + arc42 | Синтез в `hle-461-search-routing.md`. |
| `HLE-462.md` (Backlog — onec-help-mcp, гибрид BM25+вектор) | `roadmap.md` (фаза 3, отложен) | roadmap | Дочерний к HLE-415 (тема 3). Решение по гибриду BM25+вектор примем в теме 3. Сейчас — placeholder. |
| `HLE-463.md` + `attachments/HLE-463/*` | `architecture/05-building-block-view.md` (реестр доноров) + `architecture/12-glossary.md` (BSL entry-points) | arc42 + glossary | Синтез в `hle-463-bsl-ls-wrappers.md`. |
| `HLE-464.md` + `attachments/HLE-464/*` | `architecture/11-technical-risks.md` + ADR 0029–0032 (basis) + `cases/01-document-changed-account.md` | arc42 + ADR + case | Синтез в `hle-464-runtime-live-1c.md`. |

### 2.3 Linear — проект «Агент-консультант по 1С ERP» (45 issue, групповой перенос)

Это **старая декомпозиция v1.x** до перехода на v2.0. Перенос — групповой с точечными исключениями.

| Группа источников в `_source/linear/agent-konsultant-po-1s-erp/` | Куда | Тип | Примечание |
|---|---|---|---|
| HLE-292, 295, 297–312 (1.x декомпозиция: каркас, ADR-стек, парсер XML, индексатор, поисковый слой, MCP-сервер, контракт, CLI, BGE-менеджер, онбординг, эксперименты, судья, Cohere-адаптеры, упаковка, мониторинг релизов, живые процедуры, ежемесячное обновление) | `roadmap.md` (раздел «Архив v1.x: старая декомпозиция») | archive | Не мигрируем дословно — декомпозиция v1.x пересобирается заново исходя из решений v2.0 (форк bsl-atlas + готовые библиотеки + конкурентное ядро). В roadmap.md — ссылка как «исторический контекст» с одной фразой про каждый issue. При работе над фазами v2.0 — сверяться, чтобы не упустить требования (например, healthcheck папки из HLE-337, get_procedure из HLE-311). |
| HLE-313, 316, 317, 318, 319 (bootstrap — In Progress: репо/CI/Devin-ревьювер, реальные данные, cc-1c-skills, Sentry workflow, Sentry-ревью) | `architecture/08-cross-cutting-concepts.md` (мониторинг/инструментация) + ADR 0028 (Sentry × AGPL — basis) + `roadmap.md` (фаза 0) | arc42 + ADR | Bootstrap-задачи реально влияют на crosscutting (Sentry, логирование, репо-структура). Из HLE-317 (cc-1c-skills) фактура уже растащена в `hle-457-prompt-engineering-xml.md`. HLE-318/319 (Sentry workflow) — переориентируются по результату ADR 0028. |
| HLE-314 (Sentry-грант — Done) | ADR 0028 (basis: история согласования) | ADR | Done со ссылкой на исходное согласование гранта; теперь конфликтует с AGPL — см. ADR 0028. |
| HLE-315 (Sentry-инструментация — In Progress) | `architecture/08-cross-cutting-concepts.md` (мониторинг) | arc42 | Технически не отменена; зависит от ADR 0028 (если план Б — мигрирует на GlitchTip/self-host). |
| HLE-320 (repo-template — In Progress) | `roadmap.md` (фаза 0) | roadmap | Шаблон репо для будущих проектов — не часть этого ТЗ напрямую, упоминание в roadmap как параллельная инициатива. |
| HLE-321, 322, 323 (agent-playbook — Backlog/In Progress) | `roadmap.md` (фаза 0) | roadmap | Изучение agent-playbook и перенос полезного в правила проекта. Фактура для CLAUDE.md / правил агентов; в архитектуру и ADR напрямую не входит. |
| HLE-324 (adapter-агностичная архитектура MCP + install() — Backlog) | `architecture/05-building-block-view.md` (раздел адаптеров) + ADR 0020 (Реш. 1.8 — basis) | arc42 + ADR | Тема адаптера уже учтена в Реш. 1.8 (адаптер к разговорной модели в фундаменте); HLE-324 — конкретизация для install(). |
| HLE-332, 333, 334, 335 (Canceled — Document Registry, парсер личных документов, адаптивный контекст, семантический кеш) | `_source/` (отметка «отменены»; не переносим) | archive | Явно Canceled. Дубликаты в HLE-336, 337, 338, 339 (Backlog) — содержательные требования уже там. |
| HLE-336, 337, 338, 339, 340 (1a/3a/11a/6a/4a — пересобранная декомпозиция: Document Registry, парсер личных документов, адаптивный контекст, семантический кеш, PII-фильтр) | `roadmap.md` (раздел «Архив v1.x: пересобранная декомпозиция») | archive | Параллельный набор задач, который тоже отомрёт при v2.0-пересборке. PII-фильтр (HLE-340) → попадёт в `architecture/08-cross-cutting-concepts.md` (приватность). |
| HLE-341..346 (КТ1..КТ6 — контрольные точки приёмки v1.x) | `_source/` (архив) | archive | Контрольные точки v1.x. Аналоги для v2.0 будут перепроектированы при работе над фазами. |

**Итог по группе:** все 45 issue учтены. Большая часть → `roadmap.md` как «исторический контекст». Те, что содержательно работают (bootstrap, инструментация, adapter-агностика) → точечно в `architecture/08-cross-cutting-concepts.md` или basis-ссылки в ADR. Canceled — отметка «архив», не переносим.

### 2.4 Linear-вложения, проектные документы и служебные файлы

| Источник | Куда | Тип | Примечание |
|---|---|---|---|
| `_source/linear/_manifest.json`, `_projects.json` | `_source/` (остаётся) | meta | Манифесты выгрузки; пути к файлам и метаданные. Не мигрируем — это служебный индекс. |
| `_source/linear/attachments/HLE-{456..464}/{result,notes}-HLE-NNN.md` | basis-ссылки в соответствующих ADR + поддержка `architecture/*` | ADR + arc42 | Уже учтены в строках 2.2 рядом со своими issue. |
| `_source/linear/attachments/_project-docs/_project2_description.md` | `architecture/01-introduction-and-goals.md` (целевые пользователи, контекст) | arc42 | Полное описание проекта «Переписываем ТЗ» — справочный материал, частично перекрывается с `hub-1c-assistent.md`. |
| `_source/linear/attachments/_project-docs/agent-konsultant-po-1s-erp-polnoe-opisanie-proekta.md` | `roadmap.md` (раздел «Архив v1.x») | archive | Полное описание проекта v1.x — переносим только как исторический контекст. |
| `_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md` | `roadmap.md` + проверка на потери при сверке с design-system-v2 | archive | Карта задач v1.x — справочно. Сверить с design-system-v2, чтобы не упустить требования. **Флаг для Сергея:** проверить, нет ли тут архитектурных решений, не отражённых в design-system-v2 (см. секцию «Флаги» ниже). |
| `_source/linear/attachments/_project-docs/tasks-polnaya-karta-zadach-i-zavisimostej.md` | `roadmap.md` (раздел «Архив v1.x») | archive | Граф задач v1.x с зависимостями. Справочно. |

### 2.5 Спецификации и meta-документация

| Источник | Куда | Тип | Примечание |
|---|---|---|---|
| `_source/specs/_howto.md` | `_source/specs/` (остаётся) | meta | Методичка — вход для проектирования, а не контент. **Не мигрируется.** Ссылка из `architecture/README.md` и `docs/index.md`: «как написана документация — см. `_source/specs/_howto.md`». |
| `_source/specs/_links.md` | `_source/specs/` (остаётся) | meta | Индекс ссылок на источники спек. Не мигрируется. |
| `_source/specs/arc42/`, `c4/`, `madr/`, `mermaid/` | `_source/specs/` (остаётся) | meta | Скачанные канонические спецификации. Не мигрируются. Используются как референс при написании документов. |
| `_source/_crosscheck.md` | `_source/` (остаётся) | meta | Летопись сверки HLE-494. Не мигрируется. |
| `_source/_resolutions.md` | `_source/` (остаётся) | meta | Летопись применённых решений HLE-494. Не мигрируется. |
| `_source/notion/_manifest.json` | `_source/` (остаётся) | meta | Манифест Notion-выгрузки. Не мигрируется. |
| Корневые `LICENSE` (AGPL-3.0), `COPYRIGHT` | Корень репо (без изменений) | meta | Не относится к `docs/`. Упоминается в `architecture/08-cross-cutting-concepts.md` (раздел «Лицензии»). |

### 2.6 Флаги (что обсудить с Сергеем перед утверждением)

1. **`karta-zadach-i-arhitekturnye-resheniya-aktualno.md`** в `_project-docs/` — сверял с `design-system-v2.md`. Большинство v1.x-требований (личные документы как 3-й источник, Document Registry, мониторинг папки, адаптивный cut-off, кеш запросов, GDPR-флоу) — обсуждаем при открытии соответствующих тем (HLE-415..419). **Существенное расхождение, фиксируем сразу:** v1.x говорит «парсер XML-выгрузки конфигурации» (HLE-297) — это **отдельный формат** выгрузки 1С из Конфигуратора, не равный текстовой выгрузке `DumpConfigToFiles → *.bsl + метаданные`, на которую опирается bsl-atlas (реш. 1.1/1.2). XML-выгрузка содержит структуру объектов и реквизиты в XML-формате; текстовая — модули BSL и метаданные через `DumpConfigToFiles`. При работе над темой 2 (HLE-414) и темой 4 (HLE-416) — учесть, что **скорее всего нужны оба источника**: XML для полной структуры объектов (формы, регистры, реквизиты), текстовый — для модулей BSL и графа вызовов. В ADR 0011 (форк bsl-atlas) и 0024 (чанкинг) это сейчас не отражено явно — фиксирую как известное требование, утверждаем при работе над темой 2/4.
2. **Темы 3–7 — пустые в design-system-v2 («🔲 ожидает обсуждения»).** При работе над HLE-415..419 будут возникать новые ADR. Сейчас в плане учтены только placeholders в `roadmap.md` + 5 open-ADR (Sentry, мульти-аренда). При утверждении плана это нормально — план фиксирует точку Т0, дальнейшие ADR — итеративно.
3. **Дочерние Notion-страницы по темам 3–7** в Notion-хабе НЕТ (в выгрузке только страницы по фундаменту и теме 2). Если Сергей в будущем заведёт новые страницы — карту переноса дополнить.
4. **`researches.md` file-attachment `RAG_dlya_1C_ERP_obzor.md`** не выгружен (Notion MCP не качает бинарники). По `_crosscheck.md` потерь решений нет, но если когда-нибудь понадобится — придётся качать руками.

---

## 3. Список ADR с шапками

**Нумерация.** Сквозная по всем темам, 4 разряда (`NNNN`). Сейчас фиксируем 34 ADR (`0001`–`0034`); при работе над темами 3–7 нумерация продолжится с `0035`. `template.md` НЕ имеет номера — это шаблон, не ADR.

**Файл и имя.** `docs/architecture/adr/<подпапка>/NNNN-kebab-case-title.md`. Подпапки: `anti-hallucinations/`, `foundation/`, `code-processing/`, `tooling/`, `open/`.

**Поля шапки.** По `_howto.md` §3 + маппинг полей из HLE-493 + связь с DSL (ADR 0034):
- `status` — `proposed` / `accepted` / `rejected` / `deprecated` / `superseded by NNNN`
- `date` — дата принятия (для accepted) или открытия (для proposed)
- `decision-makers` — обычно `[Сергей]`, для предложенных П1/П2/П3 — Сергей + согласование с агентом-консультантом
- `linear-task` — задача Linear, в рамках которой принято
- `basis` — на чём основано (HLE-XXX, файл в `_source/`)
- `implemented-in` — компонент архитектуры; для решений, привязанных к C4-элементу — ссылка на элемент в `workspace.dsl` (через `properties { "adr-link" "docs/architecture/adr/<...>" }` на обратной стороне); для решений уровня дизайна — раздел в `docs/architecture/04-solution-strategy.md` или соответствующая глава arc42
- `related-to` — связанные ADR
- `supersedes` / `superseded-by` — где применимо

### 3.1 Анти-галлюцинации и поведенческий контракт (фон)

#### `0001-р1-metric-contradiction.md`
- **status:** `accepted` (с открытым подвопросом — см. ADR 0033)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** [`_source/notion/decisions--*.md`](../_source/notion/decisions--36b0c905e62681019228dfcc7ec2a1cb.md) Р1
- **implemented-in:** `architecture/08-cross-cutting-concepts.md` §«Метрика противоречивости»; реализация — MCP-сервер (контроль ретривинга, Р5)
- **related-to:** [0006 (Р6 — иерархия источников)](#0006-р6-source-hierarchy), [0033 (механика детектирования)](#0033-r1-contradiction-detection-mechanics)
- **Заголовок:** Метрика противоречивости источников ПЕРЕД выдачей

#### `0002-р2-faithfulness-vs-relevance.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-418 (тема 6)
- **basis:** `_source/notion/decisions--*.md` Р2
- **implemented-in:** `architecture/08-cross-cutting-concepts.md` §«Метрики качества»; реализация — eval-харнесс (RAGAS) + LLM-судья
- **related-to:** [0003 (Р3)](#0003-р3-llm-judge-spans), [0008 (П1)](#0008-п1-groundedness-detector)
- **Заголовок:** Faithfulness и relevance ретривера — разные метрики

#### `0003-р3-llm-judge-spans.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5) + HLE-306 (LLM-судья из v1.x)
- **basis:** `_source/notion/decisions--*.md` Р3
- **implemented-in:** `architecture/05-building-block-view.md` §«LLM-судья» (отдельный контейнер); `architecture/06-runtime-view.md` §«Запрос → судья»
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
- **Примечание:** короткий ADR-надгробие, чтобы при чтении `architecture/adr/anti-hallucinations/` было видно, что Р4 не «потерялся». Тело: «Р4 предлагал «не нашёл — честно ответь не знаю». Признан недостаточным: пользователь остаётся без помощи. Заменён на Р7 (фолбэк = смена режима, дип-ресёрч с тем же контрактом).»

#### `0005-р5-server-controlled-retrieval.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5) + HLE-299 (поисковый слой из v1.x)
- **basis:** `_source/notion/decisions--*.md` Р5
- **implemented-in:** `architecture/05-building-block-view.md` §«MCP-сервер: контроль ретривинга»; `architecture/06-runtime-view.md` §«Запрос → добор → ответ»
- **related-to:** [0006 (Р6)](#0006-р6-source-hierarchy), [0009 (П2)](#0009-п2-re-retrieval)
- **Заголовок:** Контроль ретривинга — на сервере (планка релевантности, триггер добора, потолок окна)

#### `0006-р6-source-hierarchy.md`
- **status:** `accepted`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` Р6
- **implemented-in:** `architecture/05-building-block-view.md` §«MCP-сервер: иерархия источников»; `architecture/08-cross-cutting-concepts.md`
- **related-to:** [0001 (Р1)](#0001-р1-metric-contradiction), [0005 (Р5)](#0005-р5-server-controlled-retrieval)
- **Заголовок:** Иерархия источников при конфликте: код → справка → ИТС

#### `0007-р7-fallback-mode-switch.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` Р7
- **implemented-in:** `architecture/06-runtime-view.md` §«Фолбэк-сценарий: дип-ресёрч»
- **supersedes:** 0004
- **related-to:** [0004 (Р4 — снят)](#0004-р4-honest-deadend-retired)
- **Заголовок:** Фолбэк = смена режима (дип-ресёрч в интернете с тем же контрактом)

#### `0008-п1-groundedness-detector.md`
- **status:** `proposed`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` П1
- **implemented-in:** `architecture/05-building-block-view.md` §«LLM-судья» (3 уровня действий)
- **related-to:** [0003 (Р3)](#0003-р3-llm-judge-spans), [0002 (Р2)](#0002-р2-faithfulness-vs-relevance)
- **Заголовок:** Детектор «relevance высокий / groundedness низкий» — 3 уровня действий

#### `0009-п2-re-retrieval.md`
- **status:** `proposed`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` П2
- **implemented-in:** `architecture/05-building-block-view.md` §«MCP-сервер: повторный ретривинг»; `architecture/06-runtime-view.md`
- **related-to:** [0005 (Р5)](#0005-р5-server-controlled-retrieval)
- **Заголовок:** Второй проход ретривера при неуверенности (открытый триггер)

#### `0010-п3-query-sufficiency.md`
- **status:** `proposed`
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` П3
- **implemented-in:** `architecture/05-building-block-view.md` §«MCP-сервер: оценка запроса»
- **related-to:** [0005 (Р5)](#0005-р5-server-controlled-retrieval)
- **Заголовок:** Оценка достаточности запроса + подсказки агенту что переспросить

### 3.2 Фундамент (тема 1, HLE-413)

#### `0011-fork-bsl-atlas-as-core.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.1; `_source/notion/bsl-atlas-opensource-research--*.md`; `LICENSE` (AGPL-3.0)
- **implemented-in:** `architecture/05-building-block-view.md` §«Азимут-ядро»
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
- **implemented-in:** `architecture/05-building-block-view.md` §«Азимут-ядро»; граница «форк vs наш код» подробно в ADR 0022
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0015](#0015-stack-migration-smoke-then-qdrant), [0022](#0022-boundary-fork-vs-own-code)
- **Заголовок:** Роль `bsl-atlas`: только «движок понимания кода» (берём парсер BSL + граф вызовов + каркас MCP + docker; меняем хранилище/эмбеддер/реранк; дописываем поведенческий контракт и оркестрацию)

#### `0014-fserg-mcp-1c-as-reference-only.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.3; `_source/notion/hle-460-fserg-chunking-qdrant--*.md` (MIT подтверждён)
- **implemented-in:** `architecture/05-building-block-view.md` §«Хранилище» (заимствуем payload-схему и RRF)
- **related-to:** [0024 (чанкинг)](#0024-code-chunking-deterministic-structural)
- **Заголовок:** `FSerg/mcp-1c-v1` — референс архитектуры, не кодовая основа (берём идеи payload-схемы и RRF, код не копируем)

#### `0015-stack-migration-smoke-then-qdrant.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.4
- **implemented-in:** `architecture/05-building-block-view.md` §«Хранилище»; `roadmap.md` фаза 2 (дымовой прогон → миграция)
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
- **implemented-in:** `architecture/05-building-block-view.md` §«MCP-серверы рядом — справочник платформы»
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
- **implemented-in:** `architecture/05-building-block-view.md` §«Клиент»
- **supersedes:** 0018
- **related-to:** [0021 (модель DeepSeek)](#0021-default-model-deepseek-v4)
- **Заголовок:** Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода)

#### `0020-cloud-llm-via-adapter.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.8
- **implemented-in:** `architecture/05-building-block-view.md` §«Adapter-слой к разговорной модели»
- **related-to:** [0021](#0021-default-model-deepseek-v4), [0008 (П1)](#0008-п1-groundedness-detector)
- **Заголовок:** Разговорная модель — облачная и подключаемая через адаптер; внутри MCP-сервера нет разговорной LLM; лёгкие модели (BGE/реранкер/судья) — локально по умолчанию, грант Cohere — опциональный апгрейд

#### `0021-default-model-deepseek-v4.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.8a
- **implemented-in:** `architecture/05-building-block-view.md` §«Adapter-слой» + конфиг
- **related-to:** [0020](#0020-cloud-llm-via-adapter), [0019](#0019-cherry-studio-default-client)
- **Заголовок:** Дефолт разговорной модели — DeepSeek V4 (Flash основной, Pro для тяжёлого кода); запас — Claude/Qwen/Yandex; финал валидируем eval-ом в теме 6

#### `0022-boundary-fork-vs-own-code.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.9
- **implemented-in:** `architecture/05-building-block-view.md` (вся структура); `architecture/04-solution-strategy.md` (краткая фиксация)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0013](#0013-fork-role-code-engine), [0017](#0017-mcp-bsl-platform-context-included), [0014](#0014-fserg-mcp-1c-as-reference-only)
- **Заголовок:** Граница «форк/готовые библиотеки vs наш код» — форк даёт понимание кода, библиотеки дают механику RAG, наш код — поведение, гарантии, оркестрацию

#### `0023-license-checklist-and-source-rule.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413
- **basis:** `_source/notion/design-system-v2--*.md` реш. 1.10; `LICENSE` (AGPL-3.0); `COPYRIGHT`
- **implemented-in:** `architecture/08-cross-cutting-concepts.md` §«Лицензии и атрибуция»; CI (`pip-licenses` или аналог)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0014](#0014-fserg-mcp-1c-as-reference-only), [0028](#0028-sentry-vs-agpl)
- **Заголовок:** Лицензионный чек-лист OSS под AGPL-3.0 + правило источников («✅ проверено: \<файл/url\>» или «⚠️ предположение»)

### 3.3 Обработка кода 1С (тема 2, HLE-414)

#### `0024-code-chunking-deterministic-structural.md`
- **status:** `accepted`
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/design-system-v2--*.md` реш. 2.1; `_source/notion/hle-460-fserg-chunking-qdrant--*.md`; `_source/notion/hle-456-four-implementations--*.md` (факты из `bsl-atlas` vector_indexer.py)
- **implemented-in:** `architecture/05-building-block-view.md` §«Чанкер»; `architecture/06-runtime-view.md` §«Индексация»
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0013](#0013-fork-role-code-engine), [0027 (портирование feenlace)](#0027-port-feenlace-techniques-to-python)
- **Заголовок:** Детерминированная структурная резка кода поверх Азимута — функция = чанк (≤ порога), иначе режем по top-level блокам (`Если`/`Цикл`/`Попытка`/`Область`) с шапкой контекста; запросы в строках режутся по `|;`; LLM для резки не используем

#### `0025-resolve-same-named-procedures.md`
- **status:** `proposed` (схема зафиксирована, алгоритм не написан)
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/hle-459-graph-analogs--*.md`; `_source/notion/hle-456-four-implementations--*.md`
- **implemented-in:** `architecture/05-building-block-view.md` §«Граф вызовов»; запланировано — наш код (открытая инженерная задача)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0024](#0024-code-chunking-deterministic-structural), [0026](#0026-code-search-routing)
- **Заголовок:** Алгоритм резолва одноимённых процедур (одинаковые имена в разных модулях) — открытый алгоритм поверх схемы из metacode (в открытом коде эту проблему не решил никто; готового не унаследуем)

#### `0026-code-search-routing.md`
- **status:** `accepted` (утверждено 2026-05-27, синтез HLE-461 = решение)
- **date:** 2026-05-27
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/hle-461-search-routing--*.md`; `_source/linear/perepisyvaem-tz/HLE-461.md` + `attachments/HLE-461/result-HLE-461.md`
- **implemented-in:** `architecture/05-building-block-view.md` §«Диспетчер MCP»; `architecture/06-runtime-view.md` §«Запрос по коду»
- **related-to:** [0005 (Р5)](#0005-р5-server-controlled-retrieval), [0024](#0024-code-chunking-deterministic-structural), [0025](#0025-resolve-same-named-procedures)
- **Заголовок:** Роутинг поиска по коду — fallback-цепочка graph → metadata → grep (по образцу `comol/ai_rules_1c`)

#### `0027-port-feenlace-techniques-to-python.md`
- **status:** `accepted` (переформулировано 2026-05-27, см. `_source/_resolutions.md` #2)
- **date:** 2026-05-26 (исходно: «переписать на Go») → 2026-05-27 (переформулировано: «портировать технику в Python»)
- **decision-makers:** [Сергей]
- **linear-task:** HLE-414
- **basis:** `_source/notion/hle-456-four-implementations--*.md` (реш. 2.4 после правки); `_source/notion/solutions-registry-summary--*.md` (противоречие №3 — действие выполнено); `_source/_resolutions.md` #2
- **implemented-in:** `architecture/05-building-block-view.md` §«Индексатор» (техники: GC-off-аналог, шардирование, кеш по SHA, манифест-diff, BSL-синонимы)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0022](#0022-boundary-fork-vs-own-code), [0024](#0024-code-chunking-deterministic-structural)
- **Заголовок:** Портировать технику `mcp-1c` (feenlace) в наш Python-код (НЕ переписывать на Go — фундамент остаётся Python+FastMCP; берём идеи, не язык)

### 3.4 Открытые вопросы (proposed/open)

#### `0028-sentry-vs-agpl.md`
- **status:** `proposed` (ждём ответ Sentry)
- **date:** 2026-05-26
- **decision-makers:** [Сергей]
- **linear-task:** HLE-413 (исходно) + HLE-314, HLE-318, HLE-319 (Sentry-инфраструктура)
- **basis:** `_source/notion/design-system-v2--*.md` §«Открытый вопрос — Конфликт AGPL × Sentry for Open Source»; `_source/linear/agent-konsultant-po-1s-erp/HLE-314.md`; [sentry.io/for/open-source](https://sentry.io/for/open-source)
- **implemented-in:** `architecture/08-cross-cutting-concepts.md` §«Мониторинг» (план Б — GlitchTip/self-host Sentry/Prometheus+Grafana)
- **related-to:** [0011](#0011-fork-bsl-atlas-as-core), [0023](#0023-license-checklist-and-source-rule)
- **Заголовок:** Конфликт AGPL × Sentry for Open Source — ждём ответ Sentry; если откажут — план Б (без Sentry, форк bsl-atlas НЕ переоткрывается)

#### `0029-multitenancy-qdrant-embedded-vs-server.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25 (поднят в `questions.md`)
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419 (тема 7)
- **basis:** `_source/notion/questions--*.md` §«Влияние мульти-аренды на ранее принятые решения»; `_source/_resolutions.md` #9; `_source/notion/bsl-atlas-opensource-research--*.md` Пробел 9
- **implemented-in:** `architecture/05-building-block-view.md` §«Хранилище» (выбор режима по конфигурации)
- **related-to:** [0015 (миграция стека)](#0015-stack-migration-smoke-then-qdrant), [0030](#0030-multitenancy-canary-vs-watchdog), [0031](#0031-multitenancy-push-via-web-frontend), [0032](#0032-multitenancy-tenant-storage-isolation)
- **Заголовок:** Мульти-аренда: Qdrant embedded vs server (embedded — локально, server — VDS) — развилка по режиму, не глобальное решение

#### `0030-multitenancy-canary-vs-watchdog.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419
- **basis:** `_source/notion/questions--*.md` §«Влияние мульти-аренды»; `_source/_resolutions.md` #9; HLE-310 (мониторинг релизов из v1.x)
- **implemented-in:** `architecture/05-building-block-view.md` §«Мониторинг релизов» + `architecture/06-runtime-view.md` §«Обновление»
- **related-to:** [0029](#0029-multitenancy-qdrant-embedded-vs-server), [0032](#0032-multitenancy-tenant-storage-isolation)
- **Заголовок:** Канарейка-в-потоке vs фоновый сторож для VDS (как разбудить «протухшее в покое» у незаходящих контор)

#### `0031-multitenancy-push-via-web-frontend.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419
- **basis:** `_source/notion/questions--*.md` §«Влияние мульти-аренды»; `_source/_resolutions.md` #9
- **implemented-in:** `architecture/05-building-block-view.md` §«Веб-морда» (тема 7)
- **related-to:** [0019 (клиент по ролям)](#0019-cherry-studio-default-client), [0029](#0029-multitenancy-qdrant-embedded-vs-server)
- **Заголовок:** Push к пользователю через веб-морду как замена отсутствующего push в MCP (уведомить контору о готовности переиндексации)

#### `0032-multitenancy-tenant-storage-isolation.md`
- **status:** `proposed` (open)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-419
- **basis:** `_source/notion/bsl-atlas-opensource-research--*.md` Пробел 9; `_source/_resolutions.md` #9
- **implemented-in:** `architecture/05-building-block-view.md` §«Хранилище» + `architecture/08-cross-cutting-concepts.md` §«Безопасность/изоляция»
- **related-to:** [0029](#0029-multitenancy-qdrant-embedded-vs-server), [0023 (license/auth)](#0023-license-checklist-and-source-rule)
- **Заголовок:** Изоляция файлового хранилища по тенантам (`/data/{tenant_id}/...` + FastAPI-зависимость с tenant_id из JWT в фильтры Qdrant и таблицы PostgreSQL)

#### `0033-r1-contradiction-detection-mechanics.md`
- **status:** `proposed` (open — закрываем в теме 5)
- **date:** 2026-05-25
- **decision-makers:** [Сергей]
- **linear-task:** HLE-417 (тема 5)
- **basis:** `_source/notion/decisions--*.md` Р1 (открытый хвост); `_source/_resolutions.md` #11
- **implemented-in:** `architecture/08-cross-cutting-concepts.md` §«Метрика противоречивости» — детальная механика
- **related-to:** [0001 (Р1)](#0001-р1-metric-contradiction), [0003 (Р3)](#0003-р3-llm-judge-spans)
- **Заголовок:** Механика детектирования противоречивости (как технически детектировать, порог, поведение при множестве конфликтов)

### 3.5 Инструментарий и процесс (подпапка `tooling/`)

#### `0034-architecture-as-code-structurizr-dsl.md`
- **status:** `accepted` (принято Сергеем 2026-05-27)
- **date:** 2026-05-27
- **decision-makers:** [Сергей]
- **linear-task:** HLE-495
- **basis:** инструкция Сергея в HLE-495 (Шаги 1–6 «Architecture as Code via Structurizr DSL + C4 Model»); `_source/specs/c4/c4model-diagrams.md` (4+3 типа диаграмм C4); `_source/specs/_howto.md` §2 (требования к нотации C4 — titles, legend, типы, технологии, протоколы); официальная документация Structurizr DSL и Structurizr Lite
- **implemented-in:** `workspace.dsl` в корне репо; локальный просмотр через `structurizr/lite` (Docker, порт 8080); все статичные C4-views (`systemContext`, `container`, `component` для Азимут-ядра и MCP-оркестратора) — отсюда
- **related-to:** [0022 (граница форк vs наш код)](#0022-boundary-fork-vs-own-code) — DSL описывает обе стороны границы; [0024 (чанкинг)](#0024-code-chunking-deterministic-structural), [0026 (роутинг)](#0026-code-search-routing) — компоненты Азимут-ядра/MCP-оркестратора с обратной ссылкой через `properties { "adr-link" ... }`
- **Заголовок:** Architecture-as-Code через Structurizr DSL — единый источник статичных C4-диаграмм; Runtime (sequence) остаётся в Mermaid
- **Краткое обоснование (для тела ADR при создании файла):**
  - **Context:** до 2026-05-27 план предполагал C4-диаграммы напрямую через Mermaid C4Context/C4Container в markdown. Это даёт хорошее отображение в GitHub, но: (1) каждая диаграмма — копия модели (имена сущностей дублируются в разных файлах), (2) Mermaid C4 экспериментальный и не поддерживает legend, properties, layout, (3) нет машинно-читаемого источника для линковки ADR ↔ компонент.
  - **Decision:** статичные C4 (System Context, Container, Component) — в одном файле `workspace.dsl` (Structurizr DSL). Каждый компонент DSL имеет `properties { "adr-link" "..." "open-issues" "..." }`, что даёт двустороннюю трассировку компонент ↔ ADR ↔ research.
  - **Consequences:** + единый источник; + явная типизация (Person/SoftwareSystem/Container/Component); + auto-layout; + Component-view только под нужные контейнеры; + локальный просмотр одним docker run; − зависимость от Java-рантайма у того, кто хочет смотреть локально (Structurizr Lite в Docker — снимает); − чуть выше порог входа для людей, которые видят DSL впервые (компенсируется путеводителем `docs/architecture/README.md`).
  - **Mermaid НЕ выбрасываем:** Runtime View (arc42 §6) — sequenceDiagram в `architecture/06-runtime-view.md` (читается в git diff лучше DSL Dynamic-views; Structurizr Dynamic-views экспериментальный). Одиночные flowchart-ы вне модели — тоже Mermaid.
  - **Confirmation:** workspace.dsl лежит в корне; `docker run -it --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite` поднимается без ошибок; views `systemContext`, `container`, `component` рендерятся; `properties { "adr-link" ... }` присутствует у ключевых элементов; CI-линт DSL (опционально) — отдельная задача roadmap.

---

## 4. Процесс и автоматизация

Этот раздел фиксирует, **как** мы работаем с архитектурой и документацией: правила обновления, CI/CD-сборка диаграмм, промпты для ИИ-агента-ревьюера на PR, протокол LLM-ресерчей и шаблон главы 13 (Lead Operating Manual). Это не ADR, а операционное руководство: оно описывает контур, который замыкает «код ↔ архитектура ↔ ADR ↔ инструкция для лида» в автоматически согласованную систему.

### 4.1 Просмотр диаграмм (CI/CD-рендеринг)

Два варианта автоматизации. Выбираем оба последовательно: А — на старте (минимум усилий, видно прямо в GitHub), Б — когда появится внутренний сервер.

**Вариант А — Git-native (генерация Mermaid из DSL в GitHub Actions).** Самый простой. CI/CD при пуше в `main` берёт `workspace.dsl`, экспортирует его в Mermaid-блоки через `structurizr/cli` и обновляет `README.md` (или `docs/architecture/diagrams/*.md`). Результат: актуальные C4-диаграммы прямо в веб-интерфейсе GitHub без локальной установки.

- Команда экспорта: `structurizr.sh export -workspace workspace.dsl -format mermaid`
- Триггер: push в `main` (или PR-preview через workflow_dispatch).
- Результат: коммит-бот пишет обновлённый markdown с Mermaid-диаграммами.

**Вариант Б — Корпоративный портал (Structurizr Lite в Docker-демоне).** Самый красивый. Внутренний сервер (или машина Сергея) держит `structurizr/lite` в `-d` режиме; webhook из GitHub дёргает `git pull` в смонтированной папке при пуше в `main`. Результат: постоянный внутренний URL (например, `http://arch.azimuth.local`), где интерактивные C4-views, клики «провалиться внутрь», ссылки на ADR через `properties`, навигация по arc42-главам как у portal/encyclopedia.

- Команда (демон): `docker run -d -p 8080:8080 -v /opt/azimuth:/usr/local/structurizr structurizr/lite`
- Webhook GitHub → cron `git -C /opt/azimuth pull` (каждые N минут) или прямой webhook.
- Этот вариант актуален, когда дойдём до темы 7 (HLE-419) и появится VDS.

**Конкретные задачи для roadmap фазы 0:** (1) добавить GitHub Action `structurizr-export.yml` с шагом `structurizr/cli export -format mermaid`; (2) после стабилизации — поднять Structurizr Lite в Docker-демоне (Б). Обе задачи — отдельные ADR при реализации (ADR 0035/0036 уйдут на это, нумерация продолжится с 0035).

### 4.2 Definition of Done — workspace.dsl как обязательная часть

**Главное правило** (заходит в `08-cross-cutting-concepts.md` §«Процесс разработки» и в `13-lead-operating-manual.md`):

> **Задача не считается выполненной, если изменения в структуре кода (новые сервисы, базы данных, API-эндпоинты, новые внешние интеграции) не отражены в файле `workspace.dsl` и для них не созданы/обновлены соответствующие ADR.**

Применяется к человекам и ИИ-агентам одинаково:
- Кодинг-агент закрывает Linear-задачу только если в PR есть изменения в `workspace.dsl` или явная пометка «структурных изменений нет».
- ИИ-ревьюер на PR (раздел 4.3) автоматически блокирует PR при нарушении.
- Лид (Сергей) при ревью читает diff `workspace.dsl` так же внимательно, как код.

### 4.3 Промпты для ИИ-агента-ревьюера на PR

Живут в `.github/prompts/`. Три промпта, каждый — отдельный шаг PR-чекера (GitHub Action подгружает соответствующий промпт и сравнивает diff PR с состоянием архитектуры).

#### Промпт 1 — Архитектурный линтер (`pr-architecture-lint.md`)

```
Контекст: Ты — Архитектурный Линтер (ИИ-ревьюер). Твоя задача — проверить, что
изменения в коде текущего Pull Request не нарушают утверждённую архитектуру
и зафиксированы в документации.

Входные данные:
1. Текстовая архитектура системы: [содержимое workspace.dsl]
2. Список изменённых файлов в PR: [git diff или список файлов]
3. arc42 §5 Building Block View: [содержимое docs/architecture/05-building-block-view.md]

Инструкция по валидации:
1. Проверь, появились ли в коде новые независимые модули, контроллеры,
   микросервисы или интеграции с внешними API.
2. Если они появились, проверь, добавлены ли они в файл workspace.dsl.
   Если их там нет, заблокируй PR и напиши:
   "Внимание: вы добавили компонент [Имя], но не внесли его в workspace.dsl."
3. Проверь связи между изменёнными файлами. Если в коде, например, Фронтенд
   начал напрямую обращаться к Базе данных в обход API, заблокируй PR
   с критической ошибкой:
   "Нарушение C4-модели: обнаружена запрещённая прямая связь контейнеров."
4. Сверь технологии в DSL и в коде. Если в DSL указан `Container "Worker" "Python"`,
   а в PR появляется Go-код для этого контейнера — заблокируй PR.
```

#### Промпт 2 — ADR-контролер (`pr-adr-check.md`)

```
Контекст: Ты — ИИ-контролер технической документации.

Входные данные:
1. workspace.dsl (с properties { "adr-link" "..." } на компонентах)
2. Папка docs/architecture/adr/ со всеми ADR
3. git diff текущего PR
4. Шаблон ADR: docs/architecture/adr/template.md

Инструкция:
1. Проанализируй изменённый код в данном PR. Если разработчик меняет логику
   работы критически важных узлов (меняет базу данных, вводит кэширование,
   переходит на асинхронные очереди, меняет протокол взаимодействия), проверь
   папку docs/architecture/adr/.
2. В этом PR должен быть либо добавлен новый файл NNNN-name.md, либо обновлён
   существующий ADR, на который ссылается изменяемый компонент в workspace.dsl
   через properties { "adr-link" "..." }.
3. Если код изменился фундаментально, а документация и properties компонентов
   в DSL остались нетронутыми — оставь комментарий:
   "PR требует создания Архитектурного решения (ADR). Пожалуйста, опиши
   причины изменения технического стека/паттерна по шаблону template.md."
4. Проверь, что новый ADR следует MADR-структуре (frontmatter с status/date/
   decision-makers/linear-task/basis/implemented-in/related-to + разделы
   Context and Problem Statement / Decision Drivers / Considered Options /
   Decision Outcome / Consequences).
```

#### Промпт 3 — Контроль главы 13 (`pr-lead-manual-check.md`)

```
Контекст: Ты — ИИ-контролер операционного регламента Лида.

Входные данные:
1. docs/architecture/13-lead-operating-manual.md
2. workspace.dsl
3. git diff PR

Инструкция:
1. Проверь, создаёт ли данный PR новые инфраструктурные элементы
   (новую базу данных, новый микросервис, новый сторонний API-интегратор,
   новую очередь, новый кеш).
2. Если ДА, то в PR должно быть включено изменение файла
   docs/architecture/13-lead-operating-manual.md:
     (a) добавлена строчка в таблицу «Метрики Системы» —
         какие метрики этого сервиса лид должен отслеживать;
     (b) описан в разделе «Инструкции по триажу Алертов»
         что делать Лиду, если этот новый сервис упадёт.
3. Если код добавлен, а инструкция для Лида в главе 13 не появилась —
   заблокируй PR с комментарием:
   "Пожалуйста, добавь регламент реагирования для Лида в главу
   13-lead-operating-manual.md для твоего нового сервиса
   (метрика в таблицу + алгоритм действий при сбое)."
```

### 4.4 Протокол ресерчей с LLM (`research-with-llm.md`)

Используется Сергеем (или агентом) при проектировании новой фичи через ChatGPT/Claude. Лежит в `.github/prompts/`, чтобы все агенты следовали единому протоколу.

```
Алгоритм ведения ресерча с LLM:

1. ИНИЦИАЛИЗАЦИЯ.
   Скинуть в LLM:
   - workspace.dsl целиком;
   - architecture/02-architecture-constraints.md
     (чтобы LLM не предлагал технологии, противоречащие ограничениям);
   - architecture/04-solution-strategy.md
     (чтобы LLM знал текущие ключевые решения).

2. ЗАПРОС.
   Сформулировать задачу:
   «Спроектируй отказоустойчивую очередь для уведомлений», или
   «Спроектируй модуль X с учётом текущей архитектуры и ограничений».

3. КРИТИКА (обязательный шаг).
   Попросить LLM найти 3 слабых места в её же предложенном решении
   с точки зрения масштабируемости, надёжности и совместимости
   с ADR-решениями. Это снимает «соблазн полноты» — LLM сама укажет
   на свои допущения.

4. ФИКСАЦИЯ (обязательный шаг).
   Дать финальную команду:
     «Решение принято. Теперь сделай две вещи:
      (1) Напиши готовый Markdown-текст для файла
          docs/architecture/adr/<подпапка>/NNNN-name.md по шаблону
          template.md;
      (2) Дай мне точный кусок кода на языке Structurizr DSL, который
          мне нужно вставить в workspace.dsl, включая связи с
          существующими контейнерами и блок properties с
          adr-link на этот новый ADR.»

5. ВСТАВКА.
   Сергей (или агент) копирует ответ ИИ в файлы репозитория,
   делает git commit, отправляет в PR. ИИ-ревьюер (промпты 1–3
   из раздела 4.3) пропускает код, интерактивные диаграммы
   автоматически перерисовываются (CI/CD из раздела 4.1).
```

### 4.5 Шаблон главы 13 — Lead Operating Manual

Файл `docs/architecture/13-lead-operating-manual.md` создаётся при bootstrap (фаза 0) по этому шаблону. ИИ-агенты ОБЯЗАНЫ дополнять его при добавлении инфраструктурных элементов (см. промпт 3 в разделе 4.3).

````markdown
# 13. Руководство Лида (Lead Operating Manual)

> **Для ИИ-агентов:** Этот файл содержит операционный регламент Лида проекта.
> Если в ходе выполнения задачи вы внедряете новые компоненты, меняете
> инфраструктуру или логику системы, вы ОБЯЗАНЫ дописать в соответствующие
> разделы этого файла инструкции, метрики и алерты для Лида.

---

## 1. Ежедневный / Еженедельный регламент (Что смотреть)

- [ ] **Ревизия архитектурного долга:** проверить главу
      `11-technical-risks.md` на наличие критических тикетов.
- [ ] **Анализ логов и ИИ-активности:** проверить, не зацикливаются ли
      кодинг-агенты на однотипных багах.
- [ ] **Архитектурный радар:** раз в неделю отсматривать новые ADR,
      созданные агентами в `docs/architecture/adr/`.

---

## 2. Метрики Системы (Health Check)

| Компонент / Сервис | Метрика | Что искать / Критический порог | Действие при аномалии |
|---|---|---|---|
| **Азимут-ядро** | `index_time_per_module` | > 2 сек на модуль на реальной ERP | Проверить, не упёрлись ли в symbol fallback из `vector_indexer.py`; см. ADR 0024 |
| **MCP-оркестратор** | `faithfulness_score` | < 0.80 за прошедшие 24ч | Запустить судью (ADR 0003) на последних 50 ответах; проверить иерархию источников (ADR 0006) |
| **LLM-судья** | `llm_judge_disagreement_rate` | > 30% несовпадений с relevance | Проверить П1 детектор (ADR 0008) — возможно, режим «relevance высокий / groundedness низкий» |
| **Sentry / GlitchTip** | `5xx_rate` MCP-сервера | > 1% от общего трафика | Смотреть кампанию ошибок: чанкер / реранкер / адаптер LLM |
| *[Место для новых компонентов]* | *[Авто-метрика]* | *[Порог]* | *[Инструкция]* |

---

## 3. Инструкции по триажу Алертов (Действия при сбоях)

Когда срабатывает мониторинг, действовать строго по регламенту.

### Сбой А: Высокий latency на запросах по коду

1. Зайти в систему мониторинга, отфильтровать по `mcp.search_by_code`.
2. Проверить статус Qdrant (см. workspace.dsl связь
   `mcp-orchestrator -> qdrant`).
3. Если Qdrant в порядке — проверить адаптер LLM (DeepSeek доступен из РФ?
   см. ADR 0021).
4. Фолбэк-режим (ADR 0007): дип-ресёрч с пометкой «не из локального индекса».

### Сбой Б: Метрика противоречивости (ADR 0001) выросла > 10%

1. Открыть Sentry → группу `contradiction_metric_high`.
2. Проверить иерархию источников (ADR 0006) — не сломалась ли разметка
   «код / справка / ИТС».
3. Если разметка ОК — поднять П1 детектор (ADR 0008) на эталонных вопросах.

### *[Сюда агенты будут дописывать новые алерты при добавлении сервисов]*

---

## 4. Протокол LLM-ресерчей

См. `.github/prompts/research-with-llm.md` (раздел 4.4 этого плана).
Краткая выжимка для повседневной работы:

1. **Инициализация:** скинуть в LLM `workspace.dsl` +
   `02-architecture-constraints.md`.
2. **Запрос:** сформулировать задачу.
3. **Критика:** попросить LLM найти 3 слабых места в её решении.
4. **Фиксация:** потребовать готовый ADR + кусок DSL.

---

## 5. Задачи на ручной контроль (Пул задач Лида)

- [ ] Раз в неделю — пересмотреть открытые ADR (`status: proposed`)
      и решить, какие переводим в `accepted` или `rejected`.
- [ ] Перед каждым большим релизом — пройти главу 11 (Risks) и пометить,
      какие риски сняты.
- [ ] Раз в месяц — сверить v1.x-карту задач
      (`_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md`)
      с фактической реализацией, чтобы убедиться, что мы ничего не упустили.
- *[Здесь добавляются ситуативные пункты при добавлении сервисов]*

---

*Шаблон главы 13 — версия 2026-05-27 (HLE-495). Обновляется ИИ-агентами
при каждом инфраструктурном изменении.*
````

---

## 5. Сводка для отчёта в Linear

- **Целевых артефактов:** 23
  - `workspace.dsl` (1, корень репо — единый источник статичных C4-views; ADR 0034).
  - `.github/prompts/{pr-architecture-lint,pr-adr-check,pr-lead-manual-check,research-with-llm}.md` (4 промпта для ИИ-агента-ревьюера и LLM-ресерчей; раздел 4).
  - `docs/index.md` (1, короткий мини-README со ссылкой на §1).
  - `docs/architecture/README.md` (1, путеводитель по папке для людей и ИИ-агентов).
  - `docs/architecture/01..12.md` (12 глав arc42).
  - `docs/architecture/13-lead-operating-manual.md` (1, наше расширение — регламент Сергея).
  - `docs/architecture/adr/template.md` (1, шаблон MADR — не ADR, не считается в нумерации).
  - `docs/cases/01-document-changed-account.md` (1, эталонный кейс).
  - `docs/roadmap.md` (1, фазы реализации + архив v1.x).
- **ADR в плане:** 34 (полный список с шапками — раздел 3), разложены по 5 подпапкам `docs/architecture/adr/{anti-hallucinations,foundation,code-processing,tooling,open}/`.
  - `anti-hallucinations/` — 10 ADR (Р1, Р2, Р3, Р4 как «надгробие», Р5, Р6, Р7, П1, П2, П3).
  - `foundation/` — 13 ADR (реш. 1.1, имя «Азимут», 1.2, 1.3, 1.4, 1.5, 1.6, 1.7→superseded, 1.7a, 1.8, 1.8a, 1.9, 1.10).
  - `code-processing/` — 4 ADR (реш. 2.1, 2.2 proposed, 2.3 accepted после утверждения 2026-05-27, 2.4).
  - `tooling/` — 1 ADR (0034 — Architecture-as-Code via Structurizr DSL, accepted 2026-05-27).
  - `open/` — 6 ADR со статусом `proposed/open` (Sentry × AGPL, 4 развилки мульти-аренды, механика Р1).
  - **По статусам:** `accepted` — 26 (+0034 Structurizr DSL), `proposed` — 7 (П1, П2, П3, 0025 резолв одноимённых, 0028 Sentry, 0033 механика Р1) + 4 open для мульти-аренды (0029–0032), `superseded` — 2 (Р4 → Р7, 1.7 → 1.7a).
- **Источников полностью покрыто:** все 17 страниц Notion + все 61 issue Linear (16 «Переписываем ТЗ» + 45 «Агент-консультант по 1С ERP») + все вложения (HLE-456..464/result+notes) + 4 проектных документа в `_project-docs/`. Спецификации (`_source/specs/`) и meta-летопись (`_crosscheck.md`, `_resolutions.md`, манифесты) явно помечены как «остаются в `_source/`, не мигрируются».
- **Флаги для Сергея:**
  1. Перед архивированием `karta-zadach-i-arhitekturnye-resheniya-aktualno.md` (v1.x) — сверить с `design-system-v2`, чтобы не упустить требований.
  2. Темы 3–7 пока имеют только placeholder-и в `roadmap.md` + 5 open-ADR. Дополнительные ADR появятся при работе над HLE-415..419.
  3. ADR 0025 (резолв одноимённых) — `proposed`; алгоритм не написан, утверждаем вместе с реализацией при работе над темой 2 (HLE-414). ADR 0026 (роутинг graph→metadata→grep) утверждён 2026-05-27 (синтез HLE-461 = решение, переведён в `accepted`).
  4. `docs/architecture/adr/` структурируется подпапками с самого начала: `anti-hallucinations/`, `foundation/`, `code-processing/`, `tooling/`, `open/`. Нумерация ADR сквозная (`0001`–`0034`), не локальная по подпапкам — это убирает риск коллизий при переезде ADR между темами. `template.md` лежит в `adr/` рядом с подпапками, без номера.
  5. **Architecture-as-Code (Structurizr DSL)** введён ADR 0034 как новая практика: статичные C4 переезжают из Mermaid в `workspace.dsl`, Runtime sequence остаётся в Mermaid. Bootstrap (создание `workspace.dsl` с верхнеуровневой моделью + `docs/architecture/README.md` + 12 arc42-глав + `13-lead-operating-manual.md` по шаблону из раздела 4.5 + `template.md` + пустые подпапки `adr/research/` + 4 промпта в `.github/prompts/`) — первая задача roadmap-фазы 0 после утверждения плана.
  6. **Полный arc42 (12 глав) + наша глава 13.** Подробности — раздел 1 mapping таблицей. Это апгрейд относительно ранней версии плана (раньше 5 файлов). Мотивация — предсказуемое место для каждого вида знания (важно для ИИ-агентов и Structurizr Lite, который встраивает arc42-главы в портал).
  7. **Раздел 4 «Процесс и автоматизация»** — DoD, CI/CD (вариант А — Mermaid-генерация в GitHub Actions / вариант Б — постоянный Structurizr Lite), 3 PR-промпта и протокол LLM-ресерчей, шаблон главы 13. Это не ADR, а операционное руководство.

*Создано 2026-05-27 для HLE-495. После утверждения Сергеем — `Done`. Без утверждения — `In Review`.*
