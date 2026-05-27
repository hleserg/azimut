# ADR — General Context (adr.github.io)

> Source: https://adr.github.io/
> Access date: 2026-05-27
> Method: WebFetch (HTML → markdown summary)

## What Is an ADR?

An **Architectural Decision Record (ADR)** documents a single architectural decision and its rationale. "An Architectural Decision (AD) is a justified design choice that addresses a functional or non-functional requirement that is architecturally significant."

ADRs capture the reasoning behind choices, including trade-offs and consequences. The collection of ADRs within a project forms its **decision log**.

## Key Definitions

- **Architectural Decision (AD)** — a justified design choice with architectural significance
- **Architecturally Significant Requirement (ASR)** — a requirement measurably affecting system architecture and quality
- **Architectural Decision Record (ADR)** — documentation of a single AD with its rationale
- **Architectural Knowledge Management (AKM)** — the broader practice of managing architectural knowledge

## Historical Development

The concept gained prominence through **Michael Nygard's 2011 blog post** "Documenting Architecture Decisions", which popularized lightweight ADR templates. Earlier work began in the late 1990s.

## Primary Motivations

- **Transparency** — making decision-making processes visible and traceable
- **Onboarding** — helping new team members understand architectural choices
- **Knowledge preservation** — capturing institutional knowledge beyond individuals
- **Traceability** — documenting rationale alongside decisions
- **Iterative improvement** — supporting agile and incremental engineering processes

## Common ADR Templates

1. **Nygard Template** — original lightweight format from the 2011 blog post
2. **MADR** (Markdown Architecture Decision Records) — modern markdown-friendly variant (what we use)
3. **Tyree-Akerman Template** — structured approach from earlier research
4. **Y-Statement Format** — from "Sustainable Architectural Decisions" by Zdun et al.

## Recommendations by Major Frameworks

- **Azure Well-Architected Framework** features ADRs prominently (2024)
- **AWS Prescriptive Guidance** recommends ADRs for streamlining technical decisions
- **Open Practice Library** includes ADRs as an established practice
