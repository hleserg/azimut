---
status: superseded by 0019
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "_source/notion/design-system-v2--*.md реш. 1.7"
implemented-in: ""
related-to: "[0019](0019-cherry-studio-default-client.md)"
supersedes: ""
superseded-by: "0019"
---

# UX и клиент — свой UI не строим, берём готовый MCP-клиент с облачной разговорной моделью

> **Надгробие.** Это решение принято в общем виде (без выбора конкретного клиента)
> и немедленно уточнено в ADR [0019](0019-cherry-studio-default-client.md), который
> фиксирует Cherry Studio как дефолт-клиент по ролям. Читай 0019 вместо этого ADR.

## Context and Problem Statement

На старте проекта зафиксировали принцип: Азимут — это MCP-сервер, а не приложение
с собственным UI. Разговорный интерфейс обеспечивает готовый MCP-клиент, который
подключает сервер к облачной разговорной модели. Свой UI слишком дорог в разработке
и обслуживании при текущем масштабе (два пользователя).

## Decision Outcome

Chosen option: "Готовый MCP-клиент + облачная разговорная модель", because
это устраняет необходимость поддерживать UI, сохраняет фокус на качестве
RAG/поиска и даёт пользователям привычный чат-интерфейс без дополнительного ПО.

**Уточнён в ADR [0019](0019-cherry-studio-default-client.md):** выбор конкретного
клиента (Cherry Studio, Claude Desktop, mini-ai-1c) по ролям мама/Сергей.

## More Information

Реш. 1.7 из `_source/notion/design-system-v2--*.md`.
