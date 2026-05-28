# CLAUDE.md

See [AGENTS.md](AGENTS.md) for all project rules (ADR process, DoD, commit standard, arc42 chapters, scripts).

## Claude Code — специфика

**MCP-серверы** (если подключены): `mcp__claude_ai_Linear__*` — для работы с задачами Linear.

**Скиллы** (вызываются через `/skill-name`):
- `/code-review` — ревью текущего diff
- `/run` — запустить приложение
- `/verify` — верифицировать изменение

**Локальные команды:**

```bash
# Создать новый ADR
./scripts/new-adr.sh <подпапка> <kebab-title>

# Обновить индекс ADR в 09-architectural-decisions.md
./scripts/update-adr-index.sh

# Поднять локальный viewer C4-диаграмм (compose-профиль "diagrams")
docker compose --profile diagrams up -d structurizr-proxy     # → http://localhost:8080
docker compose --profile diagrams down                  # остановить
```

**Статус-протокол:** при начале работы → `In Progress`; PR готов → `In Review`. `Done` ставит только Сергей.
