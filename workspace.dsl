workspace "Азимут" "ИИ-ассистент по коду 1С на базе форка bsl-atlas (ADR 0034)" {
    # Запуск: docker run --rm -p 8080:8080 -v .:/usr/local/structurizr --user $(id -u):$(id -g) structurizr/structurizr local

    !identifiers hierarchical

    model {
        # Пользователи
        serg = person "Сергей" "Лид-разработчик; основной пользователь системы на ежедневной основе."
        mama = person "Мама" "Бухгалтер / 1С-оператор; конечный пользователь-нетехник."

        # Внешние системы-источники
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

        # Основная система
        azimuth = softwareSystem "Азимут" "MCP-сервер + Азимут-ядро: понимание кода 1С, RAG, анти-галлюцинации. Форк bsl-atlas под AGPL-3.0 (ADR 0011)." {
            properties {
                "adr-link" "docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md"
            }

            # ── Внешние клиенты (Container_Ext по реш. 1.7a, ADR 0019) ──────────────
            cherryStudio = container "Cherry Studio" "MCP-клиент по умолчанию для Мамы и Сергея-everyday; подключается к MCP-оркестратору через JSON-RPC (ADR 0019)." "Electron App" {
                tags "External"
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
                }
            }

            claudeDesktop = container "Claude Desktop" "MCP-клиент для Сергея-премиум дома; поддерживает несколько MCP-серверов параллельно (ADR 0019)." "Desktop App" {
                tags "External"
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
                }
            }

            miniAi1c = container "mini-ai-1c" "Клиент Сергея для захвата BSL-кода непосредственно из Конфигуратора 1С (ADR 0019)." "Desktop App" {
                tags "External"
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
                }
            }

            # ── Внешний MCP-сервер платформы (Container_Ext, ADR 0017) ───────────────
            bslPlatformMcp = container "mcp-bsl-platform-context" "Drop-in MCP-сервер: справочник платформы 1С (MIT, alkoleft). Второй MCP рядом с Азимутом (ADR 0017)." "TypeScript / MCP" {
                tags "External"
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md"
                }
            }

            # ── Мониторинг (Container_Ext, ADR 0028 open) ───────────────────────────
            sentry = container "Sentry / GlitchTip" "Мониторинг ошибок и распределённая трассировка. Выбор между Sentry SaaS и self-hosted GlitchTip открыт (ADR 0028)." "Sentry / GlitchTip" {
                tags "External"
                properties {
                    "adr-link" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                }
            }

            # ── MCP-оркестратор (наш ключевой код) ──────────────────────────────────
            mcpOrchestrator = container "MCP-оркестратор" "Принимает MCP-запросы клиентов; управляет ретривингом, иерархией источников, LLM-судьёй, фолбэком. Граница форк vs наш код (ADR 0022)." "Python / FastMCP" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md"
                    "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                }

                serverControlledRetrieval = component "Server-Controlled Retrieval" "Контроль ретривинга на стороне сервера: планка релевантности, триггер добора, потолок окна контекста (Р5, ADR 0005)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md"
                    }
                }

                sourceHierarchy = component "Source Hierarchy" "Иерархия источников при конфликте: код → справка → ИТС. Применяет метрику противоречивости (Р6, ADR 0006)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0006-р6-source-hierarchy.md"
                        "open-issues" "docs/architecture/adr/open/0033-r1-contradiction-detection-mechanics.md"
                    }
                }

                llmJudge = component "LLM Judge" "LLM-судья со спан-привязкой: арбитрирует faithfulness и groundedness ответа через Claude API (Р3, ADR 0003)." "Python / Claude API" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md"
                    }
                }

                fallbackMode = component "Fallback Mode" "Фолбэк = смена режима (дип-ресёрч с тем же контрактом); заменил «честный тупик» Р4. (Р7, ADR 0007)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md"
                    }
                }

                contradictionMetric = component "Contradiction Metric" "Метрика противоречивости источников ПЕРЕД выдачей ответа. Механика детектирования открыта (Р1, ADR 0001; см. ADR 0033)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0001-р1-metric-contradiction.md"
                        "open-issues" "docs/architecture/adr/open/0033-r1-contradiction-detection-mechanics.md"
                    }
                }

                routeDispatcher = component "Route Dispatcher" "Диспетчер поиска по коду: fallback-цепочка graph → metadata → grep по образцу comol/ai_rules_1c (ADR 0026)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0026-code-search-routing.md"
                    }
                }
            }

            # ── Азимут-ядро (форк bsl-atlas, наш ключевой код) ──────────────────────
            azimuthCore = container "Азимут-ядро" "Форк bsl-atlas: парсер BSL, граф вызовов, чанкер, эмбеддер, реранкер. Роль форка — только «движок понимания кода» (ADR 0013)." "Python / bsl-atlas fork" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    "open-issues" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                }

                chunker = component "Чанкер" "Детерминированная структурная резка: функция = чанк (≤ порога); блоки Если/Цикл/Попытка/Область с шапкой контекста. LLM для резки не используем (ADR 0024)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md"
                    }
                }

                graph = component "Граф вызовов" "Построение графа BSL-вызовов; резолв одноимённых процедур — открытая инженерная задача (ADR 0025 proposed)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
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

            # ── Векторное хранилище (ContainerDb) ───────────────────────────────────
            qdrant = container "Qdrant" "Векторное хранилище чанков и метаданных. Embedded локально или server-mode на VDS (ADR 0029 open)." "Qdrant" {
                tags "Database"
                properties {
                    "adr-link" "docs/architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md"
                }
            }

            # ── Adapter-слой LLM (наш код, ADR 0020/0021) ───────────────────────────
            llmAdapter = container "Adapter-слой LLM" "Абстракция над разговорной облачной LLM; дефолт — DeepSeek V4; запас — Claude/Qwen/Yandex. Финал валидируем eval-ом в теме 6 (ADR 0020, 0021)." "Python" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md"
                    "open-issues" "docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md"
                }
            }
        }

        # ── Связи: пользователи → клиенты ────────────────────────────────────────
        serg -> azimuth.cherryStudio "использует everyday" "Desktop GUI"
        serg -> azimuth.claudeDesktop "использует для сложного кода" "Desktop GUI"
        serg -> azimuth.miniAi1c "захватывает код из Конфигуратора" "Desktop GUI"
        mama -> azimuth.cherryStudio "задаёт вопросы по 1С" "Desktop GUI"

        # ── Связи: клиенты → MCP-оркестратор ─────────────────────────────────────
        azimuth.cherryStudio -> azimuth.mcpOrchestrator "вызывает инструменты via" "MCP / JSON-RPC"
        azimuth.claudeDesktop -> azimuth.mcpOrchestrator "вызывает инструменты via" "MCP / JSON-RPC"
        azimuth.miniAi1c -> azimuth.mcpOrchestrator "вызывает инструменты via" "MCP / JSON-RPC"

        # ── Связи: внутри системы (Container-level) ───────────────────────────────
        azimuth.mcpOrchestrator -> azimuth.azimuthCore "запрашивает индекс кода via" "Python API"
        azimuth.mcpOrchestrator -> azimuth.qdrant "читает векторы и метаданные via" "HTTP / Qdrant API"
        azimuth.mcpOrchestrator -> azimuth.llmAdapter "генерирует ответ и фолбэк via" "HTTPS / JSON"
        azimuth.mcpOrchestrator -> azimuth.bslPlatformMcp "запрашивает справку платформы 1С via" "MCP / JSON-RPC"
        azimuth.mcpOrchestrator -> azimuth.sentry "отправляет трассировки и ошибки via" "HTTPS / Sentry SDK"
        azimuth.mcpOrchestrator -> its "ищет справочные материалы (Р6, ADR 0006) via" "HTTPS"
        azimuth.mcpOrchestrator -> claudeLLM "арбитрирует через LLM-судью via" "HTTPS / Anthropic API"
        azimuth.azimuthCore -> azimuth.qdrant "читает и сохраняет векторы via" "HTTP / gRPC"
        azimuth.llmAdapter -> deepSeekLLM "генерирует текст via" "HTTPS / OpenAI-compatible API"
        onecPlatform -> azimuth.azimuthCore "передаёт BSL-код и метаданные via" "DumpConfigToFiles / File system"

        # ── Связи: компоненты Азимут-ядра ────────────────────────────────────────
        azimuth.azimuthCore.chunker -> azimuth.azimuthCore.graph "передаёт чанки с контекстом via" "in-process"
        azimuth.azimuthCore.graph -> azimuth.azimuthCore.embedder "передаёт обогащённые чанки via" "in-process"
        azimuth.azimuthCore.embedder -> azimuth.qdrant "сохраняет векторы via" "HTTP / Qdrant API"
        azimuth.azimuthCore.reranker -> azimuth.mcpOrchestrator "возвращает реранкированные результаты via" "in-process"

        # ── Связи: компоненты MCP-оркестратора ───────────────────────────────────
        azimuth.mcpOrchestrator.serverControlledRetrieval -> azimuth.mcpOrchestrator.routeDispatcher "управляет ретривингом via" "in-process"
        azimuth.mcpOrchestrator.routeDispatcher -> azimuth.azimuthCore "маршрутизирует поиск (graph → metadata → grep) via" "Python API"
        azimuth.mcpOrchestrator.sourceHierarchy -> azimuth.mcpOrchestrator.contradictionMetric "передаёт результаты на проверку via" "in-process"
        azimuth.mcpOrchestrator.llmJudge -> azimuth.mcpOrchestrator.serverControlledRetrieval "сигнализирует о необходимости добора via" "in-process"
        azimuth.mcpOrchestrator.llmJudge -> claudeLLM "арбитрирует качество ответа via" "HTTPS / Anthropic API"
        azimuth.mcpOrchestrator.fallbackMode -> azimuth.llmAdapter "инициирует дип-ресёрч via" "Python API"
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
        }
    }

}
