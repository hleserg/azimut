# 3. Контекст и границы системы (Context and Scope)

> arc42 §3 — кто и через что взаимодействует с Азимутом снаружи; что внутри, что нет. C4 System Context описан в [`workspace.dsl`](../../workspace.dsl), view `systemContext` (ADR [0034](adr/tooling/0034-architecture-as-code-structurizr-dsl.md)).
>
> Локальный просмотр C4-диаграммы:
> ```bash
> docker run --rm -p 8080:8080 -v .:/usr/local/structurizr --user $(id -u):$(id -g) structurizr/structurizr
> ```
> Открыть `http://localhost:8080` → view `systemContext`.

## 3.1 Бизнес-контекст: цепочка взаимодействия

```
[Сергей / Мама]
      │
      ▼
[Клиент: Cherry Studio | Claude Desktop | mini-ai-1c]      ← ADR 0019
      │ MCP / JSON-RPC
      ▼
┌──────────────────────── Азимут ──────────────────────────┐
│  MCP-оркестратор  ──►  Азимут-ядро (форк bsl-atlas)      │
│  (наш код)              (BSL-парсер + граф + чанкер)     │
│  Adapter-слой LLM  ──►  Qdrant (векторы и метаданные)    │
└──┬───────────────────────────────────────────────────────┘
   │
   ├──► DeepSeek (облачная разговорная LLM, дефолт)        ← ADR 0021
   ├──► Claude (LLM-судья / Сергей-премиум)                ← ADR 0003
   ├──► mcp-bsl-platform-context (drop-in MCP справки)     ← ADR 0017
   ├──► ИТС / Портал платформы (3-й уровень иерархии)      ← ADR 0006
   └──► Sentry / GlitchTip (мониторинг и канарейка)        ← ADR 0028 (open)

[Платформа 1С] ──DumpConfigToFiles──► Азимут-ядро (загрузка BSL и метаданных)
```

Это текстовая шпаргалка для людей; авторитетный источник — `view systemContext` в `workspace.dsl`.

## 3.2 Внешние акторы — кто и зачем

### Пользователи

| Актор | Канал входа | Назначение | Ссылка в DSL |
|---|---|---|---|
| **Сергей** (лид-разработчик) | Cherry Studio everyday; Claude Desktop дома (премиум, eval-эталон); mini-ai-1c — для захвата кода из Конфигуратора | Ежедневная работа с конфигурацией ERP, тяжёлый разбор кода, проверки гипотез | `person serg` |
| **Мама** (бухгалтер) | Cherry Studio (чат, без захвата кода) | Вопросы по типовой ERP в стиле «как сделать X» | `person mama` |

См. [`01-introduction-and-goals.md`](01-introduction-and-goals.md) §1.2 — детальные ожидания стейкхолдеров.

### Внешние системы

| Внешняя система | Что от неё нужно | Протокол / формат | DSL-элемент | ADR |
|---|---|---|---|---|
| **Платформа 1С** | Текстовая выгрузка конфигурации `DumpConfigToFiles` (`*.bsl` + метаданные) + расширения + внешние обработки (`.epf/.erf`) | Файловая система, локальная папка | `softwareSystem onecPlatform` | [0011](adr/foundation/0011-fork-bsl-atlas-as-core.md), [0024](adr/code-processing/0024-code-chunking-deterministic-structural.md) |
| **DeepSeek (облачная LLM)** | Разговорная генерация (Flash основной режим, Pro — тяжёлый код); работает из РФ без VPN | HTTPS, OpenAI-compatible API | `softwareSystem deepSeekLLM` | [0020](adr/foundation/0020-cloud-llm-via-adapter.md), [0021](adr/foundation/0021-default-model-deepseek-v4.md) |
| **Claude (Anthropic)** | LLM-судья со спан-привязкой; Сергей-премиум дома (Claude Desktop по подписке) | HTTPS, Anthropic API | `softwareSystem claudeLLM` | [0003](adr/anti-hallucinations/0003-р3-llm-judge-spans.md), [0019](adr/foundation/0019-cherry-studio-default-client.md), [0020](adr/foundation/0020-cloud-llm-via-adapter.md) |
| **ИТС / Портал платформы 1С** | Справочные материалы — третий уровень иерархии источников (после кода и встроенной справки конфы) | HTTPS / офлайн-копия | `softwareSystem its` | [0006](adr/anti-hallucinations/0006-р6-source-hierarchy.md) |
| **`mcp-bsl-platform-context`** (alkoleft, MIT) | Справочник синтаксиса платформы из `shcntx_ru.hbk` — drop-in MCP-сервер рядом с Азимутом | MCP / JSON-RPC | `container bslPlatformMcp` (как Container_Ext) | [0017](adr/foundation/0017-mcp-bsl-platform-context-included.md) |
| **Sentry / GlitchTip** | Канарейка / распределённая трассировка; выбор между Sentry SaaS и self-hosted GlitchTip открыт (Sentry × AGPL — конфликт) | HTTPS / Sentry SDK | `container sentry` (как Container_Ext) | [0028 open](adr/open/0028-sentry-vs-agpl.md) |

