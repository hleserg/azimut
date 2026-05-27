workspace "Азимут" "ИИ-ассистент по коду 1С на базе форка bsl-atlas (ADR 0034)" {
    # Запуск: docker run --rm -p 8080:8080 -v .:/usr/local/structurizr --user $(id -u):$(id -g) structurizr/structurizr local

    !identifiers hierarchical

    model {
        # Пользователи
        serg = person "Сергей" "Лид-разработчик; основной пользователь системы на ежедневной основе."
        mama = person "Мама" "Бухгалтер / 1С-оператор; конечный пользователь-нетехник."

        # Внешние системы-источники
        onecPlatform = softwareSystem "Платформа 1С" "Конфигурации ERP/Бухгалтерия; источник BSL-кода и метаданных." {
            tags "External"
        }
        cloudLLM = softwareSystem "Облачная LLM" "DeepSeek V4 / Claude — разговорная модель через адаптер (ADR 0020, 0021)." {
            tags "External"
        }
        its = softwareSystem "ИТС / Портал платформы" "Справочные материалы 1С; третий уровень иерархии источников (ADR 0006)." {
            tags "External"
        }

        # MCP-клиенты (внешние)
        cherryStudio = softwareSystem "Cherry Studio" "MCP-клиент по умолчанию для мамы и Сергея-everyday (ADR 0019)." {
            tags "External"
        }
        claudeDesktop = softwareSystem "Claude Desktop" "MCP-клиент для Сергея-премиум (ADR 0019)." {
            tags "External"
        }
        miniAi1c = softwareSystem "mini-ai-1c" "Клиент для Сергея-захват кода из Конфигуратора (ADR 0019)." {
            tags "External"
        }

        # Основная система
        azimuth = softwareSystem "Азимут" "MCP-сервер + Азимут-ядро: понимание кода 1С, RAG, анти-галлюцинации (форк bsl-atlas, ADR 0011)." {
            properties {
                "adr-link" "docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md"
            }

            mcpOrchestrator = container "MCP-оркестратор" "Принимает MCP-запросы клиента; управляет ретривингом, иерархией источников, LLM-судьёй, фолбэком." "Python / FastMCP" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md"
                    "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                }
            }

            azimuthCore = container "Азимут-ядро" "Форк bsl-atlas: парсер BSL, граф вызовов, чанкер, эмбеддер, реранкер." "Python / bsl-atlas fork" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    "open-issues" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                }

                chunker = component "Чанкер" "Детерминированная структурная резка: функция = чанк; блоки Если/Цикл/Попытка/Область (ADR 0024)." "Python"
                graph = component "Граф вызовов" "Построение графа BSL-вызовов; резолв одноимённых — открытая задача (ADR 0025 proposed)." "Python"
                embedder = component "Эмбеддер" "Векторизация чанков (BGE-M3 локально по умолчанию, Cohere Rerank опционально)." "Python"
                reranker = component "Реранкер" "Реранкинг результатов перед выдачей; ADR 0002 (faithfulness vs relevance)." "Python"
            }

            qdrant = container "Qdrant" "Векторное хранилище чанков и метаданных; embedded (локально) или server (VDS, ADR 0029)." "Qdrant" {
                tags "Database"
            }

            llmJudge = container "LLM-судья" "Арбитр качества ответов (Claude); проверяет faithfulness, groundedness (ADR 0003, 0008)." "Python / Claude API" {
                properties {
                    "adr-link" "docs/architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md"
                }
            }

            llmAdapter = container "Adapter-слой LLM" "Абстракция над разговорной LLM; дефолт — DeepSeek V4 (ADR 0020, 0021)." "Python" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md"
                }
            }

            bslPlatformMcp = container "mcp-bsl-platform-context" "Drop-in MCP-сервер: справочник платформы 1С (MIT, alkoleft, ADR 0017)." "TypeScript / MCP" {
                tags "External"
            }
        }

        # Связи пользователей с клиентами
        serg -> cherryStudio "использует everyday"
        serg -> claudeDesktop "использует для сложного кода"
        serg -> miniAi1c "захватывает код из Конфигуратора"
        mama -> cherryStudio "задаёт вопросы по 1С"

        # Связи клиентов с системой
        cherryStudio -> azimuth.mcpOrchestrator "MCP-запросы" "MCP / JSON-RPC"
        claudeDesktop -> azimuth.mcpOrchestrator "MCP-запросы" "MCP / JSON-RPC"
        miniAi1c -> azimuth.mcpOrchestrator "MCP-запросы" "MCP / JSON-RPC"

        # Связи внутри системы
        azimuth.mcpOrchestrator -> azimuth.azimuthCore "индексация, поиск кода" "Python API"
        azimuth.mcpOrchestrator -> azimuth.qdrant "чтение векторов и метаданных" "HTTP / Qdrant API"
        azimuth.mcpOrchestrator -> azimuth.llmJudge "проверка качества ответа" "Python API"
        azimuth.mcpOrchestrator -> azimuth.llmAdapter "генерация ответа / фолбэк" "HTTPS / JSON"
        azimuth.mcpOrchestrator -> azimuth.bslPlatformMcp "справка платформы 1С" "MCP / JSON-RPC"
        azimuth.azimuthCore.chunker -> azimuth.azimuthCore.graph "чанки с контекстом" "in-process"
        azimuth.azimuthCore.embedder -> azimuth.qdrant "сохранение векторов" "HTTP / Qdrant API"
        azimuth.azimuthCore.reranker -> azimuth.mcpOrchestrator "реранкированные результаты" "in-process"
        azimuth.llmAdapter -> cloudLLM "генерация текста" "HTTPS / JSON"
        azimuth.llmJudge -> cloudLLM "арбитраж (Claude API)" "HTTPS / JSON"
        azimuth.mcpOrchestrator -> its "поиск в справочных материалах (Р6, ADR 0006)" "HTTPS"

        # Источники данных
        onecPlatform -> azimuth.azimuthCore "DumpConfigToFiles → BSL-код и метаданные" "File system"
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
