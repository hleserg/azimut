# Mermaid — Introduction

> Source: https://mermaid.js.org/intro/
> Access date: 2026-05-27
> Method: WebFetch (HTML → markdown summary)

## What is Mermaid?

Mermaid is a JavaScript-based diagramming and charting tool that enables users to create visualizations using text and code: "Mermaid lets you create diagrams and visualizations using text and code." It renders Markdown-inspired text definitions to dynamically generate and modify diagrams.

## Core Purpose

The primary mission of Mermaid is to combat "Doc-Rot" — the tendency for documentation to become outdated. By enabling quick diagram creation without extensive manual effort, the tool helps keep documentation current with development.

## Supported Diagram Types

- Flowchart
- Sequence Diagram
- Class Diagram
- State Diagram
- Entity Relationship Diagram
- User Journey
- Gantt
- Pie Chart
- Quadrant Chart
- Requirement Diagram
- GitGraph (Git) Diagram
- **C4 Diagram** (experimental — what we use for architecture)
- Mindmaps
- Timeline
- ZenUML
- Sankey
- XY Chart
- Block Diagram
- Packet
- Kanban
- Architecture
- Radar
- Event Modeling
- Treemap
- Venn
- Ishikawa
- Wardley
- TreeView

## Embedding in Markdown

Mermaid diagrams are embedded using fenced code blocks with the `mermaid` language identifier:

````markdown
```mermaid
[diagram definition here]
```
````

GitHub natively renders these fenced blocks in markdown files (READMEs, issues, PRs, wiki). GitLab supports it too. This is why we use Mermaid: it renders directly in git-hosted previews without any build step.

## Installation (only needed for local/CI rendering, not for GitHub render)

```sh
npm i mermaid          # npm
yarn add mermaid       # yarn
pnpm add mermaid       # pnpm
```

CDN: `https://cdn.jsdelivr.net/npm/mermaid@11/dist/`

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: true });
</script>
```
