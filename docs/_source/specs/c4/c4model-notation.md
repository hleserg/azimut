# C4 Model — Notation Specification

> Source: https://c4model.com/diagrams/notation
> Access date: 2026-05-27
> Method: WebFetch (HTML → markdown summary)
> Note: this URL was not listed in the original task but was crawled because the `/diagrams` page is a navigation hub — the actual notation rules live here.

## Core Principle

The C4 model is **notation independent** and doesn't mandate specific visual conventions, though diagrams must be self-contained and comprehensible.

## Diagram Requirements

### Titles & Keys
- Each diagram requires a descriptive title indicating type and scope
- Every diagram needs a key/legend explaining notation (shapes, colors, borders, line styles, arrows)
- Acronyms must be understandable to all audiences or defined in the legend

## Element Specifications

### Type Declaration
- Element types must be explicitly stated: **Person**, **Software System**, **Container**, **Component**

### Descriptions
- Each element requires a concise description for quick understanding of responsibilities
- Containers and components must explicitly specify their technology

## Relationship Guidelines

### Line Conventions
- Lines represent **unidirectional** relationships
- All lines must be labeled with consistent, specific terminology
- Container relationships require explicit technology/protocol labels
- **Avoid vague labels like "Uses"**

## Color Usage

Colors aren't dictated by C4. Organizations may choose any palette, provided they:
- Maintain consistency within and across diagrams
- Consider accessibility (colorblind users, black/white printing)

## Alternative Notations

C4 diagrams can be expressed through:
- UML (packages, components, stereotypes)
- ArchiMate
- Non-traditional visualizations (force-directed graphs, interactive exploration tools)

The specification emphasizes clarity and self-documentation over rigid formatting rules.
