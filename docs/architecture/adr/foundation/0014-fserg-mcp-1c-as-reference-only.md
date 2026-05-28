---
status: "accepted"
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "`_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md` реш. 1.3; `_source/notion/hle-460-fserg-chunking-qdrant--36c0c905e626814385a2c7259a3d0c0c.md` (MIT подтверждён); `_source/_resolutions.md` §#3"
implemented-in: "`docs/architecture/05-building-block-view.md` §«Хранилище» (payload-схема и RRF — лекало из FSerg)"
related-to: "[0024](../code-processing/0024-code-chunking-deterministic-structural.md)"
supersedes: ""
superseded-by: ""
---

# `FSerg/mcp-1c-v1` — референс архитектуры, не кодовая основа (берём идеи payload-схемы и RRF, код не копируем)

## Context and Problem Statement

`FSerg/mcp-1c-v1` — ближайший публичный аналог Азимута: MCP-сервер с RAG по структуре конфигурации 1С (~152★, Qdrant + RRF, Docker Compose). Нужно решить: брать его как кодовую основу, как референс или не использовать вовсе? Вопрос осложнялся неверной ранней пометкой «LICENSE НЕТ» (опровергнута аудитом HLE-460).

## Decision Drivers

* Лицензия должна быть ясной и совместимой с AGPL-3.0.
* Стек и задача должны совпадать с нашими — иначе переиспользование кода даст больше проблем, чем пользы.
* Ценные архитектурные идеи (RRF, payload-схема) не должны теряться только из-за несовместимости стека.
* Ошибки в атрибуции лицензий недопустимы — правило источников (`_source/_resolutions.md` §#3).

## Considered Options

* **Референс архитектуры** — берём только идеи (payload, RRF), реализуем свои на Python.
* **Кодовая основа** — форкаем `FSerg/mcp-1c-v1` и переписываем под наш стек.
* **Игнорировать полностью** — не смотреть вообще.

## Decision Outcome

Chosen option: **«Референс архитектуры»**, because лицензия MIT разрешает использование и копирование кода (Copyright (c) 2025 Sergey Filkin, ✅ проверено по `HLE-460`), но **архитектурно код всё равно не берём**: TypeScript-стек несовместим с нашим Python, а главное — `FSerg/mcp-1c-v1` индексирует только метаданные структуры конфигурации, не тексты BSL-модулей. Это не закрывает наш Приоритет №1 (понимание кода). Берём ценные идеи, реализуем своё.

**Что берём (идеи, не код):**
- Схема payload для метаданных конфигурации (поля `object_name`, `object_type`, `friendly_name`, `doc`).
- Паттерн RRF через Qdrant `Prefetch + FusionQuery(fusion=Fusion.RRF)` — готовый образец API.
- `PREFETCH_LIMIT_MULTIPLIER`: брать 2–5× кандидатов на prefetch, RRF сортирует.
- `on_disk=True` для векторов — экономия RAM на слабой машине.
- Разделение задач эмбеддинга: `task=retrieval.passage` / `task=retrieval.query`.

**Что не берём:**
- Подход «1 объект = 1 чанк без нарезки» — у нас тексты BSL, нужна реальная резка по функциям.
- TypeScript-код — несовместимый стек.
- Эмбеддер `all-MiniLM-L6-v2` — слабее BGE-M3 для нашей задачи.

### Consequences

* Good, because MIT лицензия подтверждена — атрибуция при явном заимствовании кода обязательна, но мы берём только идеи.
* Good, because ценные паттерны (RRF-образец, payload-схема) войдут в ADR 0024 как reference.
* Good, because исправлена ошибочная пометка «LICENSE НЕТ» — `_resolutions.md` §#3 зафиксировал правильное состояние.
* Bad, because заимствование только идей требует самостоятельной реализации — нельзя просто «взять код».

### Confirmation

В `docs/architecture/05-building-block-view.md` §«Хранилище» есть явная отсылка: «payload-схема и RRF по лекалу `FSerg/mcp-1c-v1` (MIT, Copyright (c) 2025 Sergey Filkin)». ADR 0024 (чанкинг) содержит секцию «Источники идей» с атрибуцией.

## Pros and Cons of the Options

### Референс архитектуры (выбрано)

* Good, because берём ценные паттерны без стекового конфликта.
* Good, because не копируем TypeScript-код в Python-проект — меньше технического долга.
* Bad, because больше работы: нужно самостоятельно реализовать RRF и payload-схему.

### Кодовая основа

* Good, because можно взять рабочий код как стартовую точку.
* Bad, because TypeScript → Python: переиспользование кода практически нулевое.
* Bad, because проект индексирует только метаданные структуры, не тексты BSL — нужна полная переработка.

### Игнорировать полностью

* Good, because нет зависимости.
* Bad, because теряем ценный образец RRF-реализации и payload-схему.

## More Information

* `_source/notion/hle-460-fserg-chunking-qdrant--*.md` — детальный разбор chunking-стратегии и Qdrant-схемы `FSerg/mcp-1c-v1`.
* `_source/_resolutions.md` §#3 — история ошибки «LICENSE НЕТ» и её исправление.
* `_source/notion/design-system-v2--*.md` реш. 1.3 и 1.10 — обоснование + лицензионный чек-лист.
* ADR 0024 — где идеи FSerg конкретно применены (payload-схема Qdrant, RRF-слияние).
