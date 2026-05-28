# 6. Поведение в рантайме (Runtime View)

> ⚠️ **Этот файл не предназначен для Structurizr viewer.** Mermaid `sequenceDiagram` блоки ниже Structurizr Local не рендерит — приходят как сырой код на нечитаемом dark-фоне.
>
> Открывай этот файл **в одном из мест с рендером Mermaid:**
> - GitHub web: [`docs/architecture/06-runtime-view.md` на github.com](https://github.com/hleserg/azimut/blob/master/docs/architecture/06-runtime-view.md)
> - IDE с Mermaid-плагином (VS Code + Markdown Preview Mermaid Support, JetBrains встроенно)
> - Любой markdown-viewer с Mermaid (Obsidian, Typora и т.п.)
>
> Structurizr-viewer (`docker compose --profile diagrams up -d structurizr`) — только для C4 views из `workspace.dsl`. Runtime-сценарии живут здесь как Mermaid намеренно (ADR 0034: «Mermaid `sequenceDiagram` — только для §6, лучше читается в git diff»).

---

> arc42 §6 — ключевые сценарии взаимодействия компонентов.
> Диаграммы: Mermaid `sequenceDiagram` (единственное место в документации, где допускается Mermaid, ADR 0034).

---

## 6.1 Сценарий: Индексация кода

Платформа 1С экспортирует BSL-файлы → Азимут-ядро строит индекс → векторы сохраняются в Qdrant.

✅ проверено: `workspace.dsl` (связи onecPlatform → azimuthCore → qdrant + компоненты Азимут-ядра)

```mermaid
sequenceDiagram
    participant P as Платформа 1С
    participant Core as Азимут-ядро
    participant Qdrant as Qdrant

    P->>+Core: DumpConfigToFiles (BSL-модули + XML-метаданные)
    Core->>Core: Чанкер: детерминированная резка (ADR 0024)
    Core->>Core: Граф вызовов: построение BSL-графа (ADR 0025)
    Core->>Core: Эмбеддер: BGE-M3 векторизация чанков (ADR 0020)
    Core->>+Qdrant: сохранить векторы и метаданные
    Qdrant-->>-Core: OK
    deactivate Core
```

---

## 6.2 Сценарий: Запрос пользователя

Пользователь задаёт вопрос → клиент → MCP-оркестратор → ретривинг → генерация → ответ.

✅ проверено: `workspace.dsl` (связи клиент → mcpOrchestrator → azimuthCore/qdrant/llmAdapter)

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant CS as Cherry Studio
    participant Orch as MCP-оркестратор
    participant Core as Азимут-ядро
    participant Qdrant as Qdrant
    participant LLM as Adapter-слой LLM
    participant DS as DeepSeek

    User->>CS: вопрос по 1С
    CS->>+Orch: MCP tool call (JSON-RPC)
    Orch->>Orch: SCR: оценить запрос, установить бюджет (ADR 0005)
    Orch->>+Core: маршрутизировать поиск (ADR 0026)
    Core->>+Qdrant: векторный поиск по эмбеддингу вопроса
    Qdrant-->>-Core: топ-N чанков
    Core->>Core: Реранкер: переоценить по faithfulness + relevance (ADR 0002)
    Core-->>-Orch: реранкированные чанки
    Orch->>Orch: Метрика противоречивости (ADR 0001)
    Orch->>Orch: Иерархия источников: код → справка → ИТС (ADR 0006)
    Orch->>+LLM: генерировать ответ (контекст + вопрос)
    LLM->>+DS: HTTPS (DeepSeek V4 Flash/Pro, ADR 0021)
    DS-->>-LLM: сгенерированный текст
    LLM-->>-Orch: ответ
    Orch-->>-CS: MCP response
    CS-->>User: ответ
```

---

## 6.3 Сценарий: Обновление индекса

Изменились BSL-файлы → инкрементальная переиндексация только изменённых модулей.

✅ проверено: ADR 0027 (техника кеша по SHA из feenlace)

```mermaid
sequenceDiagram
    participant P as Платформа 1С
    participant Core as Азимут-ядро
    participant Qdrant as Qdrant

    P->>+Core: обновлённые BSL-файлы (DumpConfigToFiles)
    Core->>Core: вычислить diff манифеста (SHA-кеш, ADR 0027)
    alt есть изменения
        Core->>Core: Чанкер: перечанковать изменённые модули
        Core->>Core: Граф вызовов: перестроить затронутые узлы
        Core->>Core: Эмбеддер: переиндексировать изменённые чанки
        Core->>+Qdrant: upsert обновлённых векторов
        Qdrant-->>-Core: OK
    else нет изменений
        Note over Core: пропустить (кеш по SHA)
    end
    deactivate Core
```

---

## 6.4 Сценарий: Фолбэк Р7 (смена режима)

Ретривинг не набирает достаточной релевантности → оркестратор переключается в дип-ресёрч.

✅ проверено: ADR 0007 (Р7: фолбэк = смена режима), ADR 0005 (планка релевантности SCR)

```mermaid
sequenceDiagram
    actor User as Пользователь
    participant Orch as MCP-оркестратор
    participant Core as Азимут-ядро
    participant Qdrant as Qdrant
    participant LLM as Adapter-слой LLM

    User->>+Orch: сложный запрос
    Orch->>+Core: маршрутизировать поиск (graph → metadata → grep, ADR 0026)
    Core->>+Qdrant: векторный поиск
    Qdrant-->>-Core: чанки ниже порога релевантности
    Core-->>-Orch: результаты (низкая релевантность)
    Orch->>Orch: SCR: добор исчерпан, планка не достигнута (ADR 0005)
    Note over Orch: Р7: фолбэк = смена режима (ADR 0007)
    Orch->>+LLM: дип-ресёрч (тот же API-контракт, расширенный режим)
    LLM-->>-Orch: ответ с меткой «deep-research / не из локального индекса»
    Orch-->>-User: ответ + метка режима
```

---

## 6.5 Сценарий: LLM-судья Р3

После генерации чернового ответа LLM-судья проверяет faithfulness и groundedness; при недостаточном score — триггер добора.

✅ проверено: ADR 0003 (Р3: LLM-судья со спан-привязкой), ADR 0005 (SCR: сигнал на добор)

```mermaid
sequenceDiagram
    participant Orch as MCP-оркестратор
    participant LLM as Adapter-слой LLM
    participant Judge as LLM Judge
    participant Claude as Claude (Anthropic)
    participant SCR as Server-Controlled Retrieval

    Orch->>+LLM: сгенерировать ответ
    LLM-->>-Orch: черновик ответа + спан привязки к чанкам
    Orch->>+Judge: оценить faithfulness + groundedness (ADR 0003)
    Judge->>+Claude: арбитраж через Anthropic API
    Claude-->>-Judge: verdict (оценка + объяснение)
    Judge-->>-Orch: verdict
    alt verdict: достаточно
        Orch-->>Orch: вернуть ответ пользователю
    else verdict: недостаточно
        Orch->>SCR: сигнал на добор (ADR 0005)
        SCR-->>Orch: инициировать повторный ретривинг
        Note over Orch,SCR: до MAX_RETRIEVAL_ROUNDS
    end
```
