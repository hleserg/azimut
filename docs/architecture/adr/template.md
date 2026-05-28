---
status: "proposed | accepted | rejected | deprecated | superseded by NNNN"
date: YYYY-MM-DD
decision-makers: "[Сергей]"
linear-task: "HLE-XXX"
basis: "ссылка на _source/notion/*.md или _source/linear/*.md или HLE-XXX"
implemented-in: "docs/architecture/NN-*.md §«...»; workspace.dsl Container/Component «...»"
related-to: "[NNNN](../подпапка/NNNN-kebab-title.md)"
supersedes: ""
superseded-by: ""
---

# {Короткий заголовок, описывающий решение}

## Context and Problem Statement

{Опиши контекст и проблему 2–3 предложениями. Что мы решаем? Почему нужно решение именно сейчас? Можно сослаться на компонент из workspace.dsl.}

## Decision Drivers

* {фактор 1 — желаемое качество, ограничение, требование}
* {фактор 2}

## Considered Options

* {вариант 1}
* {вариант 2}
* {вариант 3}

## Decision Outcome

Chosen option: "{вариант 1}", because {обоснование — почему именно он, какой из decision drivers он закрывает}.

### Consequences

* Good, because {положительное следствие}
* Bad, because {отрицательное следствие}

### Confirmation

{Как мы убедимся, что решение реализовано правильно? Например: `docker compose --profile diagrams up -d structurizr-proxy` рендерит новые views; CI-линт проходит; тест в CI зелёный.}

## Pros and Cons of the Options

### {вариант 1}

* Good, because {аргумент а}
* Bad, because {аргумент б}

### {вариант 2}

* Good, because {аргумент а}
* Bad, because {аргумент б}

## More Information

{Дополнительные ссылки, контекст, история обсуждения. Ссылки на related-to ADR, на research в `docs/architecture/research/`, на Linear-issues.}
