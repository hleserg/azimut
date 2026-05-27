# Заметки HLE-464: Живые данные 1С — 5 репозиториев

Дата: 2026-05-26

## URL репозиториев
1. 1c_mcp → https://github.com/vladimir-kharin/1c_mcp
2. 1c-mcp-toolkit → https://github.com/ROCTUP/1c-mcp-toolkit
3. 1c-log-checker → https://github.com/SteelMorgan/1c-log-checker
4. spring-mcp-1c-copilot → https://github.com/SteelMorgan/spring-mcp-1c-copilot
5. 1c-ai-sandbox → https://github.com/SteelMorgan/1c-ai-sandbox-client-server

---

## РЕПО 1: SteelMorgan/1c-log-checker

**URL:** https://github.com/SteelMorgan/1c-log-checker  
**Лицензия:** MIT (LICENSE:1 — «Copyright (c) 2025 Акимов Владимир»)  
**Стек:** Go 1.21+, ClickHouse 23.8+, BoltDB, MCP, Grafana  

### Назначение
Читает файлы Журнала регистрации (`.lgf`/`.lgp`) и Технологического журнала (`.log`) с диска Windows-хоста (volume mount → Docker-контейнер), парсит и заливает в ClickHouse, выставляет 8 MCP-инструментов для AI-агента.

### Механизм доступа к данным 1С
**Прямое чтение файлов** — не HTTP/OData/COM.  
- Журнал регистрации: `internal/logreader/eventlog/reader.go:35-60` — `Reader` открывает `.lgf`+`.lgp` файлы через `os.File`, потоковый разбор с отслеживанием смещений (BoltDB).
- Технологический журнал: `internal/logreader/interface.go:25-36` — `TechLogReader` читает `.log` файлы аналогичным образом.
- Файлы хранятся там, где их записывает 1С-сервер; в Docker-Compose они пробрасываются через volume mount (README.md — «Windows host log files → Docker volume mount»).

### Хранилище
ClickHouse, база `logs`, таблица `logs.event_log`.  
Запрос `internal/handlers/event_log.go:150-160`:
```sql
SELECT event_time, level, event_presentation, user_name, comment, metadata_presentation
FROM logs.event_log
WHERE cluster_guid = ? AND infobase_guid = ?
```

### MCP-инструменты (8 штук, `internal/mcp/tools.json`)
| Инструмент | Что делает |
|---|---|
| `logc_get_event_log` | Журнал регистрации из ClickHouse; обязательные: cluster_guid, infobase_guid |
| `logc_get_tech_log` | Технологический журнал из ClickHouse; обязательные: cluster_guid, infobase_guid, from, to |
| `logc_get_actual_log_timestamp` | Актуальная временная метка лога (base_id) |
| `logc_configure_techlog` | Настроить конфигурацию техжурнала |
| `logc_save_techlog` | Сохранить конфигурацию |
| `logc_restore_techlog` | Восстановить конфигурацию |
| `logc_disable_techlog` | Отключить техжурнал |
| `logc_get_techlog_config` | Прочитать конфигурацию техжурнала |

### Идентификация баз
`configs/cluster_map.yaml` — YAML-файл: human-readable имена кластеров/инфобаз + их GUID-ы. MCP-описание явно инструктирует агента сначала прочитать этот файл (`tools.json:5`).

### Уровни событий
`internal/handlers/event_log.go:34-47` — `getLevelVariants()` поддерживает рус. и англ. названия: `"Error"/"Ошибка"`, `"Warning"/"Предупреждение"`, `"Information"/"Информация"`, `"Note"/"Примечание"`.

### Классификация
**Группа A** — живые данные 1С. Читает актуальные файлы журналов с диска, где 1С их пишет. Данные всегда свежие (файлы растут в реальном времени, смещения BoltDB). Тема 7 — доступ к runtime-данным через файлы логов.

---

## РЕПО 2: vladimir-kharin/1c_mcp

**URL:** https://github.com/vladimir-kharin/1c_mcp  
**Лицензия:** MIT (README.md — «MIT License»)  
**Стек:** BSL (1С-расширение), Python 3, httpx, MCP SDK  

### Назначение
Фреймворк для разработки MCP-серверов прямо внутри 1С. Расширение устанавливается в живую базу и выставляет HTTP-сервис; Python-прокси — опциональный мост для stdio-транспорта и OAuth2.

### Архитектура
```
AI-клиент ←→ Python-прокси (опц.) ←→ HTTP-сервис mcp_APIBackend (1С) ←→ Обработки-контейнеры
```

