---
status: "accepted"
date: 2026-05-26
decision-makers: "[Сергей]"
linear-task: "HLE-413"
basis: "_source/notion/design-system-v2--*.md реш. 1.7a; _source/notion/hle-458-mini-ai-1c-competitors--*.md"
implemented-in: "docs/architecture/05-building-block-view.md §«Клиент»"
related-to: "[0021](0021-default-model-deepseek-v4.md)"
supersedes: "0018"
superseded-by: ""
---

# Дефолт-клиент по ролям: Cherry Studio (мама/Сергей-everyday) + Claude Desktop (Сергей-премиум дома) + mini-ai-1c (Сергей-захват кода)

## Context and Problem Statement

ADR [0018](0018-mcp-client-no-own-ui.md) зафиксировал принцип «готовый MCP-клиент, не
свой UI». Теперь нужно выбрать конкретные клиенты для двух пользователей с разными
профилями: мама — не-технический консультант, которому нужен простой чат; Сергей —
архитектор, которому нужны MCP-серверы, выбор модели и захват кода из Конфигуратора 1С.

## Decision Drivers

* Мама: предельно простой UX, без настройки, без знания MCP, без VPN
* Сергей (everyday): гибкий выбор модели, подключение нескольких MCP-серверов
* Сергей (захват кода): ввод текста в редактор Конфигуратора 1С в обход keyboard-хуков
* Доступность из России без VPN (ключевое ограничение для дефолт-клиента)
* Совместимость лицензии с AGPL-3.0 проекта (см. ADR [0023](0023-license-checklist-and-source-rule.md))
* Стоимость: дефолт — бесплатно, платные опции — явный апгрейд

## Considered Options

* Cherry Studio — свободный десктоп (AGPL-3.0 + коммерческая dual), 300+ моделей / 50+ провайдеров, MCP-поддержка, работает из России
* Claude Desktop — клиент Anthropic, платная подписка Claude Pro, MCP-поддержка, требует VPN в России
* mini-ai-1c (hawkxtreme) — специализированный Tauri-десктоп для разработки на 1С, Attribution Non-Commercial (код брать нельзя), EditorBridge для Конфигуратора

## Decision Outcome

Chosen option: "Cherry Studio как дефолт + Claude Desktop как домашний Premium + mini-ai-1c как инструмент захвата кода у Сергея", because Cherry Studio закрывает оба профиля (мама и Сергей-everyday) бесплатно из России без VPN, а Claude Desktop и mini-ai-1c покрывают специфические use-case Сергея там, где Cherry недостаточно.

**Распределение по ролям:**

| Роль | Клиент | Модель | Контекст |
|---|---|---|---|
| Мама (чат-консультант) | Cherry Studio | DeepSeek V4 Flash | Сергей настраивает один раз |
| Сергей (everyday) | Cherry Studio | DeepSeek V4 Flash/Pro | MCP-серверы Азимута |
| Сергей (premium дома) | Claude Desktop | Claude Opus/Sonnet | Задачи, где нужен Claude |
| Сергей (захват кода) | mini-ai-1c | — | Ввод кода в Конфигуратор через EditorBridge |

### Consequences

* Good, because Cherry Studio не требует VPN, бесплатна, AGPL-совместима, поддерживает MCP из коробки
* Good, because мама получает готовый чат без необходимости понимать MCP
* Good, because Сергей сохраняет гибкость: Cherry для рутины, Claude Desktop для premium-задач
* Good, because mini-ai-1c решает узкую задачу захвата кода из Конфигуратора (WM_CHAR через EditorBridge) — архитектурная идея, не код (Non-Commercial запрещает брать код)
* Bad, because три клиента создают рассеянность — митигируется фиксацией ролей в таблице выше
* Bad, because mini-ai-1c лицензия (Attribution Non-Commercial) несовместима с AGPL — поэтому берём только архитектурную идею EditorBridge, не код

### Confirmation

Cherry Studio установлен и подключён к MCP-серверу Азимута; мама пользуется им без помощи Сергея. В `05-building-block-view.md` раздел «Клиент» описывает трёхклиентную схему по ролям.

## Pros and Cons of the Options

### Cherry Studio

* Good, because бесплатно, AGPL-3.0 + dual (коммерция разрешена), 300+ моделей
* Good, because работает из России без VPN
* Good, because поддерживает MCP-серверы, множественные провайдеры
* Good, because простой UI подходит маме
* Bad, because не решает захват кода из Конфигуратора 1С

### Claude Desktop

* Good, because лучший UX от Anthropic, MCP-поддержка
* Bad, because требует VPN в России
* Bad, because платная подписка Claude Pro (дополнительные расходы)

### mini-ai-1c

* Good, because EditorBridge решает захват кода из Конфигуратора (WM_CHAR, обходит keyboard-хуки)
* Good, because специализирован под 1С-разработку, 4 MCP-сервера по доменам
* Bad, because Attribution Non-Commercial — код брать нельзя, только архитектурные идеи
* Bad, because не подходит для мамы (слишком специализированный)

## More Information

Реш. 1.7a из `_source/notion/design-system-v2--*.md`.
Конкурентный анализ: `_source/notion/hle-458-mini-ai-1c-competitors--*.md` — там же
эмпирика EditorBridge (утверждения из чужого репо, не проверены нами; тема 17 «живые процедуры»).
Дефолт-модель для Cherry Studio → ADR [0021](0021-default-model-deepseek-v4.md).
Лицензионная совместимость → ADR [0023](0023-license-checklist-and-source-rule.md).
