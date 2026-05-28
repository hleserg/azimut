# Roadmap проекта «Азимут»

> Фазы реализации v2.0, открытые риски, 7 требований из v1.x-карты и архив старой декомпозиции.
>
> **Источники:** [план 05-rebuild-plan.md](../docs/_planning/05-rebuild-plan.md) §7.4; [`_source/notion/solutions-registry-summary--*.md`](./_source/notion/solutions-registry-summary--36b0c905e62681148d5a3d7e74d6e487.md); [`_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md`](./_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md).
>
> Этот файл — **справочный артефакт**. Не блокирует ни одну рабочую фазу. Обновляется Сергеем при изменении статуса фаз или открытии новых рисков.

---

## Содержание

1. [Фазы реализации v2.0](#1-фазы-реализации-v20)
2. [Открытые риски](#2-открытые-риски)
3. [7 требований из v1.x-карты](#3-7-требований-из-v1x-карты)
4. [Архив v1.x: старая декомпозиция](#4-архив-v1x-старая-декомпозиция)

---

## 1. Фазы реализации v2.0

Семь тем соответствуют Linear-задачам HLE-413..419. Последовательность условная — темы 1 и 2 блокируют всё остальное; темы 3–7 могут перекрываться.

### Фаза 1: Фундамент — [HLE-413](https://linear.app/hleserg/issue/HLE-413) ✅ Done

**Что:** форк `bsl-atlas` (AGPL-3.0) как ядро понимания кода 1С; Cherry Studio как дефолт-клиент; DeepSeek V4 как дефолт-модель; `mcp-bsl-platform-context` (MIT) как второй MCP-сервер справочника платформы.

**Ключевые решения (ADR 0011–0023):**

| ADR | Решение | Статус |
|---|---|---|
| [0011](architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md) | Форк `bsl-atlas` (AGPL-3.0) — ядро понимания кода | accepted |
| [0012](architecture/adr/foundation/0012-name-azimut.md) | Имя проекта — «Азимут» / `azimuth` | accepted |
| [0013](architecture/adr/foundation/0013-fork-role-code-engine.md) | Роль форка: только «движок кода» (парсер BSL + граф + каркас MCP) | accepted |
| [0014](architecture/adr/foundation/0014-fserg-mcp-1c-as-reference-only.md) | `FSerg/mcp-1c-v1` (MIT) — референс идей, не кодовая основа | accepted |
| [0015](architecture/adr/foundation/0015-stack-migration-smoke-then-qdrant.md) | Дымовой прогон на ChromaDB → сразу Qdrant+BGE-M3 | accepted |
| [0016](architecture/adr/foundation/0016-onec-mcp-universal-deferred.md) | `onec-mcp-universal` — отложен до темы 7 | accepted |
| [0017](architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md) | `alkoleft/mcp-bsl-platform-context` (MIT) — второй MCP в фундаменте | accepted |
| [0018](architecture/adr/foundation/0018-mcp-client-no-own-ui.md) | Свой UI не строим — берём готовый MCP-клиент | superseded by 0019 |
| [0019](architecture/adr/foundation/0019-cherry-studio-default-client.md) | Cherry Studio (мама/Сергей-everyday) + Claude Desktop + mini-ai-1c | accepted |
| [0020](architecture/adr/foundation/0020-cloud-llm-via-adapter.md) | Разговорная LLM — облачная, подключается через адаптер | accepted |
| [0021](architecture/adr/foundation/0021-default-model-deepseek-v4.md) | Дефолт-модель — DeepSeek V4 (Flash / Pro для тяжёлого кода) | accepted |
| [0022](architecture/adr/foundation/0022-boundary-fork-vs-own-code.md) | Граница: форк даёт код, библиотеки — RAG, наш код — поведение | accepted |
| [0023](architecture/adr/foundation/0023-license-checklist-and-source-rule.md) | Лицензионный чек-лист OSS + правило источников | accepted |

**⚠️ Открытый хвост:** дымовой прогон `bsl-atlas` на реальной ERP не выполнен — блокирует уверенность в ADR 0011/0015 и реш. 2.1 (тема 2). Подробнее: [раздел 2](#2-открытые-риски).

---

### Фаза 2: Обработка кода 1С — [HLE-414](https://linear.app/hleserg/issue/HLE-414) 🔄 In Progress

**Что:** детерминированный структурный чанкинг поверх `bsl-atlas`; граф вызовов с резолвом одноимённых процедур; роутинг поиска graph → metadata → grep; портирование техник `feenlace/mcp-1c` (Go→Python).

**Ключевые решения (ADR 0024–0027):**

| ADR | Решение | Статус |
|---|---|---|
| [0024](architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md) | Детерминированная структурная резка: функция = чанк; `Если`/`Цикл` с шапкой контекста; запросы по `\|;` | accepted |
| [0025](architecture/adr/code-processing/0025-resolve-same-named-procedures.md) | Резолв одноимённых процедур — открытый алгоритм поверх схемы из metacode | **proposed** |
| [0026](architecture/adr/code-processing/0026-code-search-routing.md) | Роутинг поиска: fallback-цепочка graph → metadata → grep | accepted |
| [0027](architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md) | Портировать техники feenlace (GC-off, шардирование, кеш SHA, манифест-diff, BSL-синонимы) в Python | accepted |

**⚠️ Открытые хвосты:** алгоритм резолва одноимённых (ADR 0025 `proposed`) — главный технический риск темы 2; дымовой прогон ADR 0015 (блокирует уверенность в реш. 2.1).

---

### Фаза 3: Поисковый стек — [HLE-415](https://linear.app/hleserg/issue/HLE-415) 📋 Backlog

**Что:** эмбеддинги BGE-M3 (локально); гибридный поиск (BM25 + вектор); реранкер bge-reranker-v2-m3 (локально), Cohere Rerank v4 (опционально, по гранту); Self-RAG / Long-context vs RAG.

**Известные переменные (ADR появятся при работе над HLE-415):**
- BGE-M3 (MIT) — основной эмбеддер; подтверждён кандидат, финал через eval (тема 6).
- Cohere Rerank v4 — опциональный апгрейд (грант, не тратим по умолчанию).
- Self-RAG vs Long-context trade-off — открытый вопрос до работы над темой 3.
- `onec-help-mcp` (HLE-462) — гибрид BM25+вектор для документации — отложен до темы 3.
- RRF-слияние — идеи из ADR [0014](architecture/adr/foundation/0014-fserg-mcp-1c-as-reference-only.md) (payload-схема FSerg/mcp-1c).

---

### Фаза 4: Приём документации — [HLE-416](https://linear.app/hleserg/issue/HLE-416) 📋 Backlog

**Что:** разбор формата ИТС (ISCF: `Data.cab` + `Data.dir`); OCR для сканов; мультимодальный RAG (скриншоты интерфейса, схемы); парсер личных документов (txt/md/pdf/docx/doc/odt/pptx/csv/xml/json/html/eml).

**Известные переменные:**
- ISCF — проприетарный архив; разведка от 25.05.2026 в [`_source/notion/iscf-analysis--*.md`](./_source/notion/); нужен Python-парсер или готовый инструмент сообщества 1С.
- XML-выгрузка (`Конфигуратор → XML`) vs `DumpConfigToFiles` — **два разных источника**; оба нужны при индексации (ADR [0024](architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md) флаг 2.6 #1 из плана). ADR по этому вопросу — при работе над темой 2/4.
- LibreOffice headless — конвертация `.doc`/`.odt` → текст.

---

### Фаза 5: Анти-галлюцинации и поведенческий контракт — [HLE-417](https://linear.app/hleserg/issue/HLE-417) 📋 Backlog

**Что:** закрытие принятых принципов Р1–Р7 в коде и промпте; поведенческий контракт агента (системный промпт); детектор groundedness (П1); второй проход ретривера (П2); оценка достаточности запроса (П3); механика детектирования противоречивости (ADR 0033).

**ADR-фон (принятые + proposed, созданы в фазе документации):**

| ADR | Принцип | Статус |
|---|---|---|
| [0001](architecture/adr/anti-hallucinations/0001-р1-metric-contradiction.md) | Р1: Метрика противоречивости источников ПЕРЕД выдачей | accepted |
| [0002](architecture/adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md) | Р2: Faithfulness и relevance — разные метрики | accepted |
| [0003](architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md) | Р3: LLM-судья со спан-привязкой | accepted |
| [0005](architecture/adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md) | Р5: Контроль ретривинга на сервере | accepted |
| [0006](architecture/adr/anti-hallucinations/0006-р6-source-hierarchy.md) | Р6: Иерархия источников: код → справка → ИТС | accepted |
| [0007](architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md) | Р7: Фолбэк = смена режима (дип-ресёрч) | accepted |
| [0008](architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md) | П1: Детектор «relevance высокий / groundedness низкий» — 3 уровня | **proposed** |
| [0009](architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md) | П2: Второй проход ретривера при неуверенности | **proposed** |
| [0010](architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md) | П3: Оценка достаточности запроса + подсказки | **proposed** |
| [0033](architecture/adr/open/0033-r1-contradiction-detection-mechanics.md) | Механика детектирования Р1 — как технически детектировать | **proposed** |

---

### Фаза 6: Eval — [HLE-418](https://linear.app/hleserg/issue/HLE-418) 📋 Backlog

**Что:** золотой eval-набор с реальными вопросами по 1С ERP; RAGAS-харнесс (faithfulness ≥ 0.80, context_recall, answer_correctness); LLM-судья (ADR 0003) как метрика; Langfuse или Sentry (зависит от ADR [0028](architecture/adr/open/0028-sentry-vs-agpl.md)) как наблюдаемость.

**Входит эталонный кейс:** [`cases/01-document-changed-account.md`](cases/01-document-changed-account.md) — «почему документ сменил счёт» (3 слоя; см. тот файл).

---

### Фаза 7: Онлайн-деплой и мульти-аренда — [HLE-419](https://linear.app/hleserg/issue/HLE-419) 📋 Backlog

**Что:** VDS-деплой (Python+uv+FastMCP); мульти-аренда (Qdrant server, JWT, изоляция `/data/{tenant_id}/`); веб-морда (Push к пользователю вместо отсутствующего push в MCP); `onec-mcp-universal` (ADR [0016](architecture/adr/foundation/0016-onec-mcp-universal-deferred.md)).

**Открытые развилки (ADR 0029–0032):**

| ADR | Развилка | Статус |
|---|---|---|
| [0028](architecture/adr/open/0028-sentry-vs-agpl.md) | Конфликт AGPL × Sentry for Open Source — ждём ответ; план Б без Sentry | **proposed** |
| [0029](architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md) | Qdrant embedded (локально) vs server (VDS) | **proposed** |
| [0030](architecture/adr/open/0030-multitenancy-canary-vs-watchdog.md) | Канарейка-в-потоке vs фоновый сторож («протухшее в покое» у незаходящих контор) | **proposed** |
| [0031](architecture/adr/open/0031-multitenancy-push-via-web-frontend.md) | Push к пользователю через веб-морду (замена отсутствующего push в MCP) | **proposed** |
| [0032](architecture/adr/open/0032-multitenancy-tenant-storage-isolation.md) | Изоляция хранилища по тенантам (`/data/{tenant_id}/` + JWT + фильтры Qdrant) | **proposed** |

---

## 2. Открытые риски

Три главных риска тянут оценки ADR вниз (по [`_source/notion/solutions-registry-summary--*.md`](./_source/notion/solutions-registry-summary--36b0c905e62681148d5a3d7e74d6e487.md), раздел «Открытые риски»):

### Риск 1: Дымовой прогон `bsl-atlas` на реальной ERP не выполнен

**Влияние:** висит над ADR 0011 (форк как ядро), ADR 0015 (дымовой прогон → Qdrant), реш. 2.1 (чанкинг).  
**Симптом:** мы приняли решение форкать `bsl-atlas`, но ни разу не запускали его на реальной ERP-конфигурации. Неизвестно: сколько времени займёт индексация, нет ли падений на специфичных модулях, корректно ли строится граф вызовов.  
**Действие:** запустить `bsl-atlas` на тестовой ERP-копии до начала активной разработки темы 2 (HLE-414). Первый результат — в `architecture/11-technical-risks.md`.

### Риск 2: Алгоритм резолва одноимённых процедур не написан

**Влияние:** ADR [0025](architecture/adr/code-processing/0025-resolve-same-named-procedures.md) статус `proposed`; схема (`calls(caller_id, callee_id)`, `callee_id=NULL` для неразрешённых) зафиксирована, но сам алгоритм — открытая инженерная задача.  
**Симптом:** в 1С ERP одно и то же имя процедуры встречается в десятках модулей. Без резолва граф вызовов содержит «висячие» рёбра — агент не может точно ответить, кто вызывает что.  
**Действие:** закрывается при работе над темой 2 (HLE-414). Никакой готовой реализации в открытом коде не нашлось — пишем сами поверх схемы metacode.

### Риск 3: Sentry × AGPL-3.0 — конфликт

**Влияние:** ADR [0028](architecture/adr/open/0028-sentry-vs-agpl.md) статус `proposed`; HLE-318, HLE-319 (Sentry workflow) зависят от исхода; HLE-418 (eval/наблюдаемость) тоже.  
**Симптом:** Sentry for Open Source накладывает условие «проект должен быть открытым» — но AGPL-3.0 нашего форка и лицензионная политика Sentry могут конфликтовать.  
**Действие:** ждём письменного ответа от Sentry. Если откажут — план Б: GlitchTip (self-host Sentry, AGPL-совместим) или Prometheus+Grafana. Форк `bsl-atlas` **не переоткрывается** в любом случае (решение Сергея от 2026-05-26).

---

## 3. 7 требований из v1.x-карты

Требования из [`_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md`](./_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md). В v2.0 они не аннулированы — обсуждаем при открытии соответствующих тем (HLE-415..419). Здесь — для памяти, чтобы не потерять при пересборке.

| № | Требование | Тема v2.0 |
|---|---|---|
| 1 | **Личные документы как 3-й источник** — форматы: txt/md/pdf/docx/doc/odt/pptx/csv/xml/json/html/eml; рекурсивный обход папок; LibreOffice headless для doc/odt | Фаза 4 (HLE-416) |
| 2 | **Document Registry** — SQLite + SHA-256 + статусы (ok/ошибка/advisory/удалён) + автоочистка удалённых файлов | Фаза 4 (HLE-416) |
| 3 | **Мониторинг папки личных документов** — проверка изменений при каждом возвращении пользователя; ненавязчивое предложение переиндексации раз за сессию | Фаза 4 (HLE-416) |
| 4 | **Адаптивный cut-off** — gap-алгоритм по скорам реранкера вместо фиксированного top_k; параметры настраиваемые; данные для тонкой настройки — из eval (тема 6) | Фаза 3 (HLE-415) + Фаза 6 (HLE-418) |
| 5 | **Кеш запросов** — exact-match (TTL 5 мин) + semantic similarity ≥95% (TTL 1 час); отключается в экспериментальном режиме | Фаза 3 (HLE-415) |
| 6 | **GDPR-флоу для телеметрии** — opt-in один раз при первом запуске; по умолчанию выключено; пользователь отключает в любой момент; содержимое документов не отправляется | Фаза 7 (HLE-419) + ADR [0028](architecture/adr/open/0028-sentry-vs-agpl.md) |
| 7 | **XML-выгрузка vs DumpConfigToFiles** — оба источника при индексации: XML-выгрузка содержит структуру объектов и реквизиты; DumpConfigToFiles — модули BSL и граф; важно не смешивать как «один формат» | Фаза 2 (HLE-414) + Фаза 4 (HLE-416) |

> **Флаг 2.6 #1 из плана:** ADR 0011 (форк bsl-atlas) и ADR 0024 (чанкинг) пока явно не отражают требование «оба источника». Зафиксировать при работе над темой 2/4.

---

## 4. Архив v1.x: старая декомпозиция

Проект «Агент-консультант по 1С ERP» — 45 issues HLE-292..346. **Не мигрируем дословно** — декомпозиция v1.x пересобирается заново под v2.0 (форк bsl-atlas + готовые библиотеки). Здесь — ссылки как «исторический контекст»: при работе над темами 3–7 сверяться, чтобы не упустить конкретных требований.

Полные файлы: [`_source/linear/agent-konsultant-po-1s-erp/`](./_source/linear/agent-konsultant-po-1s-erp/).

### 4.1 Основная декомпозиция (18 задач, HLE-292..312)

| Issue | Заголовок | Статус | Релевантно для v2.0 |
|---|---|---|---|
| HLE-292 | 1. Каркас проекта: структура репо, конфиг, разделение код/данные | — | Фаза 0 (HLE-497/498) — сделано |
| HLE-295 | 2. ADR: фиксация стека (FastMCP, BGE-M3, reranker, vector store) | — | ADR 0011–0034 — сделано |
| HLE-297 | 3. Парсер XML-выгрузки конфигурации | — | Фаза 2/4 (HLE-414/416); требование 7 |
| HLE-298 | 4. Индексатор текстовой доки (офлайн-ИТС + платформа) с иерархией и OCR | — | Фаза 4 (HLE-416) |
| HLE-299 | 5. Поисковый слой: гибрид + реранкер + полные разделы + сигнал полноты | — | Фаза 3 (HLE-415) |
| HLE-300 | 6. MCP-сервер: инструменты с обязывающими описаниями | — | Фаза 2 (HLE-414); ADR 0026 |
| HLE-301 | 7. Поведенческий контракт: системный промпт «спец, а не колл-центр» | — | Фаза 5 (HLE-417); ADR 0008 |
| HLE-302 | 8. CLI и оркестрация индексации | — | Фаза 2 (HLE-414) |
| HLE-303 | 9. Менеджер модели BGE: ленивая загрузка + прогрев + выгрузка по простою | — | Фаза 3 (HLE-415) |
| HLE-304 | 10. Онбординг через MCP: validate_path / save_config / get_progress / healthcheck | — | Фаза 2 (HLE-414) |
| HLE-305 | 11. Экспериментальный режим: shadow-обкатка стратегий + сбор телеметрии | — | Фаза 6 (HLE-418) |
| HLE-306 | 12. LLM-судья: Claude как основной арбитр | — | Фаза 5 (HLE-417); ADR 0003 |
| HLE-307 | 13. Анализ телеметрии и финальный выбор стратегии | — | Фаза 6 (HLE-418) |
| HLE-308 | 14. Cohere-адаптеры: Rerank v4 + Embed 4 + Command (переключаемые, условные по ключу) | — | Фаза 3 (HLE-415); ADR 0020 |
| HLE-309 | 15. Упаковка и установка: ручной JSON + .mcpb-бандл + скрипт подготовки | — | Фаза 7 (HLE-419) |
| HLE-310 | 16. Мониторинг релизов ERP и платформы (дайджест + подсказка переиндексации) | — | Фаза 4 (HLE-416); требование 3 |
| HLE-311 | 17. Механизм живых процедур: `get_procedure` + самоисцеление инструкций | — | Фаза 2 (HLE-414) |
| HLE-312 | 18. Ежемесячное обновление доков: ненавязчивое предложение + согласование переиндексации | — | Фаза 4 (HLE-416) |

### 4.2 Bootstrap-задачи (12 задач, HLE-313..324)

| Issue | Заголовок | Статус | Примечание |
|---|---|---|---|
| HLE-313 | 0a. Bootstrap: репо, CI, тулинг, Devin-ревьювер | — | Фаза 0/0a сделана (HLE-497/498) |
| HLE-314 | 0b. Sentry: согласовать спонсорскую подписку | Done | ADR [0028](architecture/adr/open/0028-sentry-vs-agpl.md) — конфликт AGPL |
| HLE-315 | 0c. Инструментация: Sentry, логи, трейсинг | In Progress | Зависит от ADR 0028; план Б — GlitchTip |
| HLE-316 | 0e. Собрать реальные данные (пути) | — | Фаза 1 prerequisite — для дымового прогона |
| HLE-317 | 0d. Изучить cc-1c-skills, завендорить спеки 1С | — | Фактура в `hle-457-prompt-engineering-xml.md` |
| HLE-318 | 0f. Настроить Sentry workflow + DSN | — | Зависит от ADR 0028 |
| HLE-319 | 0g. Sentry-ревью в PR | — | Зависит от ADR 0028 |
| HLE-320 | Шаблон репо (repo-template) | In Progress | Параллельная инициатива |
| HLE-321 | 0h: agent-playbook — изучить | — | Фактура для CLAUDE.md / AGENTS.md |
| HLE-322 | Склонировать плейбук репо | — | Выполнено в ходе HLE-321 |
| HLE-323 | Изучить что натворил агент | — | Обзор состояния |
| HLE-324 | 0i: Adapter-агностичная архитектура MCP + `install()` | Backlog | ADR [0020](architecture/adr/foundation/0020-cloud-llm-via-adapter.md) |

### 4.3 Canceled-задачи (4 задачи, HLE-332..335)

Явно Canceled. Содержательные требования продублированы в HLE-336..340 (Backlog). Дословно не переносим.

| Issue | Заголовок |
|---|---|
| HLE-332 | 19. Document Registry (отменён, дубль HLE-336) |
| HLE-333 | 20. Парсер личных документов (отменён, дубль HLE-337) |
| HLE-334 | 21. Адаптивный cut-off (отменён, дубль HLE-338) |
| HLE-335 | 22. Семантический кеш запросов (отменён, дубль HLE-339) |

### 4.4 Пересобранная декомпозиция v1.x (5 задач, HLE-336..340)

Backlog. Содержательно живые требования — обсуждаем при работе над темами 3–4 (HLE-415/416).

| Issue | Заголовок | Требование v1.x |
|---|---|---|
| HLE-336 | 1a. Document Registry: SQLite + SHA-256 + статусы + автоочистка | Требование 2 |
| HLE-337 | 3a. Парсер личных документов: мульти-формат + LibreOffice + OCR + рекурсия | Требование 1 |
| HLE-338 | 11a. Адаптивный cut-off по gap скоров реранкера | Требование 4 |
| HLE-339 | 6a. Семантический кеш: exact-match + semantic similarity (опционально) | Требование 5 |
| HLE-340 | 4a. PII-фильтр: маскировка персданных перед записью в индекс (Presidio) | → `architecture/08-cross-cutting-concepts.md` |

### 4.5 Контрольные точки v1.x (6 задач, HLE-341..346)

Приёмочные КТ для v1.x. При v2.0-пересборке — перепроектировать аналоги при работе над фазами.

| Issue | Заголовок |
|---|---|
| HLE-341 | КТ1: Проверка инфраструктуры (bootstrap готов) |
| HLE-342 | КТ2: Каркас живой (конфиг + реестр запускаются) |
| HLE-343 | КТ3: Индексация работает (данные в Qdrant, реестр живёт) |
| HLE-344 | КТ4: Поиск работает (BGE + реранкер + чанки из Qdrant) |
| HLE-345 | КТ5: Агент живой в Claude Desktop (MCP + онбординг + CLI) |
| HLE-346 | КТ6: Приёмка ядра — реальные вопросы по 1С, агент отвечает правильно |

---

*Создан 2026-05-28 для HLE-501 (Фаза 7 плана перестройки документации, HLE-495). Источники: `docs/_planning/05-rebuild-plan.md`, `docs/_source/notion/solutions-registry-summary--*.md`, `docs/_source/linear/attachments/_project-docs/karta-zadach-i-arhitekturnye-resheniya-aktualno.md`, `docs/_source/linear/agent-konsultant-po-1s-erp/`.*