### Механизм доступа к данным 1С
**1С HTTP-сервис** — расширение регистрируется как HTTP-сервис `mcp_APIBackend` и принимает JSON-RPC запросы на `/hs/mcp/rpc`.  
- Python → 1С: `httpx.BasicAuth` + POST `{base_url}/hs/mcp/rpc` с JSON-RPC телом (`src/py_server/onec_client.py:35,100-116`).
- Маршрутизация в 1С: `HTTPServices/mcp_APIBackend/Ext/Module.bsl:82-96` — методы `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`.
- BSL-код работает внутри 1С-сервера и имеет прямой доступ к глобальному объекту `Метаданные`.

### Встроенные инструменты (`mcp_ИнструментДанныеОКонфигурации`)
| Инструмент | Данные |
|---|---|
| `list_metadata_objects` | `Метаданные[metaType]` — список объектов конфигурации (Справочники, Документы, Регистры и т.д.); параметр `nameMask` — фильтр по подстроке в имени/синониме (`ManagerModule.bsl:78`) |
| `get_metadata_structure` | `КоллекцияМД.Найти(name)` — реквизиты, ТЧ, измерения, ресурсы конкретного объекта (`ManagerModule.bsl:156-178`) |

Поддерживаемые типы метаданных: `Catalogs, Documents, InformationRegisters, AccumulationRegisters, AccountingRegisters, CalculationRegisters, ChartsOfCharacteristicTypes, ChartsOfAccounts, BusinessProcesses, Tasks, ExchangePlans, Reports, DataProcessors, Enums, CommonModules, SessionParameters, Constants, Roles, Subsystems, EventSubscriptions, ScheduledJobs` и другие (`ManagerModule.bsl:28`).

### Расширяемость
Добавить свой инструмент = создать обработку + включить в подсистему `mcp_КонтейнерыИнструментов` + реализовать `ДобавитьИнструменты()` и `ВыполнитьИнструмент()`. Новые инструменты могут делать любые запросы к данным 1С (бизнес-данные, отчёты, остатки и т.д.) — рамки задаёт разработчик, не фреймворк.

### Классификация
**Группа A** — живые данные 1С. BSL-код выполняется внутри 1С-сервера и получает данные через нативные объекты (`Метаданные`, а кастомные инструменты могут обращаться к любым данным базы). Механизм доступа: **1С HTTP-сервис** (не файлы, не OData, не COM).

---

## РЕПО 3: ROCTUP/1c-mcp-toolkit

**URL:** https://github.com/ROCTUP/1c-mcp-toolkit  
**Лицензия:** файл LICENSE отсутствует; в README, README_FULL.md и BSL-коде упоминаний лицензии нет → изучаю подходы, код не копирую.  
**Стек:** BSL (внешняя обработка .epf), Python (FastAPI + MCP SDK), C++ (нативные компоненты), Docker  

### Назначение
Полноценная MCP-интеграция AI-агентов с живой базой 1С: запросы к данным, выполнение кода, журнал регистрации, метаданные, навигация по объектам.

### Архитектура
**Два режима** (README.md:19-53):
- **Встроенный сервер** (без Python): HTTP-сервер запускается внутри EPF через нативный компонент `MCPHttpTransport` (C++); AI-клиент → напрямую к порту 6003 внутри 1С.
- **Прокси-режим**: Python FastAPI-сервер + long polling: `AI-клиент ←→ Python (/mcp, /api/*) ←→ EPF 1С (/1c/poll, /1c/result)`.

### Механизм доступа к данным 1С
**EPF запущен внутри 1С-клиентской сессии** — BSL-код имеет полный доступ к данным текущей базы.  
- `execute_query`: `Новый Запрос(ТекстЗапроса)` + `Запрос.Выполнить()` — язык запросов 1С, читает любые данные БД (`Module.bsl:2737-2770`).  
- `execute_code`: `Выполнить(Код)` — произвольный BSL (`Module.bsl:3020`).  
- `get_event_log`: `ВыгрузитьЖурналРегистрации(ТаблицаЖурнала, Отбор, ...)` — встроенная функция BSL, читает Журнал регистрации напрямую из текущего сеанса (`Module.bsl:7043`).  
- `get_metadata`: `Метаданные[тип]` — метаданные конфигурации.

Нет HTTP/OData/COM — всё работает через стандартный API 1С изнутри сессии.

