# 7. Вид развёртывания (Deployment View)

> arc42 §7 — как и где запускается система.
> Описан только **локальный сценарий** (Machine-мамы / рабочее место Сергея). VDS/мульти-аренда отложен до темы 7 (HLE-419, ADR 0029–0032).

---

## 7.1 Локальный сценарий

**Цель:** запустить полный стек на одной машине с минимальными ресурсами.

### Компоненты и их размещение

```
┌─────────────────────────────────────────────────┐
│  Машина пользователя (Windows / macOS / Linux)  │
│                                                 │
│  ┌──────────────────────────────┐               │
│  │   MCP-оркестратор            │               │
│  │   Python ≥ 3.11 + uv         │               │
│  │   FastMCP                    │               │
│  │                              │               │
│  │   Азимут-ядро (in-process)   │               │
│  │   bsl-atlas fork + BGE-M3    │               │
│  │                              │               │
│  │   Qdrant embedded            │               │
│  │   (in-process, файлы на диск)│               │
│  └──────────────┬───────────────┘               │
│                 │ MCP / JSON-RPC                │
│  ┌──────────────┴──────┐  ┌────────────────┐   │
│  │  Cherry Studio      │  │  Claude Desktop │   │
│  │  (Electron)         │  │  (Desktop App)  │   │
│  └─────────────────────┘  └────────────────┘   │
│                                                 │
│  ┌──────────────────────────────┐               │
│  │  mcp-bsl-platform-context    │               │
│  │  (отдельный процесс / docker)│               │
│  └──────────────────────────────┘               │
└─────────────────────────────────────────────────┘
           │ HTTPS                  │ HTTPS
     ┌─────┴──────┐         ┌──────┴─────────┐
     │  DeepSeek  │         │ Claude API     │
     │  (облако)  │         │ (Anthropic)    │
     └────────────┘         └────────────────┘
           │ HTTPS (опционально)
     ┌─────┴──────┐
     │  Sentry /  │
     │  GlitchTip │
     └────────────┘
```

### Технический стек (локальный деплой)

| Компонент | Технология | Режим |
|---|---|---|
| MCP-оркестратор | Python ≥ 3.11 + [uv](https://docs.astral.sh/uv/) + FastMCP | Local process |
| Азимут-ядро | Python / bsl-atlas fork (in-process с оркестратором) | In-process module |
| Эмбеддер | BGE-M3 (FlagEmbedding, Apache 2.0) | In-process, локально |
| Реранкер | BGE-reranker (по умолчанию) | In-process, локально |
| Qdrant | Qdrant embedded mode | In-process, файловое хранилище на диске |
| mcp-bsl-platform-context | TypeScript / Node.js или docker | Отдельный процесс |
| Cherry Studio | Electron App | Desktop |
| Claude Desktop | Desktop App | Desktop |
| mini-ai-1c | Desktop App | Desktop |
| DeepSeek V4 | Облачный API (HTTPS) | External SaaS |
| Claude (Anthropic) | Облачный API (HTTPS) | External SaaS |
| Sentry / GlitchTip | SaaS или self-hosted | External (ADR 0028, открыт) |

✅ проверено: `workspace.dsl` (контейнеры + теги); ADR 0020 (BGE-M3 локально по умолчанию); ADR 0021 (DeepSeek V4 по умолчанию)

### Требования к ресурсам

| Ресурс | Минимум | Примечание |
|---|---|---|
| RAM | 4–8 GB | BGE-M3 требует ~4 GB при загрузке; Qdrant embedded — минимальный footprint |
| Диск | ~10 GB | Qdrant-хранилище зависит от размера кодовой базы 1С |
| GPU | Не требуется | BGE-M3 работает на CPU; GPU ускоряет, но не обязателен |
| Интернет | Требуется при генерации | DeepSeek и Claude API; индексация локальная |

✅ проверено: ADR 0028 (self-hosted Sentry требует 16 GB RAM — исключён для локального деплоя)

### Порядок запуска

1. `uv sync` — установить зависимости Python
2. Запустить `mcp-bsl-platform-context` (отдельный процесс или docker)
3. Запустить MCP-оркестратор: `uv run python -m azimuth`
4. Подключить Cherry Studio / Claude Desktop по MCP JSON-RPC

⚠️ предположение: конкретные команды запуска уточняются при реализации (HLE-413 + HLE-414 — инфраструктурные задачи).

---

## 7.2 VDS / Мульти-аренда (отложено)

VDS-сценарий и мульти-арендный деплой отложены до темы 7 (HLE-419). Открытые архитектурные решения:

| ADR | Вопрос |
|---|---|
| [ADR 0029](adr/open/0029-multitenancy-qdrant-embedded-vs-server.md) | Qdrant: embedded vs server-mode на VDS |
| [ADR 0030](adr/open/0030-multitenancy-canary-vs-watchdog.md) | Канарейка vs watchdog для мульти-аренды |
| [ADR 0031](adr/open/0031-multitenancy-push-via-web-frontend.md) | Push-уведомления через веб-морду |
| [ADR 0032](adr/open/0032-multitenancy-tenant-storage-isolation.md) | Изоляция хранилища тенантов |

До принятия ADR 0029–0032 деплой на VDS **не реализуется**.
