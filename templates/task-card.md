# Task {{TASK_ID}} — {{TITLE}}

> Mandatory task format (PROMPT.md §7). The agent sees NOTHING of the conversation — this card
> must be self-contained. Save as `_prompts/{{TASK_ID}}.md` and pass via `"$(cat file)"`.

## Objective

<Exact goal of this task, one paragraph.>

## Context

<Everything the agent needs: project, branch/worktree, authoritative inputs to read,
interfaces involved, constraints. Absolute paths.>

## Scope

<What the agent may create/modify — write ONLY here.>

## Files

<Relevant files/folders to read (absolute paths where possible).>

## Do Not Touch

<Files/modules the agent must NOT modify (`.orchestrator/**`, `AGENTS.md`, other tasks' files, ...).>

## Requirements

1. ...
2. ...

## Acceptance Criteria

1. ...
2. ...

## Verification

Exact commands the ORCHESTRATOR will re-run (Hermes, independently):

```bash
<commands>
```

## Output Required

Final report must contain:

- files changed
- summary
- commands executed (exact)
- test results (real output)
- known limitations
- unresolved issues

## Constraints

- No commit / merge / rebase / push — write files only; Hermes owns git.
- English artifacts. If blocked, report `BLOCKER:` + `SUGGESTED FOLLOW-UP:` — do not expand scope.
