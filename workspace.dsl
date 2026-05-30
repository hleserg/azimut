workspace "Азимут" "ИИ-ассистент по коду 1С на базе форка bsl-atlas (ADR 0034)" {
    # Запуск: docker compose --profile diagrams up -d structurizr-proxy   (см. docker-compose.yml, HLE-537)

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
        deepSeekLLM = softwareSystem "DeepSeek" "Облачная разговорная модель (дефолт): DeepSeek V4 Flash / Pro; ADR 0021." {
            tags "External"
        }
        claudeLLM = softwareSystem "Claude (Anthropic)" "Облачная LLM для LLM-судьи и Сергея-премиум; Anthropic API; ADR 0021." {
            tags "External"
        }
        its = softwareSystem "ИТС / Портал платформы" "Справочные материалы 1С; третий уровень иерархии источников (Р6, ADR 0006)." {
            tags "External"
        }

        # ── Внешние MCP-клиенты (ADR 0019) ──────────────────────────────────────
        cherryStudio = softwareSystem "Cherry Studio" "MCP-клиент по умолчанию для Мамы и Сергея-everyday (ADR 0019)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
            }
        }
        claudeDesktop = softwareSystem "Claude Desktop" "MCP-клиент для Сергея-премиум дома (ADR 0019)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
            }
        }
        miniAi1c = softwareSystem "mini-ai-1c" "Клиент Сергея для захвата BSL-кода из Конфигуратора 1С (ADR 0019)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0019-cherry-studio-default-client.md"
            }
        }

        # ── Внешний MCP-сервер платформы 1С (ADR 0017) ───────────────────────────
        bslPlatformMcp = softwareSystem "mcp-bsl-platform-context" "Drop-in MCP-сервер: справочник платформы 1С (MIT, alkoleft; ADR 0017)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md"
            }
        }

        # ── Мониторинг (ADR 0028 open) ───────────────────────────────────────────
        sentry = softwareSystem "Sentry / GlitchTip" "Мониторинг ошибок и трассировка. Выбор между Sentry SaaS и self-hosted GlitchTip открыт (ADR 0028)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
            }
        }

        # ── Основная система ────────────────────────────────────────────────────
        azimuth = softwareSystem "Азимут" "MCP-сервер + ядро понимания кода 1С: RAG, анти-галлюцинации, граф вызовов. Форк bsl-atlas (AGPL-3.0, ADR 0011)." {
            properties {
                "adr-link" "docs/architecture/adr/foundation/0011-fork-bsl-atlas-as-core.md"
            }

            !docs docs/architecture
            !adrs docs/architecture/adr/anti-hallucinations madr
            !adrs docs/architecture/adr/foundation madr
            !adrs docs/architecture/adr/code-processing madr
            !adrs docs/architecture/adr/open madr
            !adrs docs/architecture/adr/tooling madr

            # ── MCP-оркестратор (наш код поверх форка, ADR 0022) ────────────────
            orch = container "MCP-оркестратор" "Принимает MCP-запросы клиентов; выставляет инструменты; оркестрирует ретривинг и анти-галлюцинации. Граница наш код vs форк (ADR 0022). Код: src/main.py." "Python / FastMCP" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md"
                    "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                }

                toolLayer = component "MCP Tools" "MCP-инструменты для клиентов: search_function, codesearch, helpsearch, code_grep, metadatasearch, get_object_details, reindex, stats. Точка входа. Код: src/main.py." "Python / FastMCP" {
                }

                serverControlledRetrieval = component "Server-Controlled Retrieval" "Контроль ретривинга на стороне сервера: планка релевантности, триггер добора, потолок окна контекста (Р5, ADR 0005)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md"
                    }
                }

                sourceArbiter = component "Source Arbiter" "Иерархия источников (код → справка → ИТС) + метрика противоречивости ПЕРЕД выдачей ответа. Объединяет Р6 + Р1 (ADR 0006, 0001)." "Python" {
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

                groundednessDetector = component "Groundedness Detector" "Три уровня реакции на сигнал LLM-судьи: блок-и-возврат / плашка «частично из общих знаний» / лог в Sentry (П1, ADR 0008)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md"
                        "open-issues" "docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md"
                    }
                }

                recoveryPipeline = component "Recovery Pipeline" "Повторный проход ретривера по переформулированному запросу + переключение в дип-ресёрч после N исчерпанных повторов (П2+Р7, ADR 0009, 0007)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md"
                        "open-issues" "docs/architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md"
                    }
                }

                querySufficiency = component "Query Sufficiency Gate" "Гейт «слишком общий запрос», подсказки агенту на основе индекса, проверка дрейфа переформулировки (П3, ADR 0010)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md"
                        "open-issues" "docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md"
                    }
                }
            }

            # ── Азимут-ядро (форк bsl-atlas, движок понимания кода) ──────────────
            core = container "Азимут-ядро" "Форк bsl-atlas: парсеры BSL и метаданных, чанкер, граф вызовов, индексатор, поисковый движок. Роль — «движок понимания кода» (ADR 0013). Код: src/." "Python / bsl-atlas fork" {
                properties {
                    "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    "open-issues" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                }

                parsers = component "Парсеры" "BSL-парсер (tree-sitter AST + regex fallback), парсер метаданных XML (DumpConfigToFiles), парсер справки. Извлекают функции, вызовы, объекты, реквизиты. Код: src/parsers/." "Python / tree-sitter" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    }
                }

                chunker = component "Чанкер" "Детерминированная структурная резка: функция = чанк (≤ порога); блоки Если/Цикл/Попытка/Область с шапкой контекста; запросы по |;. LLM не используется. Код: src/indexer/vector_indexer.py (ADR 0024)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md"
                    }
                }

                callGraph = component "Граф вызовов" "Построение BSL-графа: типизация процедур/функций, рёбра caller→callee, get_function_context (calls + called_by). Таблицы symbols/calls. Код: src/storage/sqlite_store.py." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    }
                }

                resolver = component "Same-Named Resolver" "Резолв одноимённых процедур: routines + calls(callee_id NULL) → пост-проход. Алгоритм не написан — главный технический риск темы 2 (ADR 0025)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                        "open-issues" "docs/architecture/adr/code-processing/0025-resolve-same-named-procedures.md"
                    }
                }

                indexer = component "Индексатор" "Инкрементальная индексация + эмбеддинг: manifest-diff {path: mtime+size}, SHA-256 кеш, file_tracker, шардирование. Провайдеры эмбеддингов: OpenRouter / Ollama / Cohere / Jina. Код: src/indexer/ (ADR 0027, 0020)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md"
                    }
                }

                searchEngine = component "Поисковый движок" "Гибридный поиск: семантический (векторное хранилище) + структурный (SQLite FTS5) + code_grep с AST-контекстом + кросс-энкодер реранкер. Маршрутизация: graph → metadata → grep (ADR 0026, 0002). Код: src/search/." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0026-code-search-routing.md"
                    }
                }

                bslSynonyms = component "BSL Synonyms RU↔EN" "Нормализация BSL-синонимов: СтрНайти↔StrFind, ~40 ключевых слов + ~180 функций. Подключается к поисковому движку и индексатору (ADR 0027)." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md"
                    }
                }
            }

            # ── SQLite (структурный индекс) ─────────────────────────────────────
            sqlite = container "SQLite" "Структурный индекс: таблицы files, symbols, calls, objects, attributes, tab_parts, register_movements; FTS5 полнотекстовый поиск по коду (code_fts) и метаданным (objects_fts, symbols_fts). Код: src/storage/sqlite_store.py." "SQLite / FTS5" {
                tags "Database"
            }

            # ── Векторное хранилище ──────────────────────────────────────────────
            vectorStore = container "Векторное хранилище" "Коллекции code, metadata, help с эмбеддингами чанков. Текущая реализация — ChromaDB (embedded). Целевая замена — Qdrant embedded / server (ADR 0029)." "ChromaDB" {
                tags "Database"
                properties {
                    "adr-link" "docs/architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md"
                }
            }

            # ── Adapter-слой LLM ────────────────────────────────────────────────
            llmAdapter = container "Adapter-слой LLM" "Абстракция над разговорной облачной LLM; дефолт — DeepSeek V4; запас — Claude/Qwen/Yandex. Валидация eval-ом в теме 6 (ADR 0020, 0021)." "Python" {
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
        cherryStudio -> azimuth.orch "вызывает инструменты" "MCP / JSON-RPC"
        claudeDesktop -> azimuth.orch "вызывает инструменты" "MCP / JSON-RPC"
        miniAi1c -> azimuth.orch "вызывает инструменты" "MCP / JSON-RPC"

        # ── Связи: контейнеры (Container-level) ─────────────────────────────────
        azimuth.orch -> azimuth.core "парсинг, поиск, индексация" "Python API (in-process)"
        azimuth.orch -> azimuth.sqlite "структурные запросы (символы, граф, метаданные)" "SQLite API"
        azimuth.orch -> azimuth.llmAdapter "генерация ответа и фолбэк" "Python API"
        azimuth.core -> azimuth.sqlite "запись символов, вызовов, объектов метаданных" "SQLite API"
        azimuth.core -> azimuth.vectorStore "запись и чтение векторов" "ChromaDB API"
        azimuth.llmAdapter -> deepSeekLLM "генерирует текст" "HTTPS / OpenAI-compatible API"
        azimuth.llmAdapter -> claudeLLM "генерация в премиум-режиме" "HTTPS / Anthropic API"
        onecPlatform -> azimuth.core "передаёт BSL-код и метаданные" "DumpConfigToFiles / File system"

        # ── Связи: система → внешние сервисы ────────────────────────────────────
        azimuth.orch -> bslPlatformMcp "справка платформы 1С" "MCP / JSON-RPC"
        azimuth.orch -> sentry "трассировки и ошибки" "HTTPS / Sentry SDK"
        azimuth.orch -> its "справочные материалы (Р6, ADR 0006)" "HTTPS"

        # ── Связи: компоненты Азимут-ядра ────────────────────────────────────────
        onecPlatform -> azimuth.core.parsers "BSL-код и метаданные" "DumpConfigToFiles / File system"
        azimuth.core.parsers -> azimuth.core.chunker "AST функций и метаданных" "in-process"
        azimuth.core.parsers -> azimuth.core.callGraph "вызовы функций" "in-process"
        azimuth.core.chunker -> azimuth.core.indexer "чанки на индексацию" "in-process"
        azimuth.core.callGraph -> azimuth.core.resolver "неразрешённые вызовы (callee_id NULL)" "in-process"
        azimuth.core.callGraph -> azimuth.sqlite "символы и вызовы" "SQLite API"
        azimuth.core.indexer -> azimuth.vectorStore "векторы чанков" "ChromaDB API"
        azimuth.core.bslSynonyms -> azimuth.core.searchEngine "нормализация запроса рус↔англ" "in-process"
        azimuth.core.bslSynonyms -> azimuth.core.indexer "нормализация при индексации" "in-process"
        azimuth.core.searchEngine -> azimuth.vectorStore "семантический поиск" "ChromaDB API"
        azimuth.core.searchEngine -> azimuth.sqlite "структурный поиск (FTS5)" "SQLite API"

        # ── Связи: компоненты MCP-оркестратора ───────────────────────────────────
        azimuth.orch.toolLayer -> azimuth.core.searchEngine "делегирует поиск" "Python API"
        azimuth.orch.toolLayer -> azimuth.sqlite "структурные запросы (search_function, get_module_functions, get_object_details)" "SQLite API"
        azimuth.orch.toolLayer -> azimuth.core.indexer "триггерит переиндексацию" "Python API"
        azimuth.orch.querySufficiency -> azimuth.orch.serverControlledRetrieval "пропускает осмысленные запросы" "in-process"
        azimuth.orch.serverControlledRetrieval -> azimuth.core.searchEngine "управляет ретривингом" "Python API"
        azimuth.orch.sourceArbiter -> azimuth.orch.llmJudge "спорные случаи арбитру" "in-process"
        azimuth.orch.llmJudge -> claudeLLM "арбитраж качества" "HTTPS / Anthropic API"
        azimuth.orch.llmJudge -> azimuth.orch.groundednessDetector "сигнал недогрунтованности" "in-process"
        azimuth.orch.groundednessDetector -> azimuth.orch.recoveryPipeline "триггерит повторный проход (уровень 1)" "in-process"
        azimuth.orch.groundednessDetector -> sentry "лог уровней 2/3" "HTTPS / Sentry SDK"
        azimuth.orch.recoveryPipeline -> azimuth.orch.serverControlledRetrieval "повтор в рамках бюджета окна" "in-process"
        azimuth.orch.recoveryPipeline -> azimuth.llmAdapter "дип-ресёрч (фолбэк, ADR 0007)" "Python API"
    }

    views {
        systemContext azimuth "systemContext" "Кто взаимодействует с системой и как. C4 Level 1." {
            include *
            include serg mama
            autolayout lr
        }

        container azimuth "container" "Из чего состоит система как набор контейнеров. C4 Level 2." {
            include *
            include serg mama
            autolayout lr
        }

        component azimuth.core "componentCore" "Компоненты Азимут-ядра (движок понимания кода). C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.orch "componentOrch" "Компоненты MCP-оркестратора. C4 Level 3." {
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
            # ── Proposed: визуально отличимы (ADR 0023, проставляется sync_arch_metadata.py) ──
            element "Proposed" {
                background #E6D5A4
                color #000000
                border dashed
                stroke #B89B5E
            }

            # ── Decisions Graph: окраска узлов ADR по статусу (HLE-541) ──
            element "Decision:accepted" {
                background #5CB85C
                color #ffffff
            }
            element "Decision:proposed" {
                background #E6D5A4
                color #000000
            }
            element "Decision:superseded" {
                background #999999
                color #ffffff
            }
            element "Decision:Accepted" {
                background #5CB85C
                color #ffffff
            }
            element "Decision:Proposed" {
                background #E6D5A4
                color #000000
            }
            element "Decision:Superseded" {
                background #999999
                color #ffffff
            }
        }
    }

}
