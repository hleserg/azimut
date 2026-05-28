workspace "Азимут" "ИИ-ассистент по коду 1С на базе форка bsl-atlas (ADR 0034)" {
    # Запуск: docker run --rm -p 8080:8080 -v .:/usr/local/structurizr --user $(id -u):$(id -g) structurizr/structurizr

    !identifiers hierarchical

    configuration {
        scope softwaresystem
    }

    model {
        # ── Пользователи ─────────────────────────────────────────────────────────
        serg = person "Сергей" "Лид-разработчик; основной пользователь системы на ежедневной основе."
        mama = person "Мама" "Бухгалтер / 1С-оператор; конечный пользователь-нетехник."

        # ── Внешние системы-источники ────────────────────────────────────────────
        onecPlatform = softwareSystem "Платформа 1С" "Конфигурации ERP/Бухгалтерия; источник BSL-кода и метаданных через DumpConfigToFiles." {
            tags "External"
        }
        deepSeekLLM = softwareSystem "DeepSeek" "Облачная разговорная модель (дефолт): DeepSeek V4 Flash (обычный код) / Pro (тяжёлый код); ADR 0021." {
            tags "External"
        }
        claudeLLM = softwareSystem "Claude (Anthropic)" "Облачная LLM для LLM-судьи и Сергея-премиум; Anthropic API; ADR 0021." {
            tags "External"
        }
        its = softwareSystem "ИТС / Портал платформы" "Справочные материалы 1С; третий уровень иерархии источников (Р6, ADR 0006)." {
            tags "External"
        }

        # ── Внешние MCP-клиенты (ADR 0019) — отдельные softwareSystem ────────────
        cherryStudio = softwareSystem "Cherry Studio" "MCP-клиент по умолчанию для Мамы и Сергея-everyday; подключается к MCP-оркестратору по JSON-RPC (ADR 0019)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
            }
        }
        claudeDesktop = softwareSystem "Claude Desktop" "MCP-клиент для Сергея-премиум дома; поддерживает несколько MCP-серверов параллельно (ADR 0019)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
            }
        }
        miniAi1c = softwareSystem "mini-ai-1c" "Клиент Сергея для захвата BSL-кода непосредственно из Конфигуратора 1С (ADR 0019)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
            }
        }

        # ── Внешний MCP-сервер платформы 1С (ADR 0017) ───────────────────────────
        bslPlatformMcp = softwareSystem "mcp-bsl-platform-context" "Drop-in MCP-сервер: справочник платформы 1С (MIT, alkoleft). Второй MCP-сервер рядом с Азимутом (ADR 0017)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md"
            }
        }

        # ── Внешний мониторинг (ADR 0028 open) ───────────────────────────────────
        sentry = softwareSystem "Sentry / GlitchTip" "Мониторинг ошибок и распределённая трассировка. Выбор между Sentry SaaS и self-hosted GlitchTip открыт (ADR 0028)." {
            tags "External" "Proposed"
            properties {
                "adr-link" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
            }
        }

        # ── Основная система ────────────────────────────────────────────────────
        azimuth = softwareSystem "Азимут" "MCP-сервер + Азимут-ядро: понимание кода 1С, RAG, анти-галлюцинации. Форк bsl-atlas под AGPL-3.0 (ADR 0011)." {
            properties {
                "adr-link" "docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md"
            }

            !docs docs/architecture
            !adrs docs/architecture/adr/anti-hallucinations madr
            !adrs docs/architecture/adr/foundation madr
            !adrs docs/architecture/adr/code-processing madr
            !adrs docs/architecture/adr/open madr
            !adrs docs/architecture/adr/tooling madr

            # ── MCP-оркестратор (наш ключевой код) ──────────────────────────────
            mcpOrchestrator = container "MCP-оркестратор" "Принимает MCP-запросы клиентов; управляет ретривингом, иерархией источников, LLM-судьёй, фолбэком. Граница форк vs наш код (ADR 0022)." "Python / FastMCP" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md"
                    "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                }

                querySufficiency = component "Query Sufficiency Gate" "Три механики на сервере: гейт «слишком общий запрос», подсказки агенту на основе индекса, проверка дрейфа переформулировки (П3, ADR 0010 proposed)." "Python" {
                    tags "Proposed"
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md"
                        "open-issues" "docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md"
                    }
                }

                serverControlledRetrieval = component "Server-Controlled Retrieval" "Контроль ретривинга на стороне сервера: планка релевантности, триггер добора, потолок окна контекста (Р5, ADR 0005)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md"
                    }
                }

                routeDispatcher = component "Route Dispatcher" "Диспетчер поиска по коду: fallback-цепочка graph → metadata → grep по образцу comol/ai_rules_1c (ADR 0026)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0026-code-search-routing.md"
                    }
                }

                sourceHierarchy = component "Source Hierarchy" "Иерархия источников при конфликте: код → справка → ИТС. Применяет метрику противоречивости (Р6, ADR 0006)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0006-р6-source-hierarchy.md"
                        "open-issues" "docs/architecture/adr/open/0033-r1-contradiction-detection-mechanics.md"
                    }
                }

                contradictionMetric = component "Contradiction Metric" "Метрика противоречивости источников ПЕРЕД выдачей ответа. Механика детектирования открыта (Р1, ADR 0001; см. ADR 0033)." "Python" {
                    tags "Proposed"
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0001-р1-metric-contradiction.md"
                        "open-issues" "docs/architecture/adr/open/0033-r1-contradiction-detection-mechanics.md"
                    }
                }

                llmJudge = component "LLM Judge" "LLM-судья со спан-привязкой: арбитрирует faithfulness и groundedness ответа через Claude API (Р3, ADR 0003)." "Python / Claude API" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md"
                    }
                }

                groundednessDetector = component "Groundedness Detector" "Три уровня реакции на сигнал LLM-судьи: блок-и-возврат / плашка «частично из общих знаний» / лог в Sentry (П1, ADR 0008 proposed)." "Python" {
                    tags "Proposed"
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md"
                        "open-issues" "docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md"
                    }
                }

                reRetrieval = component "Re-Retrieval Controller" "Второй проход ретривера по переформулированному запросу. Инициатор — агент, исполнитель — сервер; гейт N повторов на запрос (П2, ADR 0009 proposed)." "Python" {
                    tags "Proposed"
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md"
                        "open-issues" "docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md"
                    }
                }

                fallbackMode = component "Fallback Mode" "Фолбэк = смена режима (дип-ресёрч с тем же контрактом); заменил «честный тупик» Р4. (Р7, ADR 0007)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md"
                    }
                }
            }

            # ── Азимут-ядро (форк bsl-atlas, наш ключевой код) ──────────────────
            azimuthCore = container "Азимут-ядро" "Форк bsl-atlas: парсер BSL, чанкер, индексатор, граф вызовов, резолвер, эмбеддер, реранкер. Роль форка — только «движок понимания кода» (ADR 0013)." "Python / bsl-atlas fork" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    "open-issues" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                }

                chunker = component "Чанкер" "Детерминированная структурная резка: функция = чанк (≤ порога); блоки Если/Цикл/Попытка/Область с шапкой контекста; запросы режутся по `|;`, ВТ помечаются. LLM не используем (ADR 0024)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md"
                    }
                }

                indexer = component "Индексатор" "Инкрементальная индексация: manifest-diff {path: mtime+size}, дисковый кеш по SHA-256, шардирование по cpu_count(), GC-tuning на этапе batch (ADR 0027)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md"
                    }
                }

                graph = component "Граф вызовов" "Построение графа BSL-вызовов; типизация процедур/функций; рёбра событие→обработчик достраиваем поверх metacode-подхода." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    }
                }

                resolver = component "Same-Named Resolver" "Резолв одноимённых процедур: routines + calls(callee_id NULL) → пост-проход. Алгоритм не написан — главный технический риск темы 2 (ADR 0025 proposed)." "Python" {
                    tags "Proposed"
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                        "open-issues" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                    }
                }

                bslSynonyms = component "BSL Synonyms RU↔EN" "Анализатор синонимов BSL: СтрНайти↔StrFind, ~40 ключевых слов + ~180 функций. Подключается к Embedder и Route Dispatcher для нормализации запросов (ADR 0027)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md"
                    }
                }

                embedder = component "Эмбеддер" "Векторизация чанков: BGE-M3 локально по умолчанию; Cohere Embed опционально через адаптер (ADR 0020)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md"
                    }
                }

                reranker = component "Реранкер" "Реранкинг результатов перед выдачей: BGE-reranker локально; Cohere Rerank опционально. Faithfulness vs relevance (ADR 0002)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md"
                    }
                }
            }

            # ── Векторное хранилище (ContainerDb) ───────────────────────────────
            qdrant = container "Qdrant" "Векторное хранилище чанков и метаданных. Embedded локально или server-mode на VDS (ADR 0029 open)." "Qdrant" {
                tags "Database"
                properties {
                    "adr-link" "docs/architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md"
                }
            }

            # ── Adapter-слой LLM (наш код, ADR 0020/0021) ───────────────────────
            llmAdapter = container "Adapter-слой LLM" "Абстракция над разговорной облачной LLM; дефолт — DeepSeek V4; запас — Claude/Qwen/Yandex. Финал валидируем eval-ом в теме 6 (ADR 0020, 0021)." "Python" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md"
                    "open-issues" "docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md"
                }
            }
        }

        # ── Связи: пользователи → внешние клиенты ───────────────────────────────
        serg -> cherryStudio "использует everyday" "Desktop GUI"
        serg -> claudeDesktop "использует для сложного кода" "Desktop GUI"
        serg -> miniAi1c "захватывает код из Конфигуратора" "Desktop GUI"
        mama -> cherryStudio "задаёт вопросы по 1С" "Desktop GUI"

        # ── Связи: внешние клиенты → MCP-оркестратор ────────────────────────────
        cherryStudio -> azimuth.mcpOrchestrator "вызывает инструменты" "MCP / JSON-RPC"
        claudeDesktop -> azimuth.mcpOrchestrator "вызывает инструменты" "MCP / JSON-RPC"
        miniAi1c -> azimuth.mcpOrchestrator "вызывает инструменты" "MCP / JSON-RPC"

        # ── Связи: внутри системы (Container-level) ──────────────────────────────
        azimuth.mcpOrchestrator -> azimuth.azimuthCore "запрашивает индекс кода" "Python API"
        azimuth.mcpOrchestrator -> azimuth.qdrant "читает векторы и метаданные" "HTTP / Qdrant API"
        azimuth.mcpOrchestrator -> azimuth.llmAdapter "генерирует ответ и фолбэк" "HTTPS / JSON"
        azimuth.azimuthCore -> azimuth.qdrant "читает и сохраняет векторы" "HTTP / gRPC"
        azimuth.llmAdapter -> deepSeekLLM "генерирует текст" "HTTPS / OpenAI-compatible API"
        onecPlatform -> azimuth.azimuthCore "передаёт BSL-код и метаданные" "DumpConfigToFiles / File system"

        # ── Связи: система → внешние сервисы ────────────────────────────────────
        azimuth.mcpOrchestrator -> bslPlatformMcp "запрашивает справку платформы 1С" "MCP / JSON-RPC"
        azimuth.mcpOrchestrator -> sentry "отправляет трассировки и ошибки" "HTTPS / Sentry SDK"
        azimuth.mcpOrchestrator -> its "ищет справочные материалы (Р6, ADR 0006)" "HTTPS"

        # ── Связи: компоненты Азимут-ядра ────────────────────────────────────────
        azimuth.azimuthCore.chunker -> azimuth.azimuthCore.indexer "передаёт чанки на индексацию" "in-process"
        azimuth.azimuthCore.indexer -> azimuth.azimuthCore.graph "передаёт обогащённый поток" "in-process"
        azimuth.azimuthCore.graph -> azimuth.azimuthCore.resolver "передаёт calls(callee_id NULL) на резолв" "in-process"
        azimuth.azimuthCore.resolver -> azimuth.azimuthCore.embedder "передаёт resolved-чанки на векторизацию" "in-process"
        azimuth.azimuthCore.bslSynonyms -> azimuth.azimuthCore.embedder "предоставляет словарь синонимов" "in-process"
        azimuth.azimuthCore.embedder -> azimuth.qdrant "сохраняет векторы" "HTTP / Qdrant API"
        azimuth.azimuthCore.reranker -> azimuth.mcpOrchestrator.routeDispatcher "возвращает реранкированные результаты" "in-process"

        # ── Связи: компоненты MCP-оркестратора ───────────────────────────────────
        azimuth.mcpOrchestrator.querySufficiency -> azimuth.mcpOrchestrator.serverControlledRetrieval "пропускает только осмысленные запросы" "in-process"
        azimuth.mcpOrchestrator.serverControlledRetrieval -> azimuth.mcpOrchestrator.routeDispatcher "триггерит добор у диспетчера" "in-process"
        azimuth.mcpOrchestrator.routeDispatcher -> azimuth.azimuthCore "маршрутизирует поиск (graph → metadata → grep)" "Python API"
        azimuth.mcpOrchestrator.routeDispatcher -> azimuth.azimuthCore.bslSynonyms "нормализует запрос рус↔англ" "Python API"
        azimuth.mcpOrchestrator.sourceHierarchy -> azimuth.mcpOrchestrator.contradictionMetric "передаёт результаты на проверку" "in-process"
        azimuth.mcpOrchestrator.contradictionMetric -> azimuth.mcpOrchestrator.llmJudge "передаёт спорные случаи арбитру" "in-process"
        azimuth.mcpOrchestrator.llmJudge -> claudeLLM "арбитрирует качество ответа" "HTTPS / Anthropic API"
        azimuth.mcpOrchestrator.llmJudge -> azimuth.mcpOrchestrator.groundednessDetector "передаёт сигнал недогрунтованности" "in-process"
        azimuth.mcpOrchestrator.groundednessDetector -> azimuth.mcpOrchestrator.reRetrieval "триггерит повторный проход (уровень 1)" "in-process"
        azimuth.mcpOrchestrator.groundednessDetector -> sentry "лог уровней 2/3" "HTTPS / Sentry SDK"
        azimuth.mcpOrchestrator.reRetrieval -> azimuth.mcpOrchestrator.serverControlledRetrieval "запрашивает повтор в рамках бюджета окна" "in-process"
        azimuth.mcpOrchestrator.fallbackMode -> azimuth.llmAdapter "инициирует дип-ресёрч" "Python API"
    }

    views {
        systemContext azimuth "systemContext" "Кто взаимодействует с системой и как. C4 Level 1." {
            include *
            autolayout lr
        }

        container azimuth "container" "Из чего состоит система как набор запущенных процессов. C4 Level 2." {
            include *
            autolayout lr
        }

        component azimuth.azimuthCore "componentAzimuthCore" "Внутренние компоненты Азимут-ядра. C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.mcpOrchestrator "componentMCPOrchestrator" "Внутренние компоненты MCP-оркестратора. C4 Level 3." {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            # ── Элементы со статусом proposed: визуально отличимы (ADR 0023) ──
            element "Proposed" {
                background #E6D5A4
                color #000000
                border dashed
                stroke #B89B5E
            }
        }
    }

}
