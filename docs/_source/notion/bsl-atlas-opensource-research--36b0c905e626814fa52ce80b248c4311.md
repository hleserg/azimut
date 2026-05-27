Here is the result of "view" for the Page with URL https://www.notion.so/36b0c905e626814fa52ce80b248c4311 as of 2026-05-25T19:27:53.548Z:
<page url="https://www.notion.so/36b0c905e626814fa52ce80b248c4311" icon="🔍">
<ancestor-path>
<parent-page url="https://www.notion.so/36b0c905e626819eaca7ed0875cb6f8e" title="🤖 1С-ассистент — Агент-консультант по 1С ERP"/>
</ancestor-path>
<properties>
{"title":"🔍 Исследование: опенсорсные компоненты для форка bsl-atlas — 25.05.2026"}
</properties>
<content>
> Источник: deep research + разбор в чате 25.05.2026. Полный markdown-файл доступен как артефакт в чате Claude.
## Коротко
- **Форкнуть bsl-atlas и добавить \~10 хорошо подобранных библиотек** — лучше, чем брать большую платформу целиком. bsl-atlas уже даёт FastMCP-сервер, парсер BSL/XML, структурный индекс SQLite/FTS5, граф вызовов и Docker-обёртку — именно то, чего нет ни в одной универсальной RAG-платформе.
- **Главное решение «купить vs построить» — веб-морда**: НЕ заменять bsl-atlas на RAGFlow/kotaemon/Onyx целиком. Прикрутить **kotaemon (Apache-2.0)** как тонкий фронт; если нужна мульти-аренда из коробки — **RAGFlow (Apache-2.0)**.
- **Мульти-аренда решается на уровне Qdrant** через payload-разбиение (`group_id`, `is_tenant=true`) + Tiered Multitenancy 1.16 + **Authentik (MIT)** для FastAPI/веб-морды + FastMCP OAuth 2.1 для MCP.
---
## Сводная таблица выбора компонентов
<table header-row="true">
<tr>
<td>Пробел</td>
<td>Дроп-ин</td>
<td>Лицензия</td>
<td>Запасной</td>
</tr>
<tr>
<td>1 Гибридный поиск</td>
<td>`qdrant-client`  • `FlagEmbedding.BGEM3FlagModel`  • RRF (шаблон yuniko-software/bge-m3-qdrant-sample)</td>
<td>Apache-2.0 / MIT</td>
<td>Haystack `QdrantHybridRetriever`</td>
</tr>
<tr>
<td>2 Контекстные чанки</td>
<td>`llama_index.core.extractors.DocumentContextExtractor`</td>
<td>MIT</td>
<td>Anthropic cookbook</td>
</tr>
<tr>
<td>3 AST-чанкинг</td>
<td>Расширить парсер bsl-atlas → уровень процедур; stretch: `yilinjz/astchunk`  • `alkoleft/tree-sitter-bsl`</td>
<td>разная</td>
<td>`llama-index` `CodeSplitter` с кастомным парсером</td>
</tr>
<tr>
<td>4 Реранкинг</td>
<td>`AnswerDotAI/rerankers` v0.10.0 (Cohere + локальный BGE)</td>
<td>MIT</td>
<td>LlamaIndex `CohereRerank`+`SentenceTransformerRerank`</td>
</tr>
<tr>
<td>5 Eval</td>
<td>`ragas`  • `adapt_prompts("russian")` в CI</td>
<td>Apache-2.0</td>
<td>DeepEval</td>
</tr>
<tr>
<td>6 Цитаты / отказ</td>
<td>LlamaIndex `CitationQueryEngine`  • Self-RAG-промпт</td>
<td>MIT</td>
<td>NeMo Guardrails retrieval rails</td>
</tr>
<tr>
<td>7 OCR / скриншоты</td>
<td>PaddleOCR-VL (текст) + Cohere Embed v4 (мультимодаль)</td>
<td>Apache-2.0 / Cohere TOS</td>
<td>ColQwen2.5 через `colpali-engine` (MIT)</td>
</tr>
<tr>
<td>8 Приём доков</td>
<td>`docling-project/docling`</td>
<td>MIT</td>
<td>markitdown, [unstructured.io](http://unstructured.io)</td>
</tr>
<tr>
<td>9 Мульти-аренда</td>
<td>Payload-разбиение Qdrant (`group_id`, `is_tenant=true`) + Tiered MT 1.16</td>
<td>Apache-2.0</td>
<td>Отдельные коллекции только для крупных тенантов</td>
</tr>
<tr>
<td>10 Веб-морда</td>
<td>kotaemon (лёгкий) или RAGFlow (полноценная мульти-аренда)</td>
<td>Apache-2.0</td>
<td>Onyx (Danswer)</td>
</tr>
<tr>
<td>11 Авторизация</td>
<td>Authentik IdP + FastMCP OAuth + `fastapi-keycloak-middleware`</td>
<td>MIT / Apache-2.0</td>
<td>Keycloak</td>
</tr>
<tr>
<td>12 Наблюдаемость</td>
<td>Langfuse self-hosted (Postgres+ClickHouse) + Sentry-алерты</td>
<td>MIT</td>
<td>Arize Phoenix (ELv2)</td>
</tr>
<tr>
<td>13 1С-каннибализация</td>
<td>`alkoleft/mcp-bsl-platform-context` (запустить рядом) + `AlekseiSeleznev/onec-mcp-universal` (паттерн шлюза)</td>
<td>MIT / уточнить</td>
<td>`feenlace/mcp-1c` (только референс)</td>
</tr>
</table>
---
## Ключевые находки по каждому пробелу
### Пробел 1 — Гибридный поиск
Написать класс `BgeM3QdrantRetriever` (\~150 строк) на FlagEmbedding напрямую + Qdrant `query_points` с `prefetch=[dense, sparse]` и RRF. Шаблон `yuniko-software/bge-m3-qdrant-sample` — буквальный старт. Запасные: Haystack `QdrantHybridRetriever`, LlamaIndex `QdrantVectorStore(enable_hybrid=True)`.
### Пробел 2 — Contextual Retrieval
`DocumentContextExtractor` (MIT, в `llama-index-core`, PR #17367) — работает в `IngestionPipeline`, решает rate-limit, кеширование промпта, большие документы. Стоимость: **\$1,02 на миллион токенов** при кешировании. Использовать Claude Haiku как контекстуализатор.
### Пробел 3 — AST-чанкинг для BSL
Три слоя:
- **Слой A (дефолт):** расширить парсер bsl-atlas → чанки на уровне Процедура/Функция/Область. Ничего нового устанавливать не нужно.
- **Слой B:** `alkoleft/tree-sitter-bsl` (единственная публичная tree-sitter-грамматика для BSL, \~28 ⭐, лицензию проверить) + `llama-index CodeSplitter` с кастомным `parser=`.
- **Слой C (лучший алгоритм):** `yilinjz/astchunk` (`pip install astchunk`, EMNLP Findings 2025) — нужно добавить BSL-адаптер.
Стек `1c-syntax` (LGPL/GPL, JVM): только через subprocess. `bsl-language-server` (LGPL, 395⭐, март 2026), `mdclasses` (LGPL), `bsl-parser` (GPL).
### Пробел 4 — Реранкинг
`AnswerDotAI/rerankers` (MIT, v0.10.0) — единый интерфейс для Cohere + BGE + ColBERT.
```python
from rerankers import Reranker
remote = Reranker("cohere", lang="other", api_key=COHERE_KEY)
local  = Reranker("BAAI/bge-reranker-v2-m3", model_type="cross-encoder")
```
Оговорка: open issue #50 по Cohere v4 — проверить поддержку.
### Пробел 5 — Eval harness
`ragas` (Apache-2.0, 12,9k⭐) + `adapt_prompts(language="russian")` + `TestsetGenerator`. Подключить в CI как GitHub Actions; PR падает при просадке Faithfulness/Context Recall. Claude как модель-судья.
### Пробел 6 — Анти-галлюцинации и цитаты
LlamaIndex `CitationQueryEngine` (MIT) — ответы с ссылками `[1]`, `[2]` на уровне чанков. `CITATION_QA_TEMPLATE` перевести на русский. Дополнить паттерном Self-RAG (`AkariAsai/self-rag`, MIT, 2,2k⭐) как Claude-промпт-сигналы: `[ISREL]`, `[ISSUP]`, `[ISUSE]`.
### Пробел 7 — OCR и скриншоты
- **PaddleOCR-VL** (Apache-2.0, 71,8k⭐) — кириллица через `cyrillic_PP-OCRv3_mobile_rec`; v3.2.0 авг 2025.
- **Cohere Embed v4** (апр 2025) — мультимодальный, контекст 128k, 100+ языков. One-vendor рядом с Rerank v4.
- **ColQwen2.5** через `illuin-tech/colpali` (MIT, v0.3.16 май 2026) — visual retrieval без OCR; нативная поддержка в Qdrant multi-vector MaxSim.
- Surya OCR: код GPL-3 → только subprocess.
### Пробел 8 — Приём документов
`docling-project/docling` (MIT, 60,2k⭐, LF AI & Data). PDF/DOCX/PPTX/XLSX/HTML → Markdown. CHM офлайн-ИТС: `7z x` → HTML → Docling.
### Пробел 9 — Мульти-аренда Qdrant
Одна коллекция, поле `group_id` с `is_tenant=True`. Qdrant 1.16 (сент 2025): Tiered Multitenancy. **Не создавать отдельную коллекцию на тенанта** (лимит \~1000 коллекций).
```python
client.create_payload_index(
    collection_name="docs",
    field_name="group_id",
    field_schema=models.KeywordIndexParams(is_tenant=True)
)
```
### Пробел 10 — Веб-морда
- **kotaemon** (Apache-2.0, Gradio) — стартовать с него.
- **RAGFlow** (Apache-2.0) — мульти-аренда из коробки, DeepDoc, тяжёлый (\~3,4 ГБ). Паттерн: RAGFlow как UI, bsl-atlas MCP как бэкенд для BSL-запросов.
- **Open WebUI**: лицензия ужесточилась в 2024–2025 — читать актуальный LICENSE.
### Пробел 11 — Авторизация
**FastMCP OAuth 2.1** (PR #1327, авг 2025) + **Authentik** (MIT, Docker-native) как IdP + **`fastapi-keycloak-middleware`** (Apache-2.0). JWT с `tenant_id`-клеймом → один реалм для MCP и веб-морды.
### Пробел 12 — Наблюдаемость
**Langfuse self-hosted** (MIT, Postgres+ClickHouse+Redis+S3) — тегирование тенанта через `userId` и `metadata.tenant_id`. **Arize Phoenix** (ELv2) — альтернатива, лучший RAG retrieval view, нельзя перепродавать как сервис. Дублировать трейсы в **Sentry** через OTel → пороговые алерты по тенанту.
### Пробел 13 — Существующие 1С/BSL проекты
- **`alkoleft/mcp-bsl-platform-context`** (MIT, \~130⭐) — справочник синтаксиса платформы через MCP. Запустить рядом в Claude Desktop бесплатно.
- **`AlekseiSeleznev/onec-mcp-universal`** (\~400 строк Python) — MCP-гейтвей-агрегатор. Прямой кандидат на роль шлюза перед bsl-atlas.
- **`alkoleft/platform-context-exporter`** — экспортирует shcntx_ru.hbk → JSON/Markdown. Препроцессор.
- **`alkoleft/bsl-graph`** — граф знаний конфигурации. Каннибализировать слой извлечения метаданных.
- **`FSerg/mcp-1c-v1`** (TypeScript, \~152⭐) — RAG-описание структуры конфигурации 1С. Стоит код-ревью.
- **`feenlace/mcp-1c`** (Go, freemium) — самый полированный конкурент. Только референс, не копировать.
- Стек **1c-syntax** (LGPL/GPL, JVM): только subprocess.
---
## Дорожная карта
**Фаза 1 (нед. 1–3):** Qdrant гибрид + rerankers + CitationQueryEngine. Порог: Recall@5 \> 0,85, Faithfulness \> 0,90.
**Фаза 2 (нед. 4–6):** DocumentContextExtractor + AST-чанкинг процедур + Docling + ragas в CI. Порог: Faithfulness +5 п.п.
**Фаза 3 (нед. 7–10):** Qdrant payload-мульти-аренда + Authentik + FastMCP OAuth + kotaemon. Порог: 2 пилотных клиента видят только свои данные.
**Фаза 4 (нед. 11–13):** Langfuse + Sentry-алерты по тенанту + PaddleOCR/Cohere Embed v4 + Tiered MT. Порог: P95 \< 4 с, Faithfulness ≥ 0,9, нулевые утечки между тенантами.
---
## Оговорки по лицензиям
- `alkoleft/tree-sitter-bsl` — лицензию проверить напрямую в репо.
- Surya OCR — GPL-3, только subprocess.
- Стек 1c-syntax — LGPL/GPL, только subprocess + JSON CLI.
- Open WebUI — перечитать актуальный LICENSE перед коммерческим деплоем.
- Arize Phoenix — ELv2, нельзя перепродавать как hosted-сервис.
- `feenlace/mcp-1c` — freemium, не копировать код без разрешения.
- Публичных форков bsl-atlas в поиске не найдено.
</content>
</page>
