---
status: accepted
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "`_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md` §«Название проекта/форка»"
implemented-in: "README репо; `COPYRIGHT` в корне репо"
related-to: "[0011](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md)"
supersedes: ""
superseded-by: ""
---

# Имя форка/проекта — «Азимут» / `azimuth`

## Context and Problem Statement

Форк `bsl-atlas` получает новое имя. Имя должно отражать суть продукта — «навигация по коду», наследовать смысловой ряд `bsl-atlas`, не совпадать с существующими проектами и быть пригодным как slug репозитория.

## Decision Drivers

* Имя должно передавать смысл «направление / карта, где искать».
* Не копировать `atlas` буквально — форк развивает концепцию, а не клонирует бренд.
* Атрибуция автору `bsl-atlas` (Arman Kudaibergenov) — отдельно в README + NOTICE/CREDITS, на название не влияет.
* Slug пригоден для GitHub-репозитория и PyPI-пакета.

## Considered Options

* **`azimuth` / «Азимут»** — навигационный термин: азимут задаёт направление поиска.
* **`bsl-compass`** — другой навигационный термин, менее благозвучен по-русски.
* **`bsl-navigator`** — более буквальный, хуже как slug.

## Decision Outcome

Chosen option: **«Азимут» / `azimuth`**, because слово задаёт «направление/карту, где искать» — ровно то, что делает продукт. Наследует навигационный смысловой ряд `atlas`, не копируя бренд. Имя свободно, пригодно как slug, читается по-русски и по-английски.

### Consequences

* Good, because имя сразу объясняет суть продукта без технических аббревиатур.
* Good, because простой slug `azimuth` — лёгкий для URL, пакетов, docker-образов.
* Bad, because слово «азимут» может быть незнакомо части аудитории, но это компенсируется одной фразой в README.

### Confirmation

Имя закреплено в `README` репо и в поле `name` файла `COPYRIGHT`. Атрибуция `bsl-atlas` присутствует в `README` + `NOTICE/CREDITS` (требование AGPL-3.0 + OSS-гигиена).

## Pros and Cons of the Options

### `azimuth` / «Азимут»

* Good, because навигационный смысл точно соответствует функции.
* Good, because краткий, уникальный slug.
* Bad, because специализированный термин — требует одного объяснения в README.

### `bsl-compass`

* Good, because тоже навигационный.
* Bad, because менее благозвучен в русском контексте.

### `bsl-navigator`

* Good, because интуитивно понятен.
* Bad, because длинный slug, слишком буквальный.

## More Information

* `_source/notion/design-system-v2--*.md` §«Название проекта/форка» — обоснование Сергея.
* Атрибуция автору `bsl-atlas` — в `README` репо и `NOTICE/CREDITS` (создаётся при публикации релиза, ADR 0023).
