---
status: proposed
date: 2026-05-25
decision-makers: "[Сергей]"
linear-task: "HLE-419"
basis: "`docs/_source/notion/bsl-atlas-opensource-research--36b0c905e626814fa52ce80b248c4311.md` Пробел 9; `docs/_source/notion/questions--36b0c905e62681a48975d4a2315fbce9.md` §«Изоляция файлового хранилища»; `docs/_source/_resolutions.md` #9"
implemented-in: "`docs/architecture/05-building-block-view.md` §«Хранилище»; `docs/architecture/08-cross-cutting-concepts.md` §«Безопасность/изоляция»"
related-to: "[0029](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md), [0023](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0023-license-checklist-and-source-rule.md)"
supersedes: ""
superseded-by: ""
---

# Изоляция файлового хранилища по тенантам — `/data/{tenant_id}/...` + JWT-инъекция

## Context and Problem Statement

При мульти-аренде у каждой конторы есть своя конфигурация 1С и личная папка документов. Изоляция между конторами обязательна: одна контора не должна видеть файлы, индекс или данные другой. Это касается двух уровней: файловой системы (BSL-дамп, документы, загруженные артефакты) и векторного индекса (Qdrant). Текущий локальный деплой хранит всё в одной плоской папке — это работает для одного пользователя, но ломается при нескольких конторах. Нужно решить: как технически организовать изоляцию, чтобы ошибка в коде одного endpoint'а не раскрыла данные другого тенанта.

## Decision Drivers

* Изоляция данных обязательна по принципам безопасности и как ожидание клиентов VDS.
* JWT с `tenant_id`-клеймом — стандартный подход для multi-tenant FastAPI; один реалм для MCP и веб-морды (ADR 0029, Пробел 11).
* Файловая изоляция через путь (`/data/{tenant_id}/...`) — простая, прозрачная, проверяемая аудитом.
* Qdrant-изоляция через `group_id` payload-фильтр — паттерн Tiered Multitenancy (Пробел 9).
* Локальный деплой (один тенант): `tenant_id` = `"local"`, структура папок та же, без сложности.

## Considered Options

* **`/data/{tenant_id}/...` + FastAPI-зависимость + `group_id` в Qdrant** — файловое дерево по тенанту, в каждом запросе `tenant_id` инжектируется из JWT и прокидывается в фильтры Qdrant и таблицы PostgreSQL.
* **Отдельная коллекция Qdrant на тенанта** — полная изоляция индексов, без cross-tenant фильтров.
* **Отдельная схема/база PostgreSQL на тенанта** — полная изоляция метаданных.
* **Плоское хранилище с программными проверками** — без структурной изоляции, только if-проверки в коде.

## Decision Outcome

Chosen option: **«`/data/{tenant_id}/...` + FastAPI-зависимость + `group_id` в Qdrant»**, because это наиболее проверенный паттерн для multi-tenant FastAPI: `tenant_id` извлекается из JWT один раз в dependency, а дальше прокидывается через весь стек — в пути файлов, в фильтры Qdrant, в WHERE-условия PostgreSQL. Ошибиться в одном месте (не передать `tenant_id`) — тест поймает. Отдельные коллекции Qdrant на тенанта отклонены из-за лимита ~1000 коллекций.

> **Статус ADR: proposed.** Конкретный JWT-реалм, схема авторизации (Keycloak/Auth0/Authlib) и PostgreSQL-схема (одна таблица + `tenant_id` FK vs separate schema) — открытые вопросы темы 7.

### Consequences

* Good, because структурная изоляция на уровне пути к файлам — аудитируема и прозрачна.
* Good, because единая FastAPI-зависимость (`get_tenant_id`) — один контракт для всех endpoint'ов.
* Good, because Qdrant `group_id` + is_tenant-индекс — официальный паттерн, ACORN-фильтрация улучшает recall.
* Good, because для локального деплоя: `tenant_id = "local"`, та же структура, нет специального кода.
* Bad, because программная изоляция через `group_id` требует дисциплины: каждый Qdrant-запрос должен содержать фильтр — риск забыть.
* Bad, because JWT-инфраструктура (реалм, ротация ключей) добавляет операционную сложность.
* Bad, because PostgreSQL-схема (одна таблица с `tenant_id` vs schema-per-tenant) — trade-off по миграциям и производительности, пока открыт.

### Confirmation

ADR переходит в `accepted` когда в теме 7 (HLE-419): реализована FastAPI-зависимость `get_tenant_id`, все Qdrant-запросы содержат `group_id`-фильтр, файловые пути используют `{tenant_id}`, интеграционный тест с двумя тенантами подтверждает изоляцию (запрос тенанта A не видит данные тенанта B).

## Pros and Cons of the Options

### `/data/{tenant_id}/...` + FastAPI dep + `group_id` в Qdrant

* Good, because паттерн хорошо документирован; Qdrant 1.16 Tiered Multitenancy поддерживает нативно.
* Good, because один реалм JWT для MCP и веб-морды — нет дублирования аутентификации.
* Bad, because `group_id`-фильтр должен быть в КАЖДОМ Qdrant-запросе — нужен lint или обёртка.

### Отдельная коллекция Qdrant на тенанта

* Good, because полная изоляция индексов; нет риска cross-tenant запроса.
* Bad, because Qdrant рекомендует не более ~1000 коллекций на экземпляр — не масштабируется.
* Bad, because операционные накладные: создание/удаление коллекций при онбординге/оффбординге тенанта.

### Отдельная схема PostgreSQL на тенанта

* Good, because полная изоляция метаданных; простые миграции на тенанта.
* Bad, because операционная сложность: N тенантов = N схем = N наборов миграций.
* Bad, because избыточно для MVP темы 7.

### Плоское хранилище + программные проверки

* Good, because минимальные изменения существующей структуры.
* Bad, because «безопасность через дисциплину» — один забытый if ломает изоляцию.
* Bad, because не проходит security review; неприемлемо для production.

## More Information

* `docs/_source/notion/bsl-atlas-opensource-research--*.md` Пробел 9 — паттерн `group_id`, ACORN-фильтрация, Tiered Multitenancy, FastAPI-зависимость.
* `docs/_source/notion/questions--*.md` §«Изоляция файлового хранилища» — исходная постановка (добавлена 2026-05-27 по HLE-494 #9).
* `docs/_source/_resolutions.md` #9 — явная фиксация четвёртой развилки мульти-аренды.
* ADR 0029 — Qdrant embedded vs server (режим, в котором работает `group_id`).
* ADR 0023 — правило проверки лицензий; JWT-библиотека и IdP тоже проверяются по файлу.
* HLE-419 (тема 7) — задача, в которой реализуется авторизация, JWT-реалм и изоляция.
