# Skill Governance — Crosscheck GPT "Auto Skill Manager" + quyết định cuối

**Date:** 2026-10-22
**Channel:** ChatGPT thread `6ad93fe9-3a84-83ec-a5c1-371f02f635fc` ("Nâng cấp Hermes tự động")
**Owner:** Hermes Lead Orchestrator (em) · **Authority:** Sésép trao toàn quyền thiết lập + verify
**Hermes version:** v0.22.4 (build 22/09/2026) · `hermes update --check` → "Up to date with v0.22.4 (4d04303818b6)"

---

## 1. GPT đề xuất (óm tắt)
- Nâng cấp native skill lifecycle + Curator + policy gate trong Orchestrator.
- Config: `skills.guard_agent_created: true`, `skills.write_approval: true`, `curator.stale_after_days: 60`, `curator.archive_after_days: 180`.
- Viết một "Capability Policy Gate" mới trong Orchestrator.

## 2. Verified facts (repo thật)
| Hạng mục | Giá trị thật | Nguồn |
|---|---|---|
| Phiên bản | v0.22.4, build 22/09/2026 | `hermes --version` |
| Cập nhật | Up to date (4d04303818b6) | `hermes update --check` |
| Native lifecycle | skill_view / skills search+install+update+audit+check+list-modified+diff+opt-out+opt-in+reset+repair-official | `hermes skills --help` |
| Curator | enabled, mỗi 7d, stale=14d, archive=30d, consolidate=off, prune_builtins=off | `hermes curator status` |
| Curator scope | bundled+hub **never touched**; managed=12, unmanaged=25 | `curator --help` + `list-unmanaged` |
| Bundled modified giữ | 7 (blocked-page-recovery, codex, email-inbox-triage, github, hermes-agent, hermes-agent-skill-authoring, opencode) | `hermes skills list-modified` |

## 3. GPT đúng (4)
1. Native skill lifecycle đã tồn tại.
2. `hermes skills audit` + `curator {status,ledger,list-unmanaged}` có thật, chạy được.
3. Curator bảo vệ bundled/hub (never-touch) + 25 skill unmanaged là thật.
4. 7 bundled user-modified được giữ qua update.

## 4. GPT sai (3) + điểm HỎNG khi chạy thật (1)
| # | Claim GPT | Thực tế (verified) |
|---|---|---|
| 1 | "v0.22.4 released 21/10/2026" | Sai — build 22/09/2026; không có ngày 21/10 |
| 2 | "14→60, 30→180 = bảo thủ" | Nhầm lẽ — 14/30 = ship default; nới ra = giữ lâu hơn (ít bảo thủ hơn); 0 stale/0 archived ⇒ vô hiệu, chỉ churn |
| 3 | "Capability Policy Gate mới trong Orchestrator" | Trùng — đã ở lead-orchestrator §22 (destination project→owning skill→this skill→memory) + system prompt; viết lại = duplication |
| **4** | **`skills.guard_agent_created: true` (bảo thủ, an toàn)** | **HỎNG khi chạy thật** — xem §5 |

## 5. Điểm sai #4 — BẰNG CHỨNG CHẠY THẬT (quyết định rollback)
Bật `guard_agent_created=true`, rồi gọi trực tiếp hàm gate `_security_scan_skill` (`tools/skill_manager_tool.py:50`) lên 6 skill thật + 2 control:

| Đối tượng | Kết quả gate |
|---|---|
| browser-control, lead-orchestrator, devin-cli, codex, reverse-engineer-anything | ✅ ALLOW |
| **hermes-self-upgrade** | ❌ **BLOCK** — verdict `DANGEROUS`, pattern `env_exfil_curl`, `SKILL.md:52` |
| CONTROL (`curl ${API_TOKEN}` + `rm -rf /` + injection) | ✅ BLOCK (đúng) |
| CONTROL safe | ✅ ALLOW (đúng) |

**Nguyên nhân false positive:** `SKILL.md:52` chứa probe hợp lệ
`curl -H "Authorization: Bearer $OPENCODE_GO_API_KEY" https://opencode.ai/zen/go/v1/chat/completions`
→ regex `env_exfil_curl` coi **mọi** `$..._KEY` trong curl là exfiltration (critical).

**Hậu quả:** guard ON ⇒ mọi `skill_manage` write vào `hermes-self-upgrade` bị chặn ("ask") ⇒ **self-upgrade sweep không patch được lesson vào chính skill đó ⇒ phá learning loop**. Không có cơ chế allowlist.

## 6. Quyết định cuối (đã thi hành + verify)
| Config | Giá trị | Trạng thái |
|---|---|---|
| `skills.guard_agent_created` | **false** | ✅ đã rollback (smoke test chứng minh) |
| `skills.write_approval` | **false** | ✅ giữ (bật = phá "sweep toàn quyền tự quyết/tự cài đặt"; staging + đòi `/skills approve`) |
| `curator.*` | default 14/30, off, off | ✅ giữ (không churn) |

Verify lệnh:
```
hermes config get skills   # guard_agent_created: false, write_approval: false
hermes config get curator  # enabled: true, stale 14d, archive 30d, consolidate off, prune_builtins off
```
Backup: `~/.hermes/config.yaml.bak-20261022-055828`

## 7. Phát hiện ngoài scope (báo Sésép, không tự sửa)
- `hermes fallback list` hiện **2 entry** (primary `poolside/laguna-s-2.1:free`, fallback `meituan/longcat-2.5-preview:free`) — khác frozen convention 5 entry với primary `opencode-go/deepseek-flash`. Model = quyết định của Sésép (rule "Đổi model fallback = quyết định Sếp") → chỉ báo.

## 8. Status
- [x] Recon repo (version, skills, curator, gates)
- [x] Verify từng claim GPT
- [x] Smoke test gate trên skill thật → rollback guard
- [x] Gửi crosscheck + quyết định vào thread GPT
- [x] Persist doc này
- [x] Ghi lesson vào `hermes-self-upgrade`
- [x] GPT reply — **CHẤP NHẬN** (`gpt-reply-2026-10-22.md`); rút 3 đề xuất cũ (bật guard ngay / đổi ngưỡng Curator / Capability Policy Gate)

## 9. GPT verdict (2026-10-22, thread `6ad93fe9…`)
| Hạng mục | GPT verdict |
|---|---|
| guard=false / write_approval=false / Curator 14-30 | **APPROVED** |
| Capability Policy Gate | **rút** (trùng §22) |
| Guard patch | **CONDITIONAL** — chỉ làm nếu muốn bật lại; cần finding-level allowlist + integration test trên bản sao skill |
| Fallback 2/5 | **REPORTED** — không tự đổi model |
| Báo cáo upstream | GPT phát hiện thêm: scanner exception → **fail-open** (`skill_manager_tool.py`) — đáng gửi Nous |

**Next-step đề xuất (chưa làm — chờ Sésép quyết):** guard vẫn giữ OFF (false positive dormant, không gấp). Nếu muốn bật lại: triển khai finding-level exception allowlist theo thiết kế GPT + ma trận 11 test (giao Devin CLI), hoặc gửi báo cáo upstream (Nous) kèm repro + lỗi fail-open.
