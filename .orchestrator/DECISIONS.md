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

## D-007 (2026-10-08) — Devin lane → cloud (MCP/API); CLI = local fallback (T-112)

- Quy trình đổi kênh Devin: **Devin cloud qua MCP/API là kênh chính** — MCP server `devin`
  (`https://mcp.devin.ai/mcp`, service-user key → `MCP_DEVIN_API_KEY` trong
  `%LOCALAPPDATA%\hermes\.env`); Hermes lái session qua tools `mcp__devin__*` (create → poll →
  branch/PR). **Devin CLI giữ nguyên làm local fallback** (repo local-only / cloud lane down).
- Sync trong cùng round: skill `lead-orchestrator` v1.3.0 (§1 · §6 · §9) · skill `devin-cli`
  v1.1.0 (cloud section) · `docs/installation.md` (§0/§1/§2.3/§4/§6/§7/§8/§9) · `docs/agent-matrix.md`
  · `README.md` · `AGENTS.md` · `PROMPT.md` (§2/§3) · `scripts/preflight.sh` (§3b MCP checks).
- Keys/tokens **never transit chat** (standing rule; rotate on any exposure). Cloud sessions are
  quota-billed — no speculative runs. Setup step is user-run:
  `hermes mcp add devin --url https://mcp.devin.ai/mcp --auth header`.
- Fix kèm: guard-test rows trong `docs/installation.md` synced 16 → 19 (drift từ `8fceeac`).

## D-008 (2026-10-08) — Devin lane chốt về CLI-only; bỏ lane MCP/API (đảo D-007) (T-113)

- Convention: **Devin = Devin CLI — lane duy nhất** (hard worker). Bỏ hẳn lane MCP/API (server MCP,
  REST, key `.env`) và mọi nhắc kiểu fallback/cloud trong execution convention — không giữ kể cả làm
  dự phòng. Devin Desktop là app của Sếp — Hermes không đụng vào (không kill / không cấu hình).
- Lý do: lane MCP **chưa từng được đăng ký** (bước add treo từ D-007) → convention mô tả một lane
  không tồn tại; một lane duy nhất = hết split-brain giữa skill / kit docs / launcher / preflight.
  Canonical form: `devin --respect-workspace-trust false --permission-mode dangerous -p --prompt-file <file>`.
- Sync (T-113): skill `lead-orchestrator` v1.4.5 (§1 · §6 · §9) · skill `devin-cli` v1.4.0 (rename về
  từ tên thời D-007 + content CLI-only) · kit: PROMPT · agent-matrix · installation (§0–§9) · README ·
  AGENTS · preflight (§3b `devin doctor` + §3c banned-token drift scan) · launcher (`--prompt-file` +
  cygpath) · smoke needle · retire file 1-click `Them-Devin-MCP.cmd`.
- Gate mới: `preflight.sh` §3c quét banned tokens (MCP endpoint/key, tên cũ, fallback wording) trên
  kit + agent skills — drift nằm trong chữ nghĩa giờ FAIL preflight, không còn chỉ grep tay.

## D-009 (2026-10-08) — Prompt chính = bản ngắn → skill canonical; Execution invariants trong skill (T-114)

- Kiến trúc chốt (Sếp): SOUL/project prompt giữ vai trò + mục tiêu cấp cao; mọi quy tắc chi tiết sống
  trong skill `lead-orchestrator` (canonical). Prompt không lặp lại quy tắc dài ("300 dòng").
- `PROMPT.md` → bản ngắn (~15 dòng); bản đầy đủ 2026-10-06 chuyển sang `docs/prompt-full-2026-10-06.md`
  (archive; các "§N" trong templates/docs trỏ về đây).
- Skill `lead-orchestrator` v1.4.6: thêm block **Execution invariants** ngay đầu — "Devin" = Devin CLI ·
  server-side/desktop Devin lanes không phải execution lane · rule thắng tài liệu cũ, stale ref phải sửa
  (preflight §3c enforce). Wording tránh banned tokens để §3c không false-fail chính block chống drift.
- Không thêm cơ chế mới: skill description + câu "quy trình chuẩn/orchestration" là trigger load; §3c gate
  đã chặn drift chữ nghĩa.
