# Git-aware orchestration

Goal: N agents in parallel **without breaking the repository**.

## Flow

```text
Task
 ↓
isolated branch/worktree  (task/<id>-<slug> → <project>-worktrees/<TASK-ID>)
 ↓
Agent implementation       (writes files only, in scope)
 ↓
Hermes diff review         (real diff + claims spot-check)
 ↓
tests / gates              (re-run by Hermes)
 ↓
integration branch          (Hermes merges)
 ↓
repository-wide test
 ↓
merge / DONE
```

## Rules

- One task = one worktree = one branch. Never two agents on the same file/scope concurrently.
- Agents NEVER run state-changing git (commit / merge / rebase / push). **Hermes owns all git.**
- Worktrees live outside the main repo: `<project>-worktrees/<TASK-ID>`; prompts in `_prompts/`,
  logs in `_logs/`.
- Hermes merges only after full verification; remove the worktree when done
  (`git worktree remove <path>`; prune occasionally).
- Keep `third_party/` checkouts and large binaries out of commits.

## Commands

```bash
# 1) create the task worktree
bash scripts/new-task-worktree.sh E:/my-project E:/my-project-worktrees T-101 short-slug

# 2) write the task card
$EDITOR E:/my-project-worktrees/_prompts/T-101.md

# 3) dispatch (timeout + log + exit marker; --dry-run to inspect)
bash scripts/launch-agent.sh cline E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --title T-101

# 4) verify + merge (Hermes)
cd E:/my-project-worktrees/T-101 && git status && git diff
cd E:/my-project && git merge --no-ff task/T-101-short-slug -m "merge: T-101 <title> (verified)"
```

Note (this machine, MSYS/git-bash): bash `cd /e/...` works, but paths passed as ARGUMENTS to
native tools (git, cmake, .exe) must be Windows-style (`E:/...`). Prefer `cygpath -m` or `pwd -W`
when converting.
