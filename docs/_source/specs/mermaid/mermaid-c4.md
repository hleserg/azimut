# Mermaid — C4 Diagram Syntax (experimental)

> Source: https://mermaid.js.org/syntax/c4.html
> Access date: 2026-05-27
> Method: WebFetch (HTML → markdown summary)

## Overview

C4 diagrams in Mermaid are **experimental** — "the syntax and properties can change in future releases." Syntax is largely compatible with PlantUML C4 macros.

## Supported Diagram Types

1. `C4Context` — System context diagrams
2. `C4Container` — Container-level architecture
3. `C4Component` — Component details
4. `C4Dynamic` — Dynamic interactions
5. `C4Deployment` — Deployment infrastructure

## Element Types

### People & Systems
- `Person(alias, label, ?descr)` — Individual actor
- `Person_Ext(...)` — External person
- `System(alias, label, ?descr)` — Internal system
- `System_Ext(...)` — External system
- `SystemDb(...)` — Database system
- `SystemQueue(...)` — Queue system

### Containers & Components
- `Container(alias, label, ?techn, ?descr)` — Container element
- `Container_Ext(...)` — External container
- `ContainerDb(...)` / `ContainerQueue(...)` — Specialized containers
- `Component(alias, label, ?techn, ?descr)` — Component element
- `ComponentDb(...)` / `ComponentQueue(...)` — Specialized components

### Deployment
- `Node(alias, label, ?type, ?descr)` — Deployment node
- `Node_L(...)` / `Node_R(...)` — Left/right-aligned variants

### Relationships
- `Rel(from, to, label)` — Directed relationship
- `BiRel(...)` — Bidirectional relationship
- `Rel_U()`, `Rel_D()`, `Rel_L()`, `Rel_R()` — Directional variants
- `RelIndex(index, from, to, label)` — Dynamic sequence (index currently ignored)

### Boundaries
- `Boundary(alias, label)` — Generic boundary
- `Enterprise_Boundary(...)` — Enterprise scope
- `System_Boundary(...)` — System scope
- `Container_Boundary(...)` — Container scope

### Styling
- `UpdateElementStyle(element, ?bgColor, ?fontColor, ?borderColor)`
- `UpdateRelStyle(from, to, ?textColor, ?lineColor, ?offsetX, ?offsetY)`
- `UpdateLayoutConfig(?c4ShapeInRow, ?c4BoundaryInRow)` — Layout customization

## Key Limitations (vs. PlantUML C4)

Not currently supported:
- Sprites, tags, links, legends
- Layout directives (`Lay_U`, `Lay_D`, `Lay_L`, `Lay_R`)
- Custom tags/stereotypes
- Automated layout algorithms (position relies on statement order)

## Parameter Assignment Methods

Positional:
```
UpdateRelStyle(customerA, bankA, "red", "blue", "-40", "60")
```

Named (`$` prefix):
```
UpdateRelStyle(customerA, bankA, $offsetY="60", $textColor="red")
```
