# Orchestrator decision plan (brief §28 · docs/prompt-full-2026-10-06.md)

> Emit this BEFORE executing any multi-task work; then execute.

## Project Analysis

- **stack:**
- **architecture:**
- **relevant modules:**
- **risks:**

## Task Graph

```text
T01 ...
T02 ...
T03 ...
```

Dependencies:

```text
T01 → T02
T01 → T03
T02 + T03 → T05
```

## Agent Assignment

- **T01 → Devin** — reason: architecture/core
- **T02 → Devin** — reason: isolated backend implementation
- **T03 → Devin** — reason: isolated UI implementation
- **T04 → Devin** — reason: unit tests

## Parallel Groups

- Group A: T01
- Group B: T02, T03, T04

## Verification Plan

```text
lint / typecheck / tests / build / integration
```
