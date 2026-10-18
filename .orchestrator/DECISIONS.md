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

## D-010 (2026-10-11) — Post-Run Learning Loop — Quality × Speed → canonical (T-116)

- Spec Sếp ("Post-Run Learning Loop — Quality × Speed") = loop chuẩn: sau mỗi task/wave có ý nghĩa →
  selective learning pass trên evidence thật: evidence capture → root-cause classification →
  candidate lesson → admission gate (evidence · reuse · actionability · quality · speed) →
  mechanism-over-prose (test → verifier → guard → preflight → CI gate → rule) → destination hẹp nhất
  (project → owning skill → lead-orchestrator → memory) → Q/S classification (mọi Q↓ = REJECT).
- Canonical doc: `docs/post-run-learning-loop.md` (giữ nguyên văn spec, chỉ sửa format + Kit mapping);
  bản vận hành gọn: skill `lead-orchestrator` **v1.6.0** §22–§23 — §22 cũ được REPLACE (không stack).
  Routing evidence tiếp tục tích ở `docs/agent-matrix.md` → Routing memory.
- Kèm trong vòng: §3c gate bắt drift `Devin MCP` trong §2 Execution invariants (câu cấm chứa token
  cấm → gate tự fail) → reword `Devin via MCP`; bài học: wording của rule chống drift cũng phải
  tránh token (xem VERIFICATION T-116).

## D-012 (2026-10-18) — Lane-model resync: cline + opencode → `opencode/deepseek-v4.1-flash-free`; devin flag `=false` landed (T-117)

- Audit nhất quán toàn kit phát hiện 2 drift: (1) fix devin `--respect-workspace-trust=false`
  (17/10, optional-value flag — form space làm `--permission-mode` mất hiệu lực) nằm uncommitted →
  preflight §2 + smoke §4 expect form cũ → 2 gate FAIL; (2) opencode default
  `muse-spark-1.3-contributor-free` đã chết khỏi catalog (drift §21).
- **Cline lane**: `-P opencode` (KHÔNG phải `opencode-go` — hai catalog khác nhau; qua
  `opencode-go`, deepseek trả "Model access is disabled", `…-free` không tồn tại) +
  `-m opencode/deepseek-v4.1-flash-free`. Live-probe 5 tên: chỉ model này + `longcat-2.5-preview-free`
  + `beam-free` qua provider tương ứng trả PONG.
- **OpenCode lane**: default → `opencode/deepseek-v4.1-flash-free` (PONG).
- Evidence: PREFLIGHT 14/14 · SMOKE 43/43 · GUARD 19/19 · live probe qua launcher thật EXIT=0/PONG.
  Gates verify trước/sau — drift cũ 13/1 + 42/1 → 14/0 + 43/0.

## D-014 (2026-10-18) — P0 DONE: runtime evidence + log retention (T-119, OpenCode lane)

- **RUNS.jsonl**: bootstrap scaffold non-destructive; `scripts/record-run.py` append `hermes.run.v1`
  (validate required fields, dedupe `run_id`, retry = run mới, tool không tự sửa verdict);
  Hermes là bên ghi verdict cuối. Raw telemetry gitignored (repo public).
- **Log retention**: launcher default log → `<worktrees-root>/_logs/<title>-<timestamp>.log`
  (ngoài task worktree, unique per attempt); `--log` override giữ nguyên; fallback
  `<workdir>/agent_logs/` khi không có sibling `_logs/` (dispatch thẳng project root).
- **Evidence thật**: 3 run đầu tiên ghi vào RUNS.jsonl — T-119-opencode-01/02 fail do provider
  500 (deepseek-v4.1-flash-free, provider_failure=true, retry_index 0/1), T-119-opencode-03
  beam-free PASS (retry_index 2). Gates: smoke 67/67, preflight 14/14, guard 19/19.
- **Routing lesson (verified)**: opencode lane deepseek fail 2/2 với "Internal Server Error" →
  escalate standby pool `opencode/beam-free` → PASS. Đúng routing matrix §8 (provider 5xx ≠
  agent failure; retry 1 lần, fail lần 2 → standby cùng lane).
- **Deviations từ task card**: agent không commit trong worktree — Hermes review diff, fix
  2 điểm integration (launcher fallback `_logs`, README count 43→67), commit + merge.
- **Ngoài scope (ghi nhận, không sửa)**: MSYS path — record-run.py nhận native path
  (`cygpath -m`) khi gọi từ git-bash; smoke test đã dùng đúng pattern. Docs không cần đổi vì
  production caller (Hermes) dùng native path.

