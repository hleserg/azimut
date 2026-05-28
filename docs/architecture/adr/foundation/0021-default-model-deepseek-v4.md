---
status: accepted
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "_source/notion/design-system-v2--*.md реш. 1.8a"
implemented-in: "docs/architecture/05-building-block-view.md §«Adapter-слой»; конфиг llm.provider"
related-to: "[0020](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md), [0019](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0019-cherry-studio-default-client.md)"
supersedes: ""
superseded-by: ""
---

# Дефолт разговорной модели — DeepSeek V4 (Flash основной, Pro для тяжёлого кода); запас — Claude/Qwen/Yandex; финал валидируем eval-ом в теме 6

## Context and Problem Statement

ADR [0020](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md) определил, что разговорная LLM облачная и
подключается через адаптер. Теперь нужно выбрать конкретный дефолт: какую модель
настраиваем для мамы и Сергея-everyday «из коробки», какую используем для тяжёлых
задач, и что делаем, если основная модель недоступна.

Ключевое ограничение: доступность из России без VPN. Claude (Anthropic) и OpenAI
заблокированы без VPN — не могут быть дефолтом для мамы.

## Decision Drivers

* Доступность из России без VPN (мама не настраивает VPN)
* Качество на задачах 1С: понимание кода, RAG, ответы с контекстом
* Контекстное окно: конфигурации 1С ERP — большие, нужен 1M+ токенов
* Совместимость API: снижает стоимость адаптера (реш. 1.8)
* Бюджет: ~$2–12/месяц на двух пользователей
* Финальный выбор — через eval (тема 6, HLE-420); сейчас фиксируем дефолт для разработки

## Considered Options

* DeepSeek V4 (Flash + Pro) — доступен из России, открытые веса, Anthropic-совместимый API
* Claude (Anthropic) — лучшее качество, но блокирован в России без VPN
* Qwen (Alibaba) — доступен, хорошие показатели на коде, запасной вариант
* Yandex GPT — доступен в России, но слабее на 1С-специфике
* GPT-4o (OpenAI) — блокирован в России без VPN

## Decision Outcome

Chosen option: "DeepSeek V4 Flash как основной, DeepSeek V4 Pro для тяжёлого кода", because это единственная модель топ-уровня с доступностью из России без VPN, совместимым Anthropic API и бюджетом $2–12/мес на двух пользователей.

**Характеристики DeepSeek V4 (✅ проверено: реш. 1.8a, дата 2026-05-26):**

| Параметр | Значение |
|---|---|
| Контекст | 1 000 000 токенов |
| SWE-bench | ~81% (конкурентно с Claude Sonnet) |
| API-совместимость | Anthropic Messages API |
| Доступность РФ | ✅ без VPN |
| Flash (основной) | быстрый, дешёвый — everyday чат, простые запросы |
| Pro (тяжёлый код) | медленнее, дороже — сложный рефакторинг, глубокий анализ |
| Бюджет | ~$2–12/мес за двух пользователей |

**Резервная последовательность:** DeepSeek → Claude (Сергей с VPN / дома) → Qwen → Yandex GPT.

**Финальный выбор:** подтвердим eval-ом в теме 6 (HLE-420); дефолт может смениться по результатам.

### Consequences

* Good, because работает из России без VPN — мама пользуется без настройки
* Good, because 1M-контекст покрывает даже большие конфигурации 1С ERP
* Good, because Anthropic-совместимый API — адаптер (реш. 1.8) минимален
* Good, because бюджет $2–12/мес по силам до первых клиентских доходов
* Bad, because DeepSeek — китайская компания; риски данных снимаются тем, что в промпт идут только публичные мета-данные конфигурации, не бизнес-данные клиента (см. источниковую иерархию Р6)
* Bad, because Flash может не справиться с самыми сложными задачами — поэтому Pro как явный апгрейд, не по умолчанию

### Confirmation

`config.yaml` содержит `llm.provider: deepseek` и `llm.model: deepseek-chat-v4-flash` как дефолт; Pro подключается через `llm.model: deepseek-chat-v4-pro` или env-override. Eval в теме 6 зафиксирует финальный выбор.

## Pros and Cons of the Options

### DeepSeek V4 Flash/Pro (выбрано)

* Good, because доступен из России без VPN
* Good, because 1M контекст, ~81% SWE-bench, Anthropic API
* Good, because дешевле Claude при сопоставимом качестве на коде
* Bad, because китайская юрисдикция — принято как приемлемый риск при текущем масштабе

### Claude (Anthropic)

* Good, because лучшее качество понимания кода
* Good, because Anthropic API — нулевые изменения адаптера
* Bad, because блокирован в России без VPN — не подходит маме
* Bad, because дороже DeepSeek

### Qwen (Alibaba)

* Good, because доступен из России, сильные показатели на коде
* Bad, because менее зрелая документация, меньше данных о production-использовании на 1С

### Yandex GPT

* Good, because доступен в России, русский язык
* Bad, because слабее на задачах понимания кода по сравнению с DeepSeek/Claude

## More Information

Реш. 1.8a из `_source/notion/design-system-v2--*.md`.
Адаптерный слой → ADR [0020](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md).
Клиент Cherry Studio, через который DeepSeek подключается → ADR [0019](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0019-cherry-studio-default-client.md).
Финальная валидация — eval-харнесс, тема 6 HLE-420.
