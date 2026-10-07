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
- **Pin repo-local git config** in the main repo: `user.name`, `user.email`, `core.autocrlf false`.
  Worktree commits/merges run from different tool sessions and otherwise fail with "Committer
  identity unknown" or produce CRLF ghost-diffs.
- **Scope/diff checks are THREE-dot** (`git diff main...HEAD`) — two-dot shows phantom noise once
  main moves ahead. Spell the three-dot rule out in prompts whose agent does its own diff checks.
- **Bookkeeping is a separate commit**: control-plane updates (TASKS.json · VERIFICATION.md ·
  PROJECT_STATE) go in one `orchestrator: <task> verified + merged (bookkeeping)` commit right
  after the merge.
- **If a run dies pre-commit but the work is complete** (provider stream errors): Hermes completes
  the commit on the task branch with the prompt's message and logs the provenance — completed work
  is never lost to a dead CLI process.
- **Pause/resume**: on a user pause, kill agent + child processes, verify quiet, write
  `_prompts/T-xxx-resume.md` (state · paths · continuation steps); resume = re-dispatch with a
  continuation prompt pointing at that note.

## PR review loop (when the round lands as a GitHub PR)

Review comments are part of verification. When a PR receives reviews — bots (Copilot,
Cursor Bugbot, CodeRabbit, Gemini, Sonar, Sourcery, Codacy…) and/or humans — run this
loop after pushing and BEFORE reporting DONE. Tooling: Hub skills `resolve-reviews` /
`resolve-agent-reviews` / `resolve-human-reviews` (pbakaus/agent-reviews, MIT) drive
`npx agent-reviews` (auth reuses `gh`; nothing to configure).

1. **Fetch** — `npx agent-reviews --unanswered --expanded` lists every unanswered comment
   (ID, diff hunk, replies). Zero comments → skip to step 5.
2. **Classify** — bot: TRUE POSITIVE / FALSE POSITIVE; human: actionable / discussion /
   already addressed. A bot comment is a claim to verify against the code and the spec,
   never an authority — Hermes owns the classification.
3. **Act** — TRUE POSITIVE → fix via the owning agent (exact comment + evidence; the
   fail#1/fail#2 policy applies); FALSE POSITIVE → keep the code, reply with the reason;
   discussion → Hermes decides or asks Sếp. Reply to EVERY comment with the outcome.
4. **Poll** — watch until the PR goes quiet; bot doom-loops ("fix → push → new comments")
   resolve through the same loop instead of being chased by hand.
5. **Gate** — zero unanswered review comments before merge/DONE (skip only by explicit
   Sếp decision, stated in the report).

## Commands

```bash
# 1) create the task worktree
bash scripts/new-task-worktree.sh E:/my-project E:/my-project-worktrees T-101 short-slug

# 2) write the task card
$EDITOR E:/my-project-worktrees/_prompts/T-101.md

# 3) dispatch (timeout + log + exit marker; --dry-run to inspect)
bash scripts/launch-agent.sh cline E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --title T-101

# 4) verify + merge (Hermes)
cd E:/my-project-worktrees/T-101 && git status && git diff main...HEAD
cd E:/my-project && git merge --no-ff task/T-101-short-slug -m "merge: T-101 <title> (verified)"

# 5) bookkeeping (same session)
cd E:/my-project && git add .orchestrator && git commit -m "orchestrator: T-101 verified + merged (bookkeeping)"
```

Note (this machine, MSYS/git-bash): bash `cd /e/...` works, but paths passed as ARGUMENTS to
native tools (git, cmake, .exe) must be Windows-style (`E:/...`). Prefer `cygpath -m` or `pwd -W`
when converting.
