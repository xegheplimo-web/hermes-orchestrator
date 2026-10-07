# DECISIONS

One entry per binding decision. Newest at the bottom. Frozen interfaces/names change only via a new entry.

## D-001 (2026-10-06) — Kit created

- New repo `E:\hermes-orchestrator` materializes Sếp's canonical Lead Orchestrator brief into a
  reusable kit: canonical prompt + templates + control-plane scaffold + launch scripts.

## D-002 (2026-10-06) — PROMPT.md is canonical

- `PROMPT.md` reproduces the brief verbatim (formatting cleaned only). It is the system/project
  orchestrator prompt for any project run with this kit; changes go through this file.

## D-003 (2026-10-06) — Git ownership

- Agents write files; **Hermes owns git** (commit / merge / push). One task = one worktree =
  one branch (`task/<id>-<slug>`) created by `scripts/new-task-worktree.sh`.

## D-004 (2026-10-06) — Repo published (public GitHub)

- Kit repo published as <https://github.com/xegheplimo-web/hermes-orchestrator> (public), paired
  with the Hermes skill `lead-orchestrator`. Push discipline stays D-003: agents never push; Hermes
  owns remote operations. Repo-local `core.autocrlf false` pinned (CRLF ghost-diff prevention).
- `docs/installation.md` is the canonical onboarding path (verified commands + expected outputs);
  keep it in sync when CLI versions or launch conventions change.

## D-005 (2026-10-07) — PR review loop adopted (task T-109)

- Review comments (bot + human) are now a first-class verification input: new
  `docs/git-orchestration.md` section (fetch → classify → act → poll → gate), a
  `Review comments PASS` line in the `docs/gates.md` DONE checklist, a §16 extension in
  `PROMPT.md` (controlled addition to the canonical prompt), and skill `lead-orchestrator`
  v1.2.0 (§2 + §12). Tooling: Hub skills `resolve-reviews` / `resolve-agent-reviews` /
  `resolve-human-reviews` (pbakaus/agent-reviews, MIT) over `npx agent-reviews` (auth via `gh`).
- Gate: zero unanswered review comments before merge/DONE (skip only by explicit user
  decision, stated in the report). Bot comments are claims to verify — never authority.

## D-006 (2026-10-07) — §0 core vận hành (bản ngắn) + routing memory

- Sếp chốt bản prompt ngắn: **Lead Orchestrator + Technical Owner** — recon toàn dự án trước khi
  hành động · tài liệu chỉ để tham khảo (toàn quyền giữ/sửa/thay/thay thế) · quy trình
  Recon → Analyze → Decide → Plan → Assign → Implement → Verify → Fix → Integrate → Final Verify ·
  hoàn thành phải kiểm chứng bằng code/runtime/test/benchmark/integration. Thêm vào `PROMPT.md` §0;
  §1–§31 giữ nguyên làm bản chi tiết tham chiếu.
- Kèm theo: luật **học có chọn lọc** (chỉ lưu bài học tái sử dụng; ưu tiên cập nhật skill; memory
  chỉ cho luật áp dụng rộng; không học từ phỏng đoán/chưa test; thay thế bài học đã sai) + **routing
  memory** (agent × task-type, cập nhật theo round) → skill `lead-orchestrator` (§0/§13) +
  `docs/agent-matrix.md`.
