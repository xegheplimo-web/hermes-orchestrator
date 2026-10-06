# INTERFACES — script CLI contracts

Changing any of these contracts is a breaking change: record a DECISIONS entry and update
`README.md` + templates together.

## scripts/bootstrap-project.sh

```text
bash scripts/bootstrap-project.sh <project-dir> [--name NAME] [--worktrees-dir DIR] [--no-git]
```

- Creates `<project-dir>/.orchestrator/` (rendered from `templates/control-plane/`),
  `<project-dir>/agent_logs/`, `<worktrees>/_prompts`, `<worktrees>/_logs`,
  and appends `.gitignore` entries.
- `git init` (default branch `main`) unless `--no-git` or already a repo.
- Non-destructive: existing files are skipped with a notice. Exit 0 on success.

## scripts/new-task-worktree.sh

```text
bash scripts/new-task-worktree.sh <project-dir> <worktrees-root> <task-id> <slug> [base-branch]
```

- Runs `git worktree add <worktrees-root>/<task-id> -b task/<task-id>-<slug> <base>` (base default `main`).
- Refuses if the target worktree path already exists. Exit 0 on success.

## scripts/launch-agent.sh

```text
bash scripts/launch-agent.sh <cline|opencode|devin> <workdir> <prompt-file> [--title T] [--log L] [--model M] [--timeout S] [--dry-run]
```

- Runs the agent CLI with the prompt read from file; wall-clock `timeout` guard; stdout+stderr to
  log; appends `EXIT=<code>` to the log (and prints it).
- `--dry-run` prints the exact command without running (no prechecks, no log, no side effects).
- Exit code = the agent's own exit code. Defaults: cline/opencode timeout 1500s, devin 2400s;
  default log `<workdir>/agent_logs/<title>.log`; default models per `docs/agent-matrix.md`.

## scripts/smoke-test.sh

```text
bash scripts/smoke-test.sh
```

- Self-test: `bash -n` on all scripts; throwaway bootstrap in a temp dir; assertions on control
  plane, worktrees, git init; worktree creation; dry-run commands for all three agents.
- Exit 0 iff all checks pass. Prints a PASS/FAIL line per check + a summary count.
