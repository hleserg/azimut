# MADR — Home (adr.github.io/madr)

> Source: https://adr.github.io/madr/
> Access date: 2026-05-27
> Method: WebFetch (HTML → markdown summary)

## What is MADR?

MADR is a streamlined template for documenting architectural decisions in a structured markdown format. An "Architectural Decision (AD) is a justified software design choice that addresses a functional or non-functional requirement of architectural significance."

The acronym stands for **Markdown Architectural Decision Records**, though the framework supports capturing any important decision, not strictly architectural ones.

## Why Use MADR?

- Makes it easy to document decisions
- Enables version control of those decisions
- Preserves rationale and makes reasoning transparent across teams and time

## Key Structural Elements

- **Context and Problem Statement** — situation and challenge
- **Decision Drivers** — forces or concerns influencing the choice
- **Considered Options** — alternative approaches evaluated
- **Decision Outcome** — the chosen option with justification
- **Consequences** — both positive and negative impacts
- **Confirmation** — how compliance will be verified
- **Pros and Cons of the Options** — detailed analysis supporting the decision

## File Naming Conventions

ADRs follow the pattern `NNNN-title-with-dashes.md` where:
- `NNNN` is a consecutive four-digit number
- Filenames use lowercase with dashes (not underscores)
- Files reside in a `docs/decisions` folder

## Categorization for Large Projects

Projects can organize decisions using subdirectories reflecting architectural structure (e.g., `decisions/backend/`, `decisions/ui/`), allowing local numbering schemes within categories.

## Tooling and Standards

- Templates support YAML front-matter for metadata
- Markdownlint configuration ensures formatting consistency
- GitHub workflows can automate ADR linting
- Cross-referencing between ADRs is supported

## Versions Mentioned

- **4.0.0** (Sept 2024) — introduced "bare" and "minimal" template variants
- **3.0.0** — consolidated consequence sections

## Licensing

Dual-licensed: MIT and CC0 1.0.
