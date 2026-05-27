# Источники: спецификации по которым мы пишем документацию

Формат строки: `<url> | <дата доступа или НЕ СКАЧАНО> | <зачем нам / причина>`.

Все скачанное лежит в соседних подпапках (`arc42/`, `madr/`, `c4/`, `mermaid/`).
Задача-исток: [HLE-493](https://linear.app/hleserg/issue/HLE-493).

## arc42 — шаблон архитектурной документации (12 секций)

- https://arc42.org/ | 2026-05-27 | Главная страница, краткое описание шаблона → `arc42/arc42-org-home.md`
- https://docs.arc42.org/home/ | 2026-05-27 | Полный список 12 секций с описаниями → `arc42/docs-arc42-org-sections.md`
- https://github.com/arc42/arc42-template | 2026-05-27 | Репо склонировано, скопированы канонические asciidoc-шаблоны 12 секций (EN) → `arc42/EN-adoc/`, плюс README/LICENSE
- https://github.com/arc42/arc42-template/tree/master/EN/withhelp/markdown | НЕ СКАЧАНО | Путь `EN/withhelp/markdown` в upstream-репо отсутствует (только `EN/adoc/`). Markdown-версия в текущем релизе шаблона генерируется через arc42-generator и в репо не хранится. По правилу из тикета — не подменяем источник. Asciidoc-эквивалент с тем же содержанием лежит в `arc42/EN-adoc/`.

## MADR — формат ADR

- https://adr.github.io/madr/ | 2026-05-27 | Главная MADR, поля шаблона, нейминг файлов → `madr/site-madr-home.md`
- https://github.com/adr/madr | 2026-05-27 | Репо склонировано, скопированы `template/` (все варианты adr-template) и README → `madr/template/`, `madr/README.md`
- https://github.com/adr/madr/blob/main/template/adr-template.md | 2026-05-27 | Канонический шаблон ADR в формате MADR → `madr/template/adr-template.md`
- https://adr.github.io/ | 2026-05-27 | Общий контекст ADR: история, определения, известные шаблоны (Nygard / MADR / Tyree-Akerman / Y-statement) → `madr/site-adr-context.md`

## C4 model — уровни Context / Container / Component / Code

- https://c4model.com/ | 2026-05-27 | Главная: 4 уровня абстракции, 4+3 типа диаграмм → `c4/c4model-home.md`
- https://c4model.com/diagrams | 2026-05-27 | Раздел про типы диаграмм, ссылки на правила нотации → `c4/c4model-diagrams.md`
- https://c4model.com/diagrams/notation | 2026-05-27 | (бонус, не из тикета — но без него нет правил нотации) Полные правила: title, key/legend, типы элементов, лейблы связей → `c4/c4model-notation.md`

## Mermaid — синтаксис диаграмм для git-рендера

- https://mermaid.js.org/intro/ | 2026-05-27 | Введение, полный список типов диаграмм, как встраивать в markdown → `mermaid/mermaid-intro.md`
- https://mermaid.js.org/syntax/flowchart.html | 2026-05-27 | Синтаксис flowchart: направления, формы узлов, стрелки, subgraph → `mermaid/mermaid-flowchart.md`
- https://mermaid.js.org/syntax/sequenceDiagram.html | 2026-05-27 | Синтаксис sequence diagram: participant/actor, стрелки, alt/opt/par, notes → `mermaid/mermaid-sequence.md`
- https://mermaid.js.org/syntax/c4.html | 2026-05-27 | Экспериментальный C4-синтаксис Mermaid: Person/System/Container/Component/Rel/Boundary → `mermaid/mermaid-c4.md`

## Итого

- Заявлено в тикете: **14** ссылок (4 arc42 + 4 MADR + 2 C4 + 4 Mermaid).
- Скачано: **13**.
- Failed / НЕ СКАЧАНО: **1** (см. выше — путь `EN/withhelp/markdown` отсутствует в upstream).
- Дополнительно (не из тикета): https://c4model.com/diagrams/notation — нужно для следующих задач, чтобы агент знал правила нотации C4. Без него страница `/diagrams` оказалась только навигационной.
