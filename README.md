# Азимут

ИИ-ассистент по коду 1С. MCP-сервер на базе форка [bsl-atlas](https://github.com/Arman-Kudaibergenov/bsl-atlas) (AGPL-3.0): понимает BSL-код, отвечает с проверкой достоверности, не галлюцинирует.

Работает локально — подключается к Cherry Studio, Claude Desktop или любому MCP-совместимому клиенту.

## Что делает

- индексирует BSL-код конфигурации 1С (`DumpConfigToFiles`)
- строит граф вызовов, режет на чанки детерминированно по структуре
- ищет: граф → метаданные → grep (fallback-цепочка)
- перед ответом проверяет faithfulness; при низкой уверенности переключается в режим дип-ресёрча
- иерархия источников при конфликте: код → справка → ИТС

## Быстрый старт

```bash
# Выгрузите конфигурацию 1С через Конфигуратор → «Выгрузить конфигурацию в файлы»

# Скопируйте .env.example и укажите путь к исходникам
cp .env.example .env
# SOURCE_PATH=/path/to/bsl-sources

# Запуск
docker compose up -d
```

Подключение к Claude Desktop / Cherry Studio — через `claude_desktop_config.json` или `.mcp.json`:

```json
{
  "mcpServers": {
    "azimut": {
      "type": "http",
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

## Архитектура

Документация по arc42 + C4 (Structurizr DSL):

```
docs/
├── index.md                        # точка входа
├── architecture/                   # 12 глав arc42 + глава 13 (Lead Manual)
│   ├── adr/                        # архитектурные решения (MADR, 34 ADR)
│   └── README.md                   # путеводитель по папке
└── cases/                          # эталонные кейсы
workspace.dsl                       # C4-модель (Context / Container / Component)
```

Просмотр C4-диаграмм локально (compose-профиль `diagrams`, см. `docker-compose.yml`):

```bash
docker compose --profile diagrams up -d structurizr
# → http://localhost:8080
docker compose --profile diagrams down
```

## Статус

Активная разработка. Сейчас: фаза 0 — scaffold документации и архитектурные решения (ADR 0001–0034).

Дорожная карта: [`docs/roadmap.md`](docs/roadmap.md) (создаётся в фазе 7).

## Лицензия

AGPL-3.0 — наследуется от форка bsl-atlas. См. [`LICENSE`](LICENSE) и [`COPYRIGHT`](COPYRIGHT).
