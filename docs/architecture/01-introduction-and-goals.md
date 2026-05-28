# 1. Введение и цели (Introduction and Goals)

> arc42 §1 — назначение системы, стейкхолдеры, top quality goals.
>
> Источники: [`_source/notion/hub-1c-assistent--*.md`](../_source/notion/hub-1c-assistent--36b0c905e626819eaca7ed0875cb6f8e.md), [`_source/notion/design-system-v2--*.md`](../_source/notion/design-system-v2--36b0c905e626813491fcf7e9ccf2046e.md) (раздел «Что НЕ меняется»), [`_source/linear/attachments/_project-docs/_project2_description.md`](../_source/linear/attachments/_project-docs/_project2_description.md).

## 1.1 Назначение системы

**Азимут — компетентный консультант по типовой конфигурации 1С ERP, а не «улучшенный поиск».**

Система собирает контекст проблемы, проводит ресёрч по легальным источникам (выгрузка конфигурации в BSL, офлайн-ИТС, портал техдокументации платформы), отвечает **только из найденного без фантазий** и сама определяет нехватку данных — идёт искать дальше или честно меняет режим на дип-ресёрч с тем же контрактом ([ADR 0007](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md)). Реалистичная планка — «почти всегда сам в источники, по делу», не 100 %.

Архитектурно это **MCP-сервер + Азимут-ядро** (форк [`bsl-atlas`](https://github.com/Kuda1berg3nov/bsl-atlas) под AGPL-3.0, [ADR 0011](adr/foundation/0011-fork-bsl-atlas-as-core.md)). Разговорная LLM — облачная, подменяемая через адаптер ([ADR 0020](adr/foundation/0020-cloud-llm-via-adapter.md)); дефолт — DeepSeek V4 ([ADR 0021](adr/foundation/0021-default-model-deepseek-v4.md)). Клиент — Cherry Studio + Claude Desktop + mini-ai-1c ([ADR 0019](adr/foundation/0019-cherry-studio-default-client.md)). Полный C4 System Context — view `systemContext` в [`workspace.dsl`](../../workspace.dsl) ([ADR 0034](adr/tooling/0034-architecture-as-code-structurizr-dsl.md)).

## 1.2 Стейкхолдеры

| Стейкхолдер | Роль | Как пользуется системой | Что для него важно |
|---|---|---|---|
| **Сергей** | Лид-разработчик, владелец проекта, основной пользователь everyday | Cherry Studio + DeepSeek для повседневной работы; Claude Desktop дома для премиум-задач и eval-эталона; mini-ai-1c — для захвата кода прямо из Конфигуратора 1С | Понимание реального кода ERP, граф вызовов, иерархия источников ([ADR 0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md)) |
| **Мама** | Бухгалтер / 1С-оператор, конечный пользователь-нетехник; Конфигуратор не открывает | Только чат в Cherry Studio; Сергей настраивает разово (API-ключ + MCP) | Простота установки локально, ответы по делу, никаких технических деталей |
| **Будущее OSS-сообщество** | Внешние разработчики 1С, заинтересованные в открытом ассистенте по BSL | Форк/использование под AGPL-3.0; самохостинг или подключение к публичной инсталляции | Открытость кода (AGPL-3.0 наследуется от [`bsl-atlas`](https://github.com/Kuda1berg3nov/bsl-atlas)), прозрачность поведения, воспроизводимость eval |

Монетизация **сейчас не стоит**. Если появится — через услуги (внедрение, настройка под кейс клиента, поддержка) поверх открытого кода, а не через закрытость. Этот принцип задаёт тон всем ограничениям главы 2 (см. [`02-architecture-constraints.md`](02-architecture-constraints.md)).

## 1.3 Top Quality Goals

Три цели качества, по убыванию приоритета — каждая измеряется и закрывает конкретный риск:

1. **Faithfulness ответа ≥ 0.80 с реранкером** — ответ опирается на найденные источники, а не на «общие знания» облачной LLM. Это главная защита от галлюцинаций по коду 1С. Измеряется LLM-судьёй со спан-привязкой ([ADR 0003](adr/anti-hallucinations/0003-р3-llm-judge-spans.md)) поверх eval-харнесса RAGAS. Подробности порога и методики — в [`10-quality-requirements.md`](10-quality-requirements.md) (при HLE-418 / тема 6). Принципиальное разделение faithfulness и relevance ретривера зафиксировано в [ADR 0002](adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md); серверный контроль добора — в [ADR 0005](adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md).
2. **Локальность для приватности** — выгрузка конфигурации, индекс, эмбеддер (BGE-M3) и реранкер (BGE-reranker-v2-m3) работают локально по умолчанию ([ADR 0020](adr/foundation/0020-cloud-llm-via-adapter.md)). В облако уходит только разговорный запрос с маской PII; коммерческие/152-ФЗ-сценарии разбираются отдельно в теме 7 (см. [`02-architecture-constraints.md`](02-architecture-constraints.md) §2.2). Локальный запуск маме — обязательный сценарий, а не опция.
3. **Прозрачность ответов («покажи источник»)** — каждый ответ ссылается на конкретные чанки/документы; при конфликте источников применяется иерархия «код в базе → встроенная справка → ИТС» ([ADR 0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md)) и метрика противоречивости ([ADR 0001](adr/anti-hallucinations/0001-р1-metric-contradiction.md), механика — [ADR 0033](adr/open/0033-r1-contradiction-detection-mechanics.md)). Когда индекс не отвечает — фолбэк меняет режим, а не врёт ([ADR 0007](adr/anti-hallucinations/0007-р7-fallback-mode-switch.md)). Полный набор поведенческих требований и системного промпта — в [`08-cross-cutting-concepts.md`](08-cross-cutting-concepts.md) и теме 5 (HLE-417).

Принципиальное допущение, на котором стоят все три цели: **«дотошность — в сервере, не в модели»**. Гейты добора, иерархия источников, сигнал полноты живут на нашей стороне ([ADR 0022](adr/foundation/0022-boundary-fork-vs-own-code.md) — граница «форк/готовое vs наш код»), поэтому слабая или подменённая разговорная модель не ломает гарантии.
