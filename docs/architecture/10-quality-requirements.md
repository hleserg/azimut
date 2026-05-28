# 10. Требования к качеству (Quality Requirements)

> arc42 §10 — NFR: faithfulness ≥ 0.80 с реранком, latency, отказоустойчивость, локальная установка.
> Минимальный набор; расширяется при HLE-418 (тема 6, eval-харнесс).

Качественные сценарии структурированы по формату arc42: **стимул → реакция системы → измеримый критерий**.

---

## QS-01 — Faithfulness ≥ 0.80 с реранком

| | |
|---|---|
| **Цель** | Ответ агента опирается на факты из извлечённых чанков, а не на внутреннее знание модели |
| **Стимул** | Пользователь задаёт вопрос по коду конфигурации 1С |
| **Реакция** | MCP-сервер возвращает ответ с атрибуцией источников (спан-привязка, [ADR 0003](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md)) |
| **Критерий** | `faithfulness` (RAGAS) ≥ **0.80** при активном реранкере (Cohere Rerank v4 или BGE-reranker-v2-m3); `context_relevance` считается отдельно ([ADR 0002](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md)) |

> Пороги финально калибруются eval-харнессом (тема 6, HLE-418). Число 0.80 — baseline; исследовательские отчёты видели 0.85–0.90 как целевой потолок после настройки.

---

## QS-02 — Latency: интерактивный ответ на запрос по коду

| | |
|---|---|
| **Цель** | Пользователь не прерывает диалог из-за долгого ожидания |
| **Стимул** | Запрос по коду поступает в MCP-сервер (исключая фолбэк/дип-ресёрч) |
| **Реакция** | Первый содержательный токен ответа доставлен клиенту |
| **Критерий** | P95 Time-to-first-token ≤ **5 секунд** на машине с SSD и ≥ 8 GB RAM; охватывает граф + реранк + генерацию через DeepSeek Flash ([ADR 0021](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md)) |

---

## QS-03 — Локальная установка: one-click для нетехнического пользователя

| | |
|---|---|
| **Цель** | Нетехнический пользователь разворачивает систему без ручной настройки окружения |
| **Стимул** | Пользователь скачивает репозиторий и запускает одну команду |
| **Реакция** | Cherry Studio + MCP-сервер Азимут + Qdrant поднимаются и готовы к работе |
| **Критерий** | `docker compose up` — единственный шаг после клонирования; Java, Node, Go — не требуются на хосте; конфигурация Cherry Studio преднастроена в поставке ([ADR 0019](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0019-cherry-studio-default-client.md)) |

---

## QS-04 — Отказоустойчивость: фолбэк при недоступности облачной LLM

| | |
|---|---|
| **Цель** | Graceful degradation — при отказе основной облачной LLM система либо переходит на запасного провайдера (если настроен), либо возвращает пользователю явную ошибку, а не вешается и не выдаёт ложный ответ |
| **Стимул** | Основная облачная LLM ([DeepSeek по умолчанию, ADR 0021](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md)) возвращает ошибку, таймаут или 5xx |
| **Реакция** | Adapter-слой LLM ([ADR 0020](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md)) проверяет конфигурацию: <br>• если в `.env`/конфиге прописан **backup-провайдер** (Claude / Qwen / Yandex) с валидным API-ключом → retry через него с тем же payload <br>• если backup **не сконфигурирован** → возвращает пользователю структурный error `{error: "llm_unavailable", retry_after: 60}` <br>**НЕ** активирует дип-ресёрч-режим — это другой сценарий (Р7 / [ADR 0007](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md), proposed): дип-ресёрч триггерится низкой релевантностью ретривера, а не падением LLM-API |
| **Критерий** | При настроенном backup — retry-call за ≤ **5 секунд** после первой ошибки; метрики в Sentry: `llm_primary_failure_total` (счётчик), `llm_backup_success_total` (счётчик); при отсутствии backup — `llm_unavailable_returned_to_user_total` + HTTP 5xx со структурным error-объектом |

⚠️ предположение: конкретная механика backup-провайдера (retry-стратегия, timeout, какие провайдеры обязательны/опциональны) **пока не зафиксирована ADR** — нужно проектировать. Текущая реализация: только primary без retry.
