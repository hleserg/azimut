---
status: proposed
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413, HLE-314, HLE-318, HLE-319"
basis: "`docs/_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md` §«Конфликт AGPL × Sentry for Open Source»; `docs/_source/linear/agent-konsultant-po-1s-erp/HLE-314.md`"
implemented-in: "`docs/architecture/08-cross-cutting-concepts.md` §«Мониторинг» (план Б — GlitchTip/self-host Sentry/Prometheus+Grafana)"
related-to: "[0011](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md), [0023](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0023-license-checklist-and-source-rule.md)"
supersedes: ""
superseded-by: ""
---

# Конфликт AGPL × Sentry for Open Source — ждём ответ Sentry; если откажут — план Б

## Context and Problem Statement

Проект «Азимут» — форк `bsl-atlas` (AGPL-3.0). Мониторинг ошибок планировался через **Sentry for Open Source** (бесплатный грант от Sentry): HLE-314 получил грант, HLE-315/318/319 настраивали инструментацию и workflow. Однако страница [sentry.io/for/open-source](https://sentry.io/for/open-source) требует «friendly license like Apache or MIT». AGPL-3.0 — самый строгий copyleft с сетевым пунктом §13; формально OSI-одобрена, но «friendly» не считается. Возник структурный конфликт: форк `bsl-atlas` обязывает нас быть AGPL (copyleft от родителя), а Sentry хочет permissive. Перелицензировать Азимут нельзя — это потребует переписать ядро с нуля. Нужно решить: идём ли через официальный запрос к Sentry или сразу переходим к плану Б.

## Decision Drivers

* ADR 0011 зафиксирован: форк `bsl-atlas` важнее гранта Sentry — это неизменяемый якорь.
* Kanareika/мониторинг (задача 0c) уже завязаны на Sentry DSN и workflow; при плане Б переориентируются на другой инструмент.
* Принцип проекта — OSS с открытым кодом, монетизации через закрытость нет; платные Sentry-планы не рассматриваются.
* Self-hosted решения должны вписываться в минимальную RAM-конфигурацию (машина мамы / локальный деплой).
* Правило источников (ADR 0023): лицензии альтернатив проверять по файлу, не по памяти.

## Considered Options

* **План А (текущий)** — запросить Sentry напрямую, объяснить что AGPL = OSS, грант одобряют люди, не автомат.
* **План Б1 — GlitchTip** — Sentry-совместимый SDK, OSS, self-hosted.
* **План Б2 — Self-hosted Sentry** — официальный self-hosted пакет (`getsentry/self-hosted`).
* **План Б3 — Prometheus + Grafana + Loki** — стек без error-tracking, только метрики и логи.

## Decision Outcome

Chosen option: **«Ждём ответ по плану А; если откажут — план Б1 (GlitchTip)»**, because запрос к людям в Sentry — нулевые затраты при реальном шансе одобрения (формулировка «friendly like» — мягкая рекомендация, не автоматический фильтр). Если откажут, форк bsl-atlas всё равно не переоткрывается — берём GlitchTip как наиболее близкий аналог (Sentry-совместимый SDK, self-hosted, без платных планов). Принцип «канарейка сигналит до раздражения пользователя» сохраняется в любом варианте; меняется только инструмент.

### Consequences

* Good, because план А может полностью закрыть вопрос без смены стека.
* Good, because план Б1 (GlitchTip) совместим с существующим Sentry SDK — переключение минимально.
* Bad, because до получения ответа Sentry HLE-315/318/319 остаются в подвешенном состоянии (не закрываем, не форсируем).
* Bad, because self-hosted Sentry (план Б2) требует 16 GB RAM — исключён для локального деплоя.
* Bad, because лицензия GlitchTip не проверена по файлу на момент принятия решения (⚠️ предположение — сверить перед выбором).

### Confirmation

ADR переходит в `accepted` когда: (а) получен ответ от Sentry (любой), (б) выбран финальный инструмент мониторинга, (в) лицензия инструмента проверена по файлу. До этого статус `proposed` — задачи HLE-315/318/319 в Hold.

## Pros and Cons of the Options

### План А — запрос в Sentry

* Good, because нулевые затраты, нет смены стека, сохраняет уже настроенный DSN/workflow.
* Bad, because нет гарантии одобрения — «friendly» трактуется Sentry как permissive.
* Bad, because неопределённость блокирует HLE-315/318/319.

### План Б1 — GlitchTip (self-hosted)

* Good, because Sentry-совместимый SDK — миграция минимальна.
* Good, because open source, self-hosted, нет vendor lock-in.
* Bad, because лицензия ⚠️ не проверена по файлу (GitLab repo).
* Bad, because дополнительный сервис к инфраструктуре.

### План Б2 — Self-hosted Sentry (`getsentry/self-hosted`)

* Good, because идентичный Sentry интерфейс и SDK.
* Bad, because ✅ FSL (проверено: `getsentry/self-hosted master/LICENSE.md`) — не OSI, с non-compete; для нашего кейса (не конкурент Sentry) технически допустимо.
* Bad, because минимальные требования 16 GB RAM — несовместимо с локальным деплоем для мамы.

### План Б3 — Prometheus + Grafana + Loki

* Good, because гибкий стек метрик и логов, MIT/Apache лицензии.
* Bad, because нет error-tracking с group-by и stacktrace — принципиальная потеря возможности.
* Bad, because дублирует Langfuse (который рассматривается для трейсов в теме 6).

## More Information

* `docs/_source/notion/design-system-v2--*.md` §«Конфликт AGPL × Sentry» — исходная фиксация ситуации.
* `docs/_source/_resolutions.md` §«Что НЕ изменилось» — форк важнее гранта, зафиксировано явно.
* ADR 0011 — почему форк `bsl-atlas` является неизменяемым якорем.
* ADR 0023 — правило проверки лицензий по файлу перед выбором компонента.
* HLE-314 (Done) — история получения Sentry-гранта (до обнаружения конфликта).
* HLE-315, HLE-318, HLE-319 — задачи инструментации, в Hold до закрытия этого ADR.
