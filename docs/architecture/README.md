# Архитектурная документация Азимута

Путеводитель по папке для людей и ИИ-агентов.

## Как читать эту папку

Документация структурирована по полному шаблону **arc42** (12 глав) плюс наша 13-я глава (Lead Operating Manual). Каждый файл отвечает за строго определённый вид знания:

| Файл | arc42 § | За что отвечает |
|---|---|---|
| [`01-introduction-and-goals.md`](01-introduction-and-goals.md) | §1 | Назначение, стейкхолдеры, top quality goals |
| [`02-architecture-constraints.md`](02-architecture-constraints.md) | §2 | Технические и организационные ограничения |
| [`03-context-and-scope.md`](03-context-and-scope.md) | §3 | Контекст и границы системы; C4 systemContext |
| [`04-solution-strategy.md`](04-solution-strategy.md) | §4 | Ключевые архитектурные решения одним списком |
| [`05-building-block-view.md`](05-building-block-view.md) | §5 | Структура: контейнеры, компоненты; C4 views |
| [`06-runtime-view.md`](06-runtime-view.md) | §6 | Поведение в ключевых сценариях (Mermaid sequence) |
| [`07-deployment-view.md`](07-deployment-view.md) | §7 | Развёртывание; локальный и VDS-сценарий |
| [`08-cross-cutting-concepts.md`](08-cross-cutting-concepts.md) | §8 | Сквозные концепции: анти-галлюцинации, безопасность, лицензии |
| [`09-architectural-decisions.md`](09-architectural-decisions.md) | §9 | Индекс ADR по темам и статусам (автогенерация) |
| [`10-quality-requirements.md`](10-quality-requirements.md) | §10 | NFR: faithfulness, latency, отказоустойчивость |
| [`11-technical-risks.md`](11-technical-risks.md) | §11 | Технические риски и слепые зоны |
| [`12-glossary.md`](12-glossary.md) | §12 | Термины 1С, проектные, технические |
| [`13-lead-operating-manual.md`](13-lead-operating-manual.md) | (наше) | Регламент Лида: чек-листы, метрики, триаж, LLM-протокол |

## Где живут C4-диаграммы

Единый источник статичных C4-диаграмм (System Context, Container, Component) — файл **[`workspace.dsl`](../../workspace.dsl)** в корне репо (ADR 0034).

Просмотр локально:
```bash
docker run -it --rm -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite
```
Открыть `http://localhost:8080`.

Mermaid остаётся для §6 Runtime View (sequenceDiagram читается лучше в git diff).

## Где живут ADR

Каталог [`adr/`](adr/) с подпапками по темам:

| Подпапка | Тема | ADR |
|---|---|---|
| [`adr/anti-hallucinations/`](adr/anti-hallucinations/) | Анти-галлюцинации (Р1–Р7, П1–П3) | 0001–0010 |
| [`adr/foundation/`](adr/foundation/) | Фундамент (тема 1, HLE-413) | 0011–0023 |
| [`adr/code-processing/`](adr/code-processing/) | Обработка кода 1С (тема 2, HLE-414) | 0024–0027 |
| [`adr/tooling/`](adr/tooling/) | Инструментарий и процесс | 0034 |
| [`adr/open/`](adr/open/) | Открытые вопросы (proposed/open) | 0028–0033 |

Шаблон нового ADR: [`adr/template.md`](adr/template.md).

Генерация нового ADR:
```bash
./scripts/new-adr.sh <подпапка> <kebab-title>
```

## Инструкция ИИ-агентам

**Куда дописывать новое знание:**
- Требование безопасности → §8 (`08-cross-cutting-concepts.md`)
- Техническое или организационное ограничение → §2 (`02-architecture-constraints.md`)
- Нефункциональное требование → §10 (`10-quality-requirements.md`)
- Архитектурное решение → новый ADR в `adr/<подпапка>/` по шаблону `adr/template.md`
- Новый компонент/сервис → обновить `workspace.dsl` + §5 + §7 (если меняется деплой) + §13
- Новый риск → §11 (`11-technical-risks.md`)
- Новый термин → §12 (`12-glossary.md`)

**DoD (Definition of Done):** задача не считается выполненной без обновления `workspace.dsl` + ADR + (если новый сервис) главы 13. Подробности — в `AGENTS.md` корня репо.

**Правило пустых секций** (из `docs/_source/specs/_howto.md` §1): пустая секция оставляется с заголовком и одной фразой «здесь пока нечего сказать, см. <ссылка>». Не удаляем — это сигнал «об этом подумали».