### Полный список MCP-инструментов (README.md:153-168)
`execute_query`, `execute_code`, `get_metadata`, `get_event_log`, `get_object_by_link`, `get_link_of_object`, `find_references_to_object`, `get_access_rights`, `get_bsl_syntax_help` (нативный компонент SyntaxHelpReader), `get_screenshot` (нативный ScreenCapture, Windows only), `submit_for_deanonymization`, `restart_1c_session`, `close_1c_session`.

### Анонимизация
Python-прокси может заменять персональные данные токенами `[ORG-00001]`, `[PER-00001]`, `[INN-00001]` и т.д. (ANONYMIZATION.md). Встроенный сервер — настройка через форму.

### Классификация
**Группа A** — живые данные 1С. EPF запущен внутри 1С-сессии, `execute_query` и `execute_code` — прямой доступ к любым данным базы. Мощнейший инструмент среди всех пяти.

---

## РЕПО 4: SteelMorgan/spring-mcp-1c-copilot

**URL:** https://github.com/SteelMorgan/spring-mcp-1c-copilot  
**Лицензия:** Custom Open Source (LICENSE:1-46) — некоммерческое использование свободно, коммерческое только с разрешения автора.  
**Стек:** Kotlin, Spring Boot 3.x, Spring WebFlux, Docker  

### Назначение
MCP-прокси к облачному AI-сервису **1С:Напарник** (`code.1c.ai`). Не работает с данными живой 1С-базы.

### Механизм доступа
**Внешний REST API** — Spring `WebClient` отправляет запросы к `https://code.1c.ai`:  
- `POST /chat_api/v1/conversations/` — создать сессию (с `skill_name`) (`OneCApiClient.kt:128-157`)  
- `POST /chat_api/v1/conversations/{sessionId}/messages` — отправить вопрос (`OneCApiClient.kt:55-58`)  
- Ответ — SSE поток, парсится в текст (`OneCApiClient.kt:163-285`)  
- Аутентификация: Bearer-токен в заголовке `Authorization` (`OneCApiClient.kt:28-31`)

1С:Напарник — это облачный AI-ассистент по программированию на BSL от фирмы «1С», не работает с данными конкретной базы.

### MCP-инструменты
| Инструмент | Что делает |
|---|---|
| `ask_1c_ai` | Задать вопрос 1С:Напарнику (вопрос, язык, новая сессия) |
| `explain_1c_syntax` | Объяснить синтаксис элемента 1С через Напарника |
| `check_1c_code` | Проверить код на ошибки через Напарника |

### Классификация
**Группа B** — НЕ живые данные 1С. Прокси к внешнему AI-сервису `code.1c.ai`; данные конкретной базы не затрагиваются. Не релевантно «теме 7».

---

## РЕПО 5: SteelMorgan/1c-ai-sandbox-client-server

**URL:** https://github.com/SteelMorgan/1c-ai-sandbox-client-server  
**Лицензия:** MIT (LICENSE:1 — «Copyright (c) 2026 Владимир Акимов»)  
**Стек:** Docker, Hyper-V, PowerShell, Bash, Python (опц.)  

### Назначение
Инфраструктурная «песочница» для AI-агентов, работающих с платформой 1С. **Не является MCP-сервером** и не реализует собственных инструментов для доступа к данным 1С.

### Архитектура (README.md:14-48)
Две части:
1. **Клиентский Dev Container** (VS Code/Cursor): Linux-контейнер с установленной платформой 1С (толстый/тонкий клиент + Конфигуратор), Xvfb (headless X11), CLI-агентами (Claude Code, Codex CLI, Gemini CLI).
2. **Серверная часть (Hyper-V VM)**: Ubuntu VM с Docker Compose — `onec-server` + `postgres` + `onec-web` (Apache), порты 1540/1541/1545/1560-1591/5432/8080.

### Что есть по теме доступа к данным 1С
Репозиторий только **запускает** 1С-окружение (сервер + базы). Как именно AI-агент обращается к этому 1С-серверу — определяет **другой** инструмент (например, 1c-mcp-toolkit, который устанавливается отдельно). Сам репозиторий не содержит ни MCP-инструментов, ни HTTP-сервисов, ни BSL-кода для доступа к данным.

Единственное, что релевантно теме 7 — это то, что инфраструктура обеспечивает живой 1С-сервер с базами (PostgreSQL backend), к которому уже можно подключать другие MCP-решения из данного списка.

### Классификация
**Группа B** — НЕ живые данные 1С (в смысле MCP-доступа). Это инфраструктура/платформа для запуска 1С-сред под AI-агентов. Собственных MCP-инструментов для доступа к данным нет. Не релевантно «теме 7» напрямую.
