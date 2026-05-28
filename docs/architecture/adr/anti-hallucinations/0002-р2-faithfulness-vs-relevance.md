---
status: accepted
date: 2026-05-25
decision-makers: "[Сергей]"
linear-task: "HLE-418"
basis: "_source/notion/decisions--36b0c905e62681019228dfcc7ec2a1cb.md §Р2"
implemented-in: "docs/architecture/08-cross-cutting-concepts.md §«Метрики качества»; docs/architecture/10-quality-requirements.md; eval-харнесс (RAGAS) + LLM-судья (ADR 0003)"
related-to: "[0003](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/anti-hallucinations/0003-р3-llm-judge-spans.md), [0008](https://github.com/hleserg/azimut/blob/master/docs/architecture/adr/anti-hallucinations/0008-п1-groundedness-detector.md)"
supersedes: ""
superseded-by: ""
---

# Faithfulness и relevance ретривера — разные метрики

## Context and Problem Statement

Соблазн измерять качество RAG-системы «одним числом» (точность, удовлетворённость, общая faithfulness) на практике скрывает причину деградации: непонятно, виноват ретривер (не нашёл) или генератор (нашёл, но не опёрся). Чтобы калибровать систему по слоям, нужно разделить эти два сигнала.

## Decision Drivers

* Возможность диагностировать, какой слой деградировал (ретривер vs генератор).
* Возможность независимо калибровать порог релевантности (Р5 / ADR 0005) и поведение судьи (Р3 / ADR 0003).
* Совместимость с практиками RAGAS / Self-RAG 2026 (разделение retrieval-метрик и generation-метрик).
* Прозрачность в дашборде: одна цифра «качество» не позволяет принять решение, две и больше — позволяют.

## Considered Options

* (A) Считать relevance ретривера и faithfulness генерации как две независимые метрики.
* (B) Считать одну агрегированную метрику «качество ответа» (например, end-to-end satisfaction).
* (C) Считать только faithfulness (исходя из того, что плохой retrieval всё равно проявится в низком faithfulness).

## Decision Outcome

Chosen option: «(A) две независимые метрики», because только так можно понять, где именно проблема, и независимо двигать пороги/политики каждого слоя. Это базовое условие для калибровки Р5 (контроль ретривинга) и Р3 (LLM-судья).

### Consequences

* Good, because деградация ретривера и деградация генератора видны раздельно.
* Good, because вписывается в эволюцию: добавление детектора groundedness (П1 / ADR 0008) — это уже третий независимый сигнал поверх этой пары.
* Bad, because стоимость eval-харнесса выше: нужны разные датасеты/инструменты для retrieval-метрик и generation-метрик.

### Confirmation

* В eval-харнессе (RAGAS) считаются как минимум две метрики: `context_relevance` (ретривер) и `faithfulness` (генератор).
* Дашборд показывает их раздельно во времени, без агрегации в «общее качество».
* В §10 (quality-requirements) пороги по этим метрикам указаны отдельно.

## Pros and Cons of the Options

### (A) Две независимые метрики

* Good, because диагностируема причина деградации.
* Good, because калибруется по слоям.
* Bad, because больше инфраструктуры eval.

### (B) Одна агрегированная

* Good, because проще считать и докладывать.
* Bad, because не отвечает на вопрос «что чинить».

### (C) Только faithfulness

* Good, because дешевле.
* Bad, because низкая faithfulness может быть от плохого retrieval ИЛИ плохой генерации — снова не отвечает «что чинить».

## More Information

* Источник: `_source/notion/decisions--*.md` §Р2.
* Связанные ADR: 0003 (LLM-судья), 0008 (детектор groundedness — третий независимый сигнал).
* Контекст в arc42: §8 (cross-cutting) — общая модель метрик; §10 (quality) — конкретные пороги.