## D-013 (2026-10-18) — ChatGPT architect review (thread 6ad473ee) → roadmap P0–P3 (T-118)

- Brief gửi: §A facts verified (gates 14/14 · 43/43 · 19/19 · sweep model · lane resync D-012) +
  §B 3 gaps + 5 cross-questions. Full reply: `docs/design/chatgpt-6ad473ee-reply-20261018.md`.
- **Verdict ChatGPT**: kit operational-ready ("đủ dùng ngay"), chưa hoàn thiện về telemetry /
  doc-verification / Devin E2E evidence; KHÔNG cần agent-router / model-router LLM / DB telemetry /
  dashboard — đúng hướng minimal của kit.
- Quyết định adopt (Hermes đã verify từng claim trên source trước khi adopt):
  1. **RUNS.jsonl**: scaffold vào bootstrap + append writer thật (run_id duy nhất; retry = run mới,
     không ghi đè). VERIFICATION.md giữ vai trò ledger nghiệm thu — hai ledger khác trách nhiệm.
     Telemetry raw local/gitignored (repo public — không đẩy log lên GitHub).
  2. **verify-doc-refs**: sửa PARSER tại nguồn (phân loại URL / %VAR% Windows path / flag / placeholder;
     expandvars chỉ biến được phép; ENV_UNRESOLVED ≠ MISSING) + loại self-matching (doc đang check
     phải nằm ngoài tập token search) + regression test cho verifier. KHÔNG skip-list che lỗi.
     *(Hermes verify: grep -rl -F -e root search cả doc — self-match thật; line 54 skip `%` nhưng
     bare-path extractor vẫn bắt substring — đúng mechanism 9 MISSING.)*
  3. **Model routing**: giữ deepseek-v4.1-flash-free cả 2 lane (verify: PONG); 7 model solid khác
     → standby pool, chưa auto-production; chọn model sau khi có telemetry task-level (≥10–20 task).
  4. **Devin E2E**: ĐÁNG burn 1 quota canary — nhưng phải là canary giải quyết bug thật (đề xuất:
     MSYS wrapper-timeout orphan process trong agent-matrix), scope worktree riêng + dummy child,
     acceptance chain 5 bước, 1 dispatch duy nhất.
- **2 gaps ChatGPT phát hiện thêm** (Hermes verify từng cái):
  A. Log retention: `launch-agent.sh` default log `<workdir>/agent_logs/` → mất khi cleanup
     worktree. Bootstrap đã có `_logs/` ở worktrees root — cần chuyển default + keep `--log` override.
  B. Guard scope: hook chỉ gắn `pre_tool_call` của Hermes (fail-open) — KHÔNG tự động chứng minh
     CLI con (devin/cline/opencode) đi qua guard. Cần verify scope trước khi tuyên bố "guard bảo vệ
     delegated agents". *(Hermes verify: governance.md line 19 — pre_tool_call matcher terminal ✓;
     devin chạy `--permission-mode dangerous` trong process riêng ✓.)*
- **Roadmap**: P0 runtime evidence (RUNS.jsonl + log retention + retry test) → P1 verification
  correctness (verify-doc-refs parser + regression) → P2 safety + Devin canary → P3 data-driven
  learning. Mục tiêu cuối: kit đo được chất lượng điều phối, tự điều chỉnh trên verified evidence.
- Routing P0: OpenCode (scaffold/test) + Cline (launcher integration nếu cần) — theo agent-matrix.

## D-011 (2026-10-11) — Bản core operating brief mới (brief Sếp 11-10) → docs/prompt-core-2026-10-11.md

- Sếp soạn bản core vận hành "vừa" (219 dòng): Recon-first + thứ tự ưu tiên (Correctness & Quality →
  Stability → Simplicity → Speed → Reuse → Low Dependency → Cost Efficiency) + quy trình 10 bước +
  agent execution invariants + code intelligence + verification invariant + fix/escalation + parallelism +
  git/integration + selective learning + decision rule + Tags/related skills + Definition of DONE.
- Đối chiếu skill `lead-orchestrator` v1.7.1: cover toàn bộ nội dung; gap duy nhất đã bổ sung — §1.3
  thêm `maintainable` + `reversible` vào chuỗi chọn giải pháp.
- Quyết định: PROMPT.md giữ nguyên (D-009 còn hiệu lực — prompt ngắn, skill canonical); bản mới lưu docs
  làm tham chiếu. Nếu Sếp chốt dùng làm prompt chính → cập nhật PROMPT.md + D thay thế D-009.
- Reword bắt buộc khi lưu: tên lane cũ → `Devin via MCP` (tránh token cấm — preflight §3c).
