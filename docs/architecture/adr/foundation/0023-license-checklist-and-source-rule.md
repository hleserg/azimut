---
status: accepted
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "_source/notion/design-system-v2--*.md реш. 1.10; LICENSE (AGPL-3.0); COPYRIGHT"
implemented-in: "docs/architecture/08-cross-cutting-concepts.md §«Лицензии и атрибуция»; CI (pip-licenses или аналог)"
related-to: "[0011](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md), [0014](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0014-fserg-mcp-1c-as-reference-only.md), [0028](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/open/0028-sentry-vs-agpl.md)"
supersedes: ""
superseded-by: ""
---

# Лицензионный чек-лист OSS под AGPL-3.0 + правило источников («✅ проверено: <файл/url>» или «⚠️ предположение»)

## Context and Problem Statement

Азимут — форк bsl-atlas (AGPL-3.0). Open source — это цель, не риск. При этом проект
использует компоненты с разными лицензиями, и ошибка в лицензионной оценке может
сделать весь проект нераспространяемым. Одновременно в ходе исследований накопились
утверждения («у этого репо нет лицензии», «MIT», «Non-Commercial»), часть которых
оказалась ошибочной. Нужны: (1) верифицированный чек-лист зависимостей; (2) правило,
отличающее проверенный факт от предположения.

## Decision Drivers

* AGPL-3.0 накладывает требования на зависимости: GPL-совместимые — ОК, проприетарные — нет
* Ошибочные лицензионные утверждения уже были (FSerg/mcp-1c-v1 ошибочно числился «без лицензии» — на деле MIT; исправлено в `_resolutions.md` #3)
* При добавлении новой зависимости нужен однозначный процесс верификации
* Автоматизация в CI: `pip-licenses` ловит новые зависимости без ручного ревью
* Правило источников должно работать не только для лицензий, но для любых фактических утверждений в `_source/`

## Considered Options

* Неформальный чек-лист в README без автоматизации
* Формализованный чек-лист в ADR + автоматический `pip-licenses` в CI + правило источников
* Полный SPDX-файл с машиночитаемым манифестом

## Decision Outcome

Chosen option: "Формализованный чек-лист в ADR + pip-licenses в CI + правило источников", because это минимально необходимый уровень для OSS-проекта с AGPL-зависимостями; SPDX-манифест — следующий шаг при росте числа зависимостей.

### Чек-лист зависимостей (состояние на 2026-05-26)

| Компонент | Лицензия | Статус | Использование |
|---|---|---|---|
| bsl-atlas (Arman Kudaibergenov) | AGPL-3.0 | ✅ проверено: `LICENSE`, `COPYRIGHT` | Форк-ядро; attribution в `README` + `NOTICE` |
| tree-sitter-bsl | MIT | ✅ проверено: LICENSE репо | pip-зависимость |
| alkoleft/mcp-bsl-platform-context | MIT | ✅ проверено: LICENSE репо | pip/docker-зависимость |
| FSerg/mcp-1c-v1 (Sergey Filkin) | MIT | ✅ проверено: LICENSE репо (исправление: ранее числился «без лицензии», опровергнуто 2026-05-26, см. `_resolutions.md` #3) | Референс техник, не зависимость |
| 1c-syntax / BSL Language Client | GPL / LGPL | ✅ проверено: LICENSE репо | Subprocess-вызов (не линковка) — GPL-совместимо при subprocess |
| Cherry Studio | AGPL-3.0 + коммерческая dual | ✅ проверено: LICENSE репо | Клиент (не зависимость рантайма сервера) |
| hawkxtreme/mini-ai-1c | Attribution Non-Commercial | ✅ проверено: LICENSE репо | ❌ Код брать нельзя; только архитектурные идеи |
| DitriXNew/EDT-MCP | GNU AGPL v3.0 | ✅ проверено: LICENSE репо (Copyright 2026 DitriX) | Кандидат внешнего MCP (тема 7); код совместим |
| BGE-M3 (FlagEmbedding) | Apache 2.0 | ✅ проверено: LICENSE репо | pip-зависимость; Apache 2.0 совместима с AGPL |
| Qdrant | Apache 2.0 | ✅ проверено: LICENSE репо | docker-зависимость |

**Неподтверждённые (требуют проверки перед использованием):**

| Компонент | Статус |
|---|---|
| ROCTUP/1c-buddy | ⚠️ предположение: лицензия не подтверждена на 2026-05-26 — сверить LICENSE репо перед любым использованием |

### Правило источников

Любое фактическое утверждение в документации `_source/`, ADR или arch42-главах должно быть помечено одним из двух маркеров:

- **`✅ проверено: <файл/url>`** — факт подтверждён в указанном первичном источнике
- **`⚠️ предположение`** — факт не проверен в первичном источнике; требует верификации перед принятием решения

Утверждения без маркера считаются предположениями при ревью.

### Attribution bsl-atlas

`README.md` и `NOTICE` содержат: `Copyright (C) 2026 Arman Kudaibergenov. Originally licensed under AGPL-3.0.`

### Consequences

* Good, because чек-лист фиксирует верифицированное состояние на дату — будущий аудит видит, что проверялось
* Good, because `pip-licenses` в CI ловит новые AGPL/GPL-зависимости автоматически, не требуя ручного ревью
* Good, because правило источников предотвращает накопление непроверенных утверждений (прецедент с FSerg/mcp-1c-v1)
* Bad, because чек-лист устаревает при добавлении зависимостей — митигируется CI-автоматизацией
* Bad, because subprocess-граница для GPL-компонентов требует осторожности при рефакторинге (нельзя превратить subprocess в линковку)

### Confirmation

`pip-licenses --fail-on "GPL" --allow-only "MIT;Apache 2.0;AGPL-3.0;BSD"` (или эквивалент) запускается в CI. `README.md` содержит attribution bsl-atlas. `NOTICE` существует. `08-cross-cutting-concepts.md` §«Лицензии и атрибуция» содержит краткий свод этого ADR.

## Pros and Cons of the Options

### Чек-лист в ADR + pip-licenses + правило источников (выбрано)

* Good, because минимальный overhead при максимальном покрытии рисков для текущего масштаба
* Good, because правило источников решает проблему шире лицензий — любые факты в документации
* Bad, because pip-licenses не покрывает docker-образы и JS-зависимости (Cherry Studio) — ручной ревью для них

### Неформальный чек-лист в README

* Good, because быстро
* Bad, because не обновляется при добавлении зависимостей; нет истории верификации

### SPDX-манифест

* Good, because машиночитаем, стандарт индустрии
* Bad, because избыточен при текущем числе зависимостей; добавляем при росте

## More Information

Реш. 1.10 из `_source/notion/design-system-v2--*.md`.
Исправление ошибки «FSerg без лицензии» → `_source/_resolutions.md` #3.
Форк bsl-atlas → ADR [0011](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md).
FSerg как референс, не зависимость → ADR [0014](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0014-fserg-mcp-1c-as-reference-only.md).
Sentry × AGPL → ADR [0028](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/open/0028-sentry-vs-agpl.md).
Конкурентный анализ лицензий (mini-ai-1c / 1c-buddy / EDT-MCP) → `_source/notion/hle-458-mini-ai-1c-competitors--*.md`.
