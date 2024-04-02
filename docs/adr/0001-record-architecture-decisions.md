# 1. Record architecture decisions

Date: 2024-04-02

## Status

Accepted

## Context

This platform is small now, but the early decisions (cloud provider, IaC tool,
container orchestrator, GitOps controller, observability stack) tend to outlast
the people who made them. Six months in, the question "why did we pick this?"
loses fidelity quickly.

## Decision

We will record significant architectural decisions as Architecture Decision
Records (ADRs), following the format described by Michael Nygard.

ADRs live in `docs/adr/`, are numbered sequentially, and are immutable once
accepted. To revisit a decision, write a new ADR that supersedes the prior
one and link them.

## Consequences

- New contributors can read `docs/adr/` and understand the shape of the
  platform without spelunking through commit history.
- Decisions surface their tradeoffs explicitly, which discourages "we've
  always done it this way" reasoning.
- Cost: a small amount of writing for each major change. Worth it.

## Template

```
# N. Title

Date: YYYY-MM-DD

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR-NNNN](NNNN-...)

## Context

What forces are at play.

## Decision

What we decided.

## Consequences

What gets easier, what gets harder.
```
