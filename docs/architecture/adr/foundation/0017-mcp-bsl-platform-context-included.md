---
status: accepted
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "`_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md` реш. 1.6"
implemented-in: "`docs/architecture/05-building-block-view.md` §«MCP-серверы рядом — справочник платформы»; `workspace.dsl` Container «mcp-bsl-platform-context»"
related-to: ""
supersedes: ""
superseded-by: ""
---

# `alkoleft/mcp-bsl-platform-context` берём в фундамент (drop-in вторым MCP, MIT, бесплатно)

## Context and Problem Statement

Азимут понимает код *конкретной конфигурации* (кастомный BSL — то, что написано в ERP). Но агент также будет работать со встроенным **API платформы 1С** — сигнатурами и поведением глобальных объектов и методов (`Запрос`, `ТаблицаЗначений`, `ПолучитьОбщийМакет()`, `Записать()` и т.д.). Это два разных слоя знания. По платформенным методам облачные LLM склонны галлюцинировать — они видели много типовой 1С, но точные сигнатуры API платформы не фиксировались в документации стабильно. Нужен надёжный источник.

## Decision Drivers

* Закрыть вектор галлюцинаций по API платформы 1С без написания своего компонента.
* Стоимость должна быть минимальной — бесплатно и без написания кода.
* Лицензия совместима с AGPL-3.0.
* Не требует единого шлюза (Claude Desktop тянет несколько MCP-серверов нативно, ADR 0016).

## Considered Options

* **`alkoleft/mcp-bsl-platform-context`** — MIT (~130★), отдаёт через MCP содержимое `shcntx_ru.hbk` (встроенная справка платформы).
* **Написать свой справочник API платформы** — полный контроль над контентом.
* **Не включать** — полагаться на встроенные знания LLM о платформе 1С.

## Decision Outcome

Chosen option: **«`alkoleft/mcp-bsl-platform-context`»**, because закрывает отдельный пласт знания (API платформы) дёшево: MIT (~130★, Koryakin Aleksey 2025, ✅ проверено), ноль кода, drop-in вторым MCP-сервером. Подтверждает правило ADR 0016: несколько MCP-серверов рядом без шлюза — штатный сценарий.

**Что предоставляет:** справочник синтаксиса платформы 1С — содержимое `shcntx_ru.hbk` (встроенная справка): глобальные методы, API объектов типа `Запрос`, `ТаблицаЗначений`, `ОбщийМодуль` и т.д. Агент получает достоверный источник по сигнатурам и поведению платформенных методов.

**Проверить при первом запуске:** версия справки в `shcntx_ru.hbk` соответствует платформе, которой пользуются (иначе сигнатуры разойдутся с реальностью).

### Consequences

* Good, because закрывает вектор галлюцинаций по платформенным API — дёшево и без своего кода.
* Good, because MIT совместима с AGPL-3.0: включение в `docker-compose.yml` не меняет лицензию Азимута.
* Good, because подтверждает ADR 0016: Claude Desktop держит два MCP-сервера нативно.
* Bad, because `shcntx_ru.hbk` обновляется вместе с платформой 1С — нужно следить за версией справки при обновлении платформы.
* Bad, because охватывает только API платформы, не конфигурационный код — для кода конфигурации по-прежнему нужен Азимут.

### Confirmation

`workspace.dsl` Container «mcp-bsl-platform-context» с `properties { "adr-link" "docs/architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md" }` присутствует. В `docker-compose.yml` или конфиге Claude Desktop есть запись о втором MCP-сервере. В `docs/architecture/05-building-block-view.md` §«MCP-серверы рядом» атрибуция: «MIT, Koryakin Aleksey 2025».

## Pros and Cons of the Options

### `alkoleft/mcp-bsl-platform-context` (выбрано)

* Good, because готовый, проверенный (~130★), ноль кода на нашей стороне.
* Good, because MIT — лицензионно чисто.
* Good, because drop-in — настройка в конфиге клиента, не в коде Азимута.
* Bad, because зависим от актуальности `shcntx_ru.hbk` — нужен контроль версии.

### Написать свой справочник

* Good, because полный контроль над контентом и обновлениями.
* Bad, because значительный объём работы по сбору и структурированию справки платформы 1С.
* Bad, because дублирование уже сделанного в `alkoleft/mcp-bsl-platform-context`.

### Не включать

* Good, because нет зависимости.
* Bad, because LLM галлюцинируют по платформенным API — без источника качество ответов по API платформы будет ниже.

## More Information

* `_source/notion/design-system-v2--*.md` реш. 1.6 — обоснование выбора.
* `_source/notion/design-system-v2--*.md` реш. 1.10 — лицензионный чек-лист: MIT (✅ проверено: `master/LICENSE`, Koryakin Aleksey 2025; совместимо с AGPL).
* `workspace.dsl` Container «mcp-bsl-platform-context» — архитектурный элемент.
* ADR 0016 — почему шлюз не нужен (Claude Desktop тянет оба MCP напрямую).
