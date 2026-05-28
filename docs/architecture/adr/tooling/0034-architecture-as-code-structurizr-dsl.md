---
status: "accepted"
date: 2026-05-27
decision-makers: "[Сергей]"
linear-task: "HLE-495"
basis: "Инструкция Сергея в HLE-495 (Шаги 1–6 «Architecture as Code via Structurizr DSL + C4 Model»); `docs/_source/specs/c4/c4model-diagrams.md`; `docs/_source/specs/_howto.md` §2; документация Structurizr DSL и Structurizr Lite"
implemented-in: "`workspace.dsl` в корне репо; локальный просмотр через `structurizr/lite` (Docker, порт 8080)"
related-to: "[0022](../foundation/0022-boundary-fork-vs-own-code.md), [0024](../code-processing/0024-code-chunking-deterministic-structural.md), [0026](../code-processing/0026-code-search-routing.md)"
supersedes: ""
superseded-by: ""
---

# Architecture-as-Code через Structurizr DSL — единый источник статичных C4-диаграмм

## Context and Problem Statement

До 2026-05-27 план предполагал C4-диаграммы через Mermaid `C4Context`/`C4Container` прямо в Markdown-файлах. Это даёт читаемость в GitHub, но создаёт три системные проблемы: (1) каждая диаграмма — копия модели: имена сущностей, технологии и связи дублируются в разных файлах и расходятся при правках; (2) Mermaid C4 экспериментальный — не поддерживает `legend`, `properties`, управление layout, group-по-уровням; (3) нет машинно-читаемого источника для двусторонней трассировки «ADR ↔ компонент» — ИИ-агент не может автоматически найти, какой ADR описывает данный контейнер. Нужна единая текстовая модель с явной типизацией и семантикой связей.

## Decision Drivers

* Единственный источник истины для статичных C4-диаграмм: Context, Container, Component — один файл, одна модель.
* Двусторонняя трассировка: компонент → ADR и ADR → компонент; реализуется через `properties { "adr-link" "..." "open-issues" "..." }`.
* Явная типизация элементов: `Person`, `SoftwareSystem`, `Container`, `Component` — Mermaid это не гарантирует.
* Локальный просмотр для Сергея: один `docker run`, без сборки.
* Совместимость с arc42 §5 (Building Block View) и §3 (Context): диаграммы привязаны к главам doc-as-code.
* Mermaid остаётся для §6 Runtime View (sequenceDiagram): git diff читается лучше DSL Dynamic-views.

## Considered Options

* **Structurizr DSL в `workspace.dsl`** — единый файл, рендеринг через Structurizr Lite (Docker).
* **Mermaid C4 в Markdown** — диаграммы в месте использования, нативный рендер GitHub.
* **PlantUML C4** — матурная, широко используемая нотация; требует Java/PlantUML сервер.
* **draw.io / Lucidchart** — визуальные редакторы, бинарные или XML файлы.

## Decision Outcome

Chosen option: **«Structurizr DSL в `workspace.dsl`»**, because только Structurizr DSL даёт все три свойства одновременно: единый источник модели с явной типизацией, поддержка `properties` для трассировки ADR↔компонент, и локальный рендеринг одним `docker run` без установки инструментов. Mermaid C4 остаётся для Runtime View (§6) — там sequenceDiagram читается лучше в git diff, чем DSL Dynamic-views (которые экспериментальные в Structurizr).

### Consequences

* Good, because единый источник: нет дублирования имён сущностей по разным markdown-файлам.
* Good, because явная типизация (`Person`/`SoftwareSystem`/`Container`/`Component`) — ИИ-агент не угадывает, что что значит.
* Good, because `properties { "adr-link" "..." }` на компонентах — ИИ-ревьюер (промпт 2 из `04-process.md`) может проверить, что каждый компонент имеет ADR.
* Good, because auto-layout из коробки; Component-view только под нужные контейнеры.
* Good, because `docker run -it --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite` — один командный запуск, интерактивный UI в браузере.
* Bad, because зависимость от Java-рантайма у того, кто хочет смотреть без Docker (снимается Structurizr Lite в Docker).
* Bad, because порог входа для людей, первый раз видящих DSL — компенсируется путеводителем `docs/architecture/README.md`.
* Bad, because DSL Dynamic-views (runtime-сценарии) экспериментальные — поэтому Runtime View остаётся Mermaid.

### Confirmation

`workspace.dsl` лежит в корне репо; `docker run -it --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite` поднимается без ошибок; views `systemContext`, `container`, `component` рендерятся; `properties { "adr-link" ... }` присутствует у ключевых элементов (Азимут-ядро, MCP-оркестратор, Qdrant, LLM-судья); CI-линт DSL — отдельная задача roadmap (ADR 0035/0036).

## Pros and Cons of the Options

### Structurizr DSL

* Good, because единственный инструмент с нативной поддержкой `properties` для трассировки ADR.
* Good, because Structurizr Lite — open-source, self-hosted, без vendor lock-in (⚠️ лицензия: Structurizr Lite — проверить по файлу перед production-использованием).
* Good, because экспорт в Mermaid/PlantUML через `structurizr/cli export` — для CI/CD рендеринга.
* Bad, because DSL-файл растёт вместе с архитектурой; нужна дисциплина форматирования.

### Mermaid C4 в Markdown

* Good, because нативный рендер в GitHub без Docker; минимальный порог входа.
* Good, because хорошо читается в PR diff.
* Bad, because C4-блоки в Mermaid экспериментальные: нет `properties`, нет `legend`, нет управления layout.
* Bad, because дублирование: каждый файл — своя копия модели; при переименовании компонента — ручной обход всех файлов.
* Bad, because нет машинно-читаемого источника для трассировки ADR↔компонент.

### PlantUML C4

* Good, because матурный инструмент, широко используется в enterprise.
* Bad, because требует PlantUML-сервер или Java local; нет `properties` в стиле Structurizr.
* Bad, because C4-модель в PlantUML — набор макросов, не семантическая модель.

### draw.io / Lucidchart

* Good, because наглядный визуальный редактор, нет кривой обучения DSL.
* Bad, because файлы XML/binary — не читаются в git diff.
* Bad, because нет машинно-читаемой семантики для трассировки.
* Bad, because vendor lock (Lucidchart); draw.io XML — тяжёлый для ревью.

## More Information

* `docs/_planning/05-rebuild-plan.md` §3.5 — подробное обоснование и контекст принятия решения.
* `docs/_planning/05-rebuild-plan.md` §4.1 — два варианта CI/CD-рендеринга (Mermaid-экспорт через GitHub Actions / Structurizr Lite как внутренний сервер).
* `docs/_planning/05-rebuild-plan.md` §4.2 — DoD: workspace.dsl как обязательная часть PR.
* ADR 0022 — граница «форк vs наш код»: DSL описывает обе стороны границы.
* ADR 0024, ADR 0026 — компоненты Азимут-ядра/MCP-оркестратора; имеют `properties { "adr-link" }` в workspace.dsl.
* Локальный просмотр: `docker run -it --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite` → открыть `http://localhost:8080`.
