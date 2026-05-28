# Азимут — документация

Точка входа для людей и ИИ-агентов.

Начни с **[`docs/architecture/01-introduction-and-goals.md`](architecture/01-introduction-and-goals.md)** — там назначение системы, стейкхолдеры и top quality goals.

## Навигация

| Что ищешь | Куда идти |
|---|---|
| Архитектура (arc42, 12 глав + глава 13) | [`docs/architecture/`](architecture/README.md) |
| C4-диаграммы (Context / Container / Component) | [`workspace.dsl`](../workspace.dsl) → `docker run --rm -p 8080:8080 -v .:/usr/local/structurizr --user $(id -u):$(id -g) structurizr/structurizr` |
| Архитектурные решения (ADR, MADR) | [`docs/architecture/adr/`](architecture/adr/) |
| Эталонные кейсы | [`docs/cases/`](cases/) |
| Промпты для ИИ-агентов и ревьюера | [`.github/prompts/`](../.github/prompts/) |
| Операционный регламент Лида | [`docs/architecture/13-lead-operating-manual.md`](architecture/13-lead-operating-manual.md) |
| Как написана документация | [`docs/_source/specs/_howto.md`](_source/specs/_howto.md) |

## Быстрый старт Structurizr (on-prem, local-режим)

```bash
docker run --rm -p 8080:8080 -v .:/usr/local/structurizr --user $(id -u):$(id -g) structurizr/structurizr
```

Открыть `http://localhost:8080`.
