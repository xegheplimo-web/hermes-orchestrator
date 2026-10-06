# Gates & DONE definition

## Gate list (run what the repo has; skip what it doesn't)

```text
FORMAT · LINT · TYPECHECK · UNIT TEST · INTEGRATION TEST · E2E TEST · BUILD
```

## DONE — never on "code written" / "agent says done"

DONE only when ALL of these pass:

```text
Acceptance criteria       PASS
Relevant tests            PASS
Lint                      PASS
Typecheck                 PASS
Build                     PASS
Integration               PASS
Diff review               PASS
No unresolved blocker     PASS
```

If any item FAILS → STATUS = NOT DONE → Fix → Verify → Integrate → Final Verify.

## Command sets (examples — use what the repo actually has)

- **Node/TS**: `npm run format:check` · `npm run lint` · `npm run typecheck` · `npm test` · `npm run build`
- **Python**: `ruff check .` && `ruff format --check .` && `pytest`
- **CMake/C++**: `cmake --build build` && `ctest --test-dir build --output-on-failure`
- **Rust**: `cargo fmt --check && cargo clippy && cargo test && cargo build`
- **Shell**: `bash -n <script>` (+ shellcheck if available) && `bash scripts/smoke-test.sh`

## Evidence discipline

- Re-run gates YOURSELF (orchestrator); "the agent ran its own tests" is not evidence.
- Spot-check agent claims against the actual source (line numbers, symbols, hashes).
- For retries: confirm the final artifact's mtime/content belongs to the LATEST run.
- **A dead run is not a failed task**: on provider stream errors / mid-run deaths, inspect the
  worktree before declaring failure — if the deliverable + evidence are complete and the gate
  re-run is green, the orchestrator completes the commit and logs the provenance
  (see `agent-matrix.md` → Field lessons).
- **Scope check is THREE-dot** (`git diff main...HEAD`) — two-dot shows phantom noise once main
  moves ahead.

## Diff hygiene (before DONE)

Check `git diff --stat` + `git diff`. Not accepted: debug logs, temp code, meaningless TODOs,
commented-out code, unrelated formatting, accidental dependency changes, generated files,
secrets/credentials/`.env`, stray binaries.