### MCP-клиенты как граничные контейнеры

В C4-модели три клиента ([ADR 0019](adr/foundation/0019-cherry-studio-default-client.md)) описаны как контейнеры внутри `softwareSystem azimuth`, но помечены `tags "External"` (Container_Ext) — это сторонние приложения, которыми пользователь владеет, а не наш код:

- `container cherryStudio` — Cherry Studio (AGPL-3.0 + dual licensing) — дефолт для мамы и Сергея-everyday.
- `container claudeDesktop` — Claude Desktop — Сергей-премиум дома (подписка, не API).
- `container miniAi1c` — mini-ai-1c — Сергей-захват кода из Конфигуратора.

## 3.3 Чего система НЕ делает (out of scope)

Сознательные ограничения, которые формируют границу — каждое привязано к ADR:

1. **Не генерирует ответ самостоятельно.** Разговорной LLM внутри MCP-сервера нет; «мозг разговора» — это модель клиента, подключённая через адаптер ([ADR 0020](adr/foundation/0020-cloud-llm-via-adapter.md), реш. 1.8). MCP отдаёт контекст + поведенческий контракт; финальную реплику собирает клиент.
2. **Не лезет в облачные данные без маски PII.** Перед отправкой запроса в облачную LLM применяется PII-фильтр; персональные данные маскируются. Прототип + локальный сценарий + DeepSeek/Claude — допустимы; коммерческие тенанты (152-ФЗ) — отдельная тема 7 (см. [`02-architecture-constraints.md`](02-architecture-constraints.md) §2.2 O5).
3. **Не пишет код в 1С (read-only).** Азимут читает выгрузку конфигурации и работает с индексом. Изменения в базу 1С не вносит. Runtime-доступ к живой 1С (5 репо из [HLE-464](https://linear.app/hleserg/issue/HLE-464)) — это отдельная развилка темы 7 ([`11-technical-risks.md`](11-technical-risks.md), [ADR 0029](adr/open/0029-multitenancy-qdrant-embedded-vs-server.md)–[0032](adr/open/0032-multitenancy-tenant-storage-isolation.md)).
4. **Не выдумывает паттерны 1С.** Любое утверждение о коде 1С — либо подтверждённый факт из исходников, либо помечено «не знаю, надо проверить» ([`02-architecture-constraints.md`](02-architecture-constraints.md) §2.2 O2).
5. **Не строит свой UI.** Веб-морда и собственные интерфейсы — кандидаты на тему 7 ([ADR 0018](adr/foundation/0018-mcp-client-no-own-ui.md)). На локальном сценарии клиент — Cherry Studio / Claude Desktop / mini-ai-1c.
6. **Не агрегирует MCP-серверы через шлюз.** На локальном сценарии Cherry Studio / Claude Desktop сами подключают несколько MCP-серверов (Азимут + mcp-bsl-platform-context) — без шлюза `onec-mcp-universal` ([ADR 0016](adr/foundation/0016-onec-mcp-universal-deferred.md)). Шлюз вернётся к рассмотрению в теме 7.

## 3.4 Технический контекст: интерфейсы

Каждая внешняя связь авторитетно описана в [`workspace.dsl`](../../workspace.dsl) (model → relationships). Сводка:

| Связь | Протокол / технология | Где в DSL |
|---|---|---|
| Клиент → MCP-оркестратор | MCP / JSON-RPC (stdio или http) | `azimuth.cherryStudio -> azimuth.mcpOrchestrator` (и аналогичные для других клиентов) |
| MCP-оркестратор → Adapter-слой → DeepSeek | HTTPS / OpenAI-compatible API | `azimuth.mcpOrchestrator -> azimuth.llmAdapter`, `azimuth.llmAdapter -> deepSeekLLM` |
| MCP-оркестратор → Claude (LLM-судья) | HTTPS / Anthropic API | `azimuth.mcpOrchestrator -> claudeLLM` |
| MCP-оркестратор → mcp-bsl-platform-context | MCP / JSON-RPC | `azimuth.mcpOrchestrator -> azimuth.bslPlatformMcp` |
| MCP-оркестратор → ИТС | HTTPS | `azimuth.mcpOrchestrator -> its` |
| Азимут-ядро ↔ Qdrant | HTTP / gRPC (Qdrant API) | `azimuth.azimuthCore -> azimuth.qdrant`, `azimuth.embedder -> azimuth.qdrant` |
| Платформа 1С → Азимут-ядро | Файловая система (`DumpConfigToFiles`) | `onecPlatform -> azimuth.azimuthCore` |
| Все компоненты → Sentry | HTTPS / Sentry SDK | `azimuth.mcpOrchestrator -> azimuth.sentry` |

Уровни глубже (Container и Component) — в [`05-building-block-view.md`](05-building-block-view.md) + views `container`, `componentAzimuthCore`, `componentMCPOrchestrator` в [`workspace.dsl`](../../workspace.dsl).
