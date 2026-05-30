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
        its = softwareSystem "ИТС / Портал платформы" "Справочные материалы 1С; третий уровень иерархии источников (Р6, ADR 0006)." {
            tags "External"
        }

        # ── Облачные LLM (группа) ───────────────────────────────────────────────
        group "Облачные LLM (ADR 0021)" {
            deepSeekLLM = softwareSystem "DeepSeek" "Облачная разговорная модель (дефолт): DeepSeek V4 Flash / Pro; ADR 0021." {
                tags "External"
            }
            claudeLLM = softwareSystem "Claude (Anthropic)" "Облачная LLM для LLM-судьи и Сергея-премиум; Anthropic API; ADR 0021." {
                tags "External"
            }
        }

        # ── MCP-клиенты по ролям (группа, ADR 0019) ─────────────────────────────
        group "MCP-клиенты по ролям (ADR 0019)" {
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
        }

        # ── Внешний MCP-сервер платформы 1С (ADR 0017) ───────────────────────────
        bslPlatformMcp = softwareSystem "mcp-bsl-platform-context" "Drop-in MCP-сервер: справочник платформы 1С (MIT, alkoleft; ADR 0017)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/foundation/0017-mcp-bsl-platform-context-included.md"
            }
        }

        # ── Внешний кросс-энкодер реранкер (HTTP, опциональный) ─────────────────
        rerankerService = softwareSystem "Cross-Encoder Reranker" "Внешний HTTP-сервис для реранкинга результатов: BGE-reranker локально или Cohere Rerank. Опциональный — включается через RERANKER_URL. Вызывается из Поискового движка (ADR 0002)." {
            tags "External"
            properties {
                "adr-link" "docs/architecture/adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md"
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

            # ═══════════════════════════════════════════════════════════════════
            # Группа: НАШ КОД (поверх форка, граница ADR 0022)
            # ═══════════════════════════════════════════════════════════════════
            group "Наш код (поверх форка, ADR 0022)" {

                # ── MCP-сервер ─────────────────────────────────────────────────
                mcpServer = container "MCP-сервер" "Точка входа FastMCP: выставляет MCP-инструменты для клиентов, инициализирует сервисы, оркестрирует ретривинг. Граница наш код vs форк (ADR 0022). Код: src/main.py, src/config.py." "Python / FastMCP" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md"
                        "open-issues" "docs/architecture/adr/open/0028-sentry-vs-agpl.md"
                    }

                    fastmcpApp = component "FastMCP App" "MCP-инструменты (search_function, codesearch, helpsearch, code_grep, metadatasearch, get_object_details, get_function_context, get_module_functions, reindex, stats), HTTP-эндпоинты /health, /reindex, init_services и lifespan. Файл: src/main.py." "Python / FastMCP" {
                    }

                    appConfig = component "Config" "Конфигурация из env: пути, провайдеры эмбеддингов (openai/openrouter/ollama/cohere/jina), модели, порты, режимы индексации (fast/full). Файл: src/config.py." "Python / dataclass" {
                    }
                }

                # ── Anti-Hallucination Pipeline ────────────────────────────────
                antiHall = container "Anti-Hallucination Pipeline" "Гарантии качества ответа: контроль ретривинга, иерархия источников, LLM-судья, повторные проходы, фолбэк. Планируется как src/quality/. Граница ADR 0022 (наш код)." "Python (планируется)" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0022-boundary-fork-vs-own-code.md"
                    }

                    serverControlledRetrieval = component "Server-Controlled Retrieval" "Контроль ретривинга на стороне сервера: планка релевантности, триггер добора, потолок окна контекста (Р5, ADR 0005)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0005-р5-server-controlled-retrieval.md"
                        }
                    }

                    sourceHierarchy = component "Source Hierarchy" "Иерархия источников при конфликте: код → справка → ИТС (Р6, ADR 0006)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0006-р6-source-hierarchy.md"
                        }
                    }

                    contradictionMetric = component "Contradiction Metric" "Метрика противоречивости источников ПЕРЕД выдачей ответа. Механика детектирования открыта (Р1, ADR 0001; см. ADR 0033)." "Python" {
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

                    groundednessDetector = component "Groundedness Detector" "Три уровня реакции на сигнал LLM-судьи: блок-и-возврат / плашка «частично из общих знаний» / лог в Sentry (П1, ADR 0008)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md"
                            "open-issues" "docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md"
                        }
                    }

                    reRetrievalController = component "Re-Retrieval Controller" "Второй проход ретривера по переформулированному запросу. Гейт N повторов на запрос (П2, ADR 0009)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md"
                            "open-issues" "docs/architecture/adr/anti-hallucinations/0009-п2-re-retrieval.md"
                        }
                    }

                    fallbackMode = component "Fallback Mode" "Фолбэк = смена режима (дип-ресёрч с тем же контрактом); заменил «честный тупик» Р4 (Р7, ADR 0007)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0007-р7-fallback-mode-switch.md"
                        }
                    }

                    querySufficiencyGate = component "Query Sufficiency Gate" "Гейт «слишком общий запрос», подсказки агенту, проверка дрейфа переформулировки (П3, ADR 0010)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md"
                            "open-issues" "docs/architecture/adr/anti-hallucinations/0010-п3-query-sufficiency.md"
                        }
                    }
                }

                # ── Adapter-слой LLM ───────────────────────────────────────────
                llmAdapter = container "Adapter-слой LLM" "Абстракция над разговорной облачной LLM; дефолт — DeepSeek V4; запас — Claude/Qwen/Yandex. Планируется как src/adapters/llm/ (ADR 0020, 0021)." "Python (планируется)" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md"
                        "open-issues" "docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md"
                    }

                    conversationalAdapter = component "Conversational LLM Adapter" "Унифицированный интерфейс к провайдерам разговорной LLM: DeepSeek (дефолт), Claude (премиум), Qwen/Yandex (запас). Маршрутизирует запросы по роли (ADR 0021)." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/foundation/0021-default-model-deepseek-v4.md"
                        }
                    }
                }
            }

            # ═══════════════════════════════════════════════════════════════════
            # Группа: ФОРК bsl-atlas (движок понимания кода, ADR 0013)
            # ═══════════════════════════════════════════════════════════════════
            group "Форк bsl-atlas (движок понимания кода, ADR 0013)" {

                # ── Парсеры ────────────────────────────────────────────────────
                parsers = container "Парсеры" "Парсеры исходников 1С: BSL-код, XML метаданных, текстовый дамп, HTML-справка. Извлекают функции, параметры, вызовы, объекты, реквизиты. Код: src/parsers/." "Python / tree-sitter" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    }

                    bslCodeParser = component "BSL Code Parser" "Парсер BSL: основной API над tree-sitter (точный AST) с regex fallback. Извлекает процедуры/функции, параметры, тело, флаг Экспорт, вызовы. Модель — BSLFunction. Файл: src/parsers/code.py." "Python" {
                    }

                    treeSitterParser = component "Tree-sitter Parser" "Загрузка нативной библиотеки tree-sitter-bsl (/app/lib/bsl.so), инициализация языка и парсера. Используется BSL Code Parser. Файл: src/parsers/tree_sitter_parser.py." "Python / ctypes / tree-sitter" {
                    }

                    metadataXMLParser = component "Metadata XML Parser" "Парсер XML-выгрузки конфигуратора 1С (DumpConfigToFiles): MetaDataObject → Catalog/Document/... → Properties/ChildObjects → Attribute/TabularSection. Файл: src/parsers/metadata_xml.py." "Python / xml.etree" {
                    }

                    metadataTextParser = component "Metadata Text Parser" "Парсер текстовых дампов метаданных 1С (legacy, портирован из comol/1c_code_metadata_mcp). Используется как fallback. Файл: src/parsers/metadata.py." "Python" {
                    }

                    helpParser = component "Help Parser" "Парсер HTML-справки 1С: BeautifulSoup → markdownify → markdown для индексации. Файл: src/parsers/help.py." "Python / BeautifulSoup" {
                    }
                }

                # ── Индексатор ─────────────────────────────────────────────────
                indexer = container "Индексатор" "Инкрементальная индексация в векторное хранилище: чанкинг по образцу ADR 0024, эмбеддинг через провайдеров, инкремент по хешу через file_tracker (ADR 0027). Код: src/indexer/." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md"
                    }

                    vectorIndexer = component "Vector Indexer" "Главный класс индексации: parallel collection чанков, batch-индексация в ChromaDB, function-level хеш для skip unchanged, smart chunking (≤2000 байт — один чанк). Файл: src/indexer/vector_indexer.py (ADR 0024)." "Python / ChromaDB / LangChain TextSplitter" {
                        properties {
                            "adr-link" "docs/architecture/adr/code-processing/0024-code-chunking-deterministic-structural.md"
                        }
                    }

                    embeddingProviders = component "Embedding Providers" "Провайдеры эмбеддингов: OpenAI / OpenRouter / Ollama / Cohere / Jina + локальный fallback. Авто-маппинг имён моделей между провайдерами. Концептуально относится к Adapter-слою LLM (ADR 0020). Файл: src/indexer/embeddings.py." "Python" {
                        properties {
                            "adr-link" "docs/architecture/adr/foundation/0020-cloud-llm-via-adapter.md"
                        }
                    }

                    fileTracker = component "File Tracker" "Отслеживание изменений файлов через SHA-256 хеши: file-level и function-level. Хранит state в отдельной SQLite БД (file_tracker.db). Поддерживает status: new/modified/unchanged/deleted (ADR 0027). Файл: src/indexer/file_tracker.py." "Python / SQLite" {
                        properties {
                            "adr-link" "docs/architecture/adr/code-processing/0027-port-feenlace-techniques-to-python.md"
                        }
                    }
                }

                # ── Поисковый движок ───────────────────────────────────────────
                searchEngine = container "Поисковый движок" "Поиск по индексу: гибридный (vector + fulltext) для семантики, code_grep с AST-контекстом для текстовых паттернов. Маршрутизация: graph → metadata → grep (ADR 0026). Код: src/search/." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/code-processing/0026-code-search-routing.md"
                    }

                    hybridSearch = component "Hybrid Search" "Гибридный поиск по коллекциям ChromaDB (code, metadata, help): fulltext для single-word, vector для multi-word. Трансформация запросов (Справочник→Справочники). Вызывает внешний реранкер по HTTP (ADR 0002). Файл: src/search/hybrid.py." "Python / ChromaDB" {
                        properties {
                            "adr-link" "docs/architecture/adr/anti-hallucinations/0002-р2-faithfulness-vs-relevance.md"
                        }
                    }

                    codeGrep = component "Code Grep" "Поиск текстового паттерна в BSL-коде с AST-контекстом: для каждого совпадения определяет функцию-владельца. Использует FTS5 в SQLite (mgновенно) с fallback на сканирование файлов. Файл: src/search/code_grep.py." "Python / FTS5" {
                    }
                }

                # ── Хранилище ──────────────────────────────────────────────────
                storage = container "Хранилище" "Data Access Layer над SQLite: схема, FTS5, операции по BSL-символам, графу вызовов, объектам метаданных 1С. Код: src/storage/." "Python" {
                    properties {
                        "adr-link" "docs/architecture/adr/foundation/0013-fork-role-code-engine.md"
                    }

                    sqliteStore = component "SQLite Store" "Основной класс DAL: schema DDL, индексация BSL-файлов в symbols/calls/code_fts, индексация объектов метаданных в objects/attributes/tab_parts/register_movements, find_function/get_module_functions/get_function_context, search_metadata, code_grep по FTS5. Файл: src/storage/sqlite_store.py." "Python / SQLite / FTS5" {
                    }

                    dataModels = component "Data Models" "Модели данных (dataclasses): BSLFunction, FunctionInfo, FunctionContext, MetadataObject, ObjectDetails, Attribute, TabPart, IndexStats, ReferenceInfo. Общий контракт между парсерами и DAL. Файл: src/storage/models.py." "Python / dataclasses" {
                    }
                }
            }

            # ── Data stores (внешние с точки зрения процесса) ──────────────────
            sqlite = container "SQLite" "Структурный индекс: таблицы files, symbols, calls, objects, attributes, tab_parts, register_movements; FTS5 для code_fts, symbols_fts, objects_fts. БД: /data/bsl_index.db." "SQLite / FTS5" {
                tags "Database"
            }

            fileTrackerDb = container "File Tracker DB" "Отдельная SQLite БД для file_tracker (SHA-256 хеши, статусы индексации, function-level хеши). БД: /data/chroma_db/file_tracker.db." "SQLite" {
                tags "Database"
            }

            vectorStore = container "Векторное хранилище" "Коллекции code, metadata, help с эмбеддингами чанков. Текущая реализация — ChromaDB embedded. Целевая замена — Qdrant embedded / server (ADR 0029)." "ChromaDB" {
                tags "Database"
                properties {
                    "adr-link" "docs/architecture/adr/open/0029-multitenancy-qdrant-embedded-vs-server.md"
                }
            }
        }

        # ═══════════════════════════════════════════════════════════════════════
        # СВЯЗИ
        # ═══════════════════════════════════════════════════════════════════════

        # ── Пользователи → внешние клиенты ──────────────────────────────────────
        serg -> cherryStudio "использует everyday" "Desktop GUI"
        serg -> claudeDesktop "использует для сложного кода" "Desktop GUI"
        serg -> miniAi1c "захватывает код из Конфигуратора" "Desktop GUI"
        mama -> cherryStudio "задаёт вопросы по 1С" "Desktop GUI"

        # ── Внешние клиенты → MCP-сервер ───────────────────────────────────────
        cherryStudio -> azimuth.mcpServer "вызывает инструменты" "MCP / JSON-RPC"
        claudeDesktop -> azimuth.mcpServer "вызывает инструменты" "MCP / JSON-RPC"
        miniAi1c -> azimuth.mcpServer "вызывает инструменты" "MCP / JSON-RPC"

        # ── Платформа 1С → парсеры (исходники) ─────────────────────────────────
        onecPlatform -> azimuth.parsers "BSL-код, XML конфигурации, HTML справка" "DumpConfigToFiles / File system"
        onecPlatform -> azimuth.parsers.bslCodeParser "*.bsl файлы" "File system"
        onecPlatform -> azimuth.parsers.metadataXMLParser "XML конфигурации (Catalog/Document/...)" "File system"
        onecPlatform -> azimuth.parsers.metadataTextParser "*.txt дампы метаданных (legacy)" "File system"
        onecPlatform -> azimuth.parsers.helpParser "HTML-справка" "File system"

        # ── MCP-сервер → нижележащие контейнеры (Container-level) ──────────────
        azimuth.mcpServer -> azimuth.parsers "запрашивает парсинг" "Python API"
        azimuth.mcpServer -> azimuth.indexer "триггерит индексацию (reindex, /reindex)" "Python API"
        azimuth.mcpServer -> azimuth.searchEngine "семантический поиск + code_grep" "Python API"
        azimuth.mcpServer -> azimuth.storage "структурные запросы (символы, граф, метаданные)" "Python API"
        azimuth.mcpServer -> azimuth.antiHall "контроль качества ответа" "Python API"
        azimuth.mcpServer -> azimuth.llmAdapter "генерация ответа и фолбэк" "Python API"

        # ── Индексатор → нижележащие ───────────────────────────────────────────
        azimuth.indexer -> azimuth.parsers "парсит BSL/XML/help" "Python API"
        azimuth.indexer -> azimuth.vectorStore "пишет векторы и метаданные" "ChromaDB API"
        azimuth.indexer -> azimuth.fileTrackerDb "пишет хеши, статусы" "SQLite API"

        # ── Поисковый движок → нижележащие ─────────────────────────────────────
        azimuth.searchEngine -> azimuth.vectorStore "семантические запросы" "ChromaDB API"
        azimuth.searchEngine -> azimuth.storage "FTS5 и структурный поиск" "Python API"
        azimuth.searchEngine -> rerankerService "реранкинг (опц.)" "HTTPS / JSON"

        # ── Хранилище → SQLite ─────────────────────────────────────────────────
        azimuth.storage -> azimuth.sqlite "DDL, INSERT, SELECT (symbols, calls, objects, FTS5)" "SQLite API"
        azimuth.storage -> azimuth.parsers "парсит BSL при rebuild()" "Python API"

        # ── Anti-Hallucination Pipeline → внешние ──────────────────────────────
        azimuth.antiHall -> azimuth.llmAdapter "вызов разговорной LLM" "Python API"
        azimuth.antiHall -> sentry "лог уровней П1" "HTTPS / Sentry SDK"

        # ── Adapter-слой LLM → внешние LLM ─────────────────────────────────────
        azimuth.llmAdapter -> deepSeekLLM "генерирует текст" "HTTPS / OpenAI-compatible API"
        azimuth.llmAdapter -> claudeLLM "генерация / арбитраж" "HTTPS / Anthropic API"

        # ── MCP-сервер → внешние сервисы ───────────────────────────────────────
        azimuth.mcpServer -> bslPlatformMcp "справка платформы 1С" "MCP / JSON-RPC"
        azimuth.mcpServer -> sentry "трассировки и ошибки" "HTTPS / Sentry SDK"
        azimuth.mcpServer -> its "справочные материалы (Р6, ADR 0006)" "HTTPS"

        # ═══════════════════════════════════════════════════════════════════════
        # Component-level связи
        # ═══════════════════════════════════════════════════════════════════════

        # ── MCP-сервер компоненты ──────────────────────────────────────────────
        azimuth.mcpServer.fastmcpApp -> azimuth.mcpServer.appConfig "читает env-настройки" "in-process"
        azimuth.mcpServer.fastmcpApp -> azimuth.storage.sqliteStore "search_function, get_module_functions, get_function_context, get_object_details, metadatasearch, code_grep" "Python API"
        azimuth.mcpServer.fastmcpApp -> azimuth.indexer.vectorIndexer "init, reindex, /reindex (background)" "Python API"
        azimuth.mcpServer.fastmcpApp -> azimuth.searchEngine.hybridSearch "codesearch, helpsearch, search_code_filtered" "Python API"
        azimuth.mcpServer.fastmcpApp -> azimuth.searchEngine.codeGrep "code_grep (fallback на файлы)" "Python API"
        azimuth.mcpServer.fastmcpApp -> azimuth.parsers.metadataXMLParser "rebuild SQLite — парсит XML" "Python API"

        # ── Парсеры компоненты ─────────────────────────────────────────────────
        azimuth.parsers.bslCodeParser -> azimuth.parsers.treeSitterParser "точный AST с regex fallback" "in-process"
        azimuth.parsers.bslCodeParser -> azimuth.storage.dataModels "BSLFunction" "in-process"
        azimuth.parsers.metadataXMLParser -> azimuth.storage.dataModels "MetadataObject, Attribute, TabPart" "in-process"

        # ── Индексатор компоненты ──────────────────────────────────────────────
        azimuth.indexer.vectorIndexer -> azimuth.indexer.embeddingProviders "векторизация чанков" "in-process"
        azimuth.indexer.vectorIndexer -> azimuth.indexer.fileTracker "статус файлов / функций, mark_indexed" "in-process"
        azimuth.indexer.vectorIndexer -> azimuth.parsers.bslCodeParser "parse_file_functions" "Python API"
        azimuth.indexer.vectorIndexer -> azimuth.parsers.metadataTextParser "parse_file (метаданные)" "Python API"
        azimuth.indexer.vectorIndexer -> azimuth.parsers.helpParser "parse_file (HTML help)" "Python API"
        azimuth.indexer.vectorIndexer -> azimuth.vectorStore "collection.add (batch)" "ChromaDB API"
        azimuth.indexer.fileTracker -> azimuth.fileTrackerDb "файлы и function-hashes" "SQLite API"

        # ── Поисковый движок компоненты ────────────────────────────────────────
        azimuth.searchEngine.hybridSearch -> azimuth.vectorStore "collection.query" "ChromaDB API"
        azimuth.searchEngine.hybridSearch -> rerankerService "POST /rerank (опц.)" "HTTPS / JSON"
        azimuth.searchEngine.codeGrep -> azimuth.storage.sqliteStore "code_grep по FTS5" "Python API"

        # ── Хранилище компоненты ───────────────────────────────────────────────
        azimuth.storage.sqliteStore -> azimuth.sqlite "DDL, INSERT, SELECT" "SQLite API"
        azimuth.storage.sqliteStore -> azimuth.parsers.bslCodeParser "parse_file_functions при rebuild" "Python API"
        azimuth.storage.sqliteStore -> azimuth.storage.dataModels "BSLFunction, FunctionInfo, MetadataInfo" "in-process"

        # ── Anti-Hallucination Pipeline компоненты ─────────────────────────────
        azimuth.antiHall.querySufficiencyGate -> azimuth.antiHall.serverControlledRetrieval "пропускает осмысленные запросы" "in-process"
        azimuth.antiHall.serverControlledRetrieval -> azimuth.searchEngine "управляет ретривингом (планка, добор, потолок)" "Python API"
        azimuth.antiHall.sourceHierarchy -> azimuth.antiHall.contradictionMetric "передаёт ранжированные источники" "in-process"
        azimuth.antiHall.contradictionMetric -> azimuth.antiHall.llmJudge "спорные случаи арбитру" "in-process"
        azimuth.antiHall.llmJudge -> claudeLLM "арбитраж качества" "HTTPS / Anthropic API"
        azimuth.antiHall.llmJudge -> azimuth.antiHall.groundednessDetector "сигнал недогрунтованности" "in-process"
        azimuth.antiHall.groundednessDetector -> azimuth.antiHall.reRetrievalController "уровень 1: триггер повтора" "in-process"
        azimuth.antiHall.groundednessDetector -> sentry "уровни 2/3: лог" "HTTPS / Sentry SDK"
        azimuth.antiHall.reRetrievalController -> azimuth.antiHall.serverControlledRetrieval "повтор в рамках бюджета" "in-process"
        azimuth.antiHall.reRetrievalController -> azimuth.antiHall.fallbackMode "после N повторов (Р7)" "in-process"
        azimuth.antiHall.fallbackMode -> azimuth.llmAdapter.conversationalAdapter "дип-ресёрч (фолбэк, ADR 0007)" "Python API"

        # ── Adapter-слой LLM компонент ─────────────────────────────────────────
        azimuth.llmAdapter.conversationalAdapter -> deepSeekLLM "дефолт" "HTTPS / OpenAI-compatible API"
        azimuth.llmAdapter.conversationalAdapter -> claudeLLM "премиум / арбитраж" "HTTPS / Anthropic API"
    }

    views {
        systemContext azimuth "systemContext" "Кто взаимодействует с системой и как. C4 Level 1." {
            include *
            include serg mama
            # Cross-Encoder Reranker — техническая деталь поиска, показывается в C2 (container view)
            exclude rerankerService
            autolayout lr
        }

        container azimuth "container" "Контейнеры системы (логические подсистемы + БД). C4 Level 2." {
            include *
            include serg mama
            autolayout lr
        }

        component azimuth.parsers "componentParsers" "Парсеры: модули src/parsers/. C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.indexer "componentIndexer" "Индексатор: модули src/indexer/. C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.searchEngine "componentSearchEngine" "Поисковый движок: модули src/search/. C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.storage "componentStorage" "Хранилище: модули src/storage/. C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.mcpServer "componentMcpServer" "MCP-сервер: модули src/main.py, src/config.py. C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.antiHall "componentAntiHall" "Anti-Hallucination Pipeline: компоненты по ADR (планируется). C4 Level 3." {
            include *
            autolayout lr
        }

        component azimuth.llmAdapter "componentLlmAdapter" "Adapter-слой LLM: компоненты (планируется). C4 Level 3." {
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
            # ── Proposed: визуально отличимы (проставляется sync_arch_metadata.py) ──
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
