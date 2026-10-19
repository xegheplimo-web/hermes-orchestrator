# Post-Run Learning Loop — Quality × Speed

Sau mỗi task hoặc wave có ý nghĩa, Hermes phải thực hiện một **selective learning pass** dựa trên evidence thực tế.

Mục tiêu không phải lưu càng nhiều càng tốt.

Mục tiêu là:

> **mỗi vòng sau đạt chất lượng ít nhất bằng vòng trước, nhưng nhanh hơn, ít retry hơn, ít thao tác thừa hơn và ít mắc lại lỗi cũ hơn.**

## 1. Quality × Speed invariant

Hai tiêu chí hàng đầu là:

**QUALITY + SPEED**

nhưng quan hệ giữa chúng là:

**Quality = hard constraint  
Speed = optimization target**

Không dùng weighted score để cho phép tốc độ bù chất lượng.

Ví dụ:

- nhanh hơn nhưng bỏ test → REJECT;
- nhanh hơn nhưng tăng false positive → REJECT;
- nhanh hơn nhưng tăng regression risk → REJECT;
- nhanh hơn nhưng chỉ dựa vào mock thay vì runtime thật → REJECT;
- chất lượng tương đương và nhanh hơn → ADOPT;
- chất lượng tốt hơn và tốc độ tương đương → ADOPT;
- chất lượng tốt hơn và nhanh hơn → STRONG ADOPT;
- chất lượng tốt hơn nhưng chậm hơn đáng kể → phân tích nguyên nhân và tối ưu tiếp, không mặc định coi là workflow tối ưu.

Nguyên tắc:

> **Không bao giờ tối ưu tốc độ bằng cách bỏ qua một bước verification cần thiết.  
> Tối ưu bằng cách làm đúng bước đó thông minh hơn, sớm hơn và ít lặp hơn.**

---

## 2. Evidence capture

Sau mỗi task/wave, chỉ thu những dữ liệu có giá trị cho lần sau.

### Quality evidence

Ghi nhận khi phù hợp:

- acceptance criteria pass/fail;
- defects Hermes phát hiện sau khi Agent báo DONE;
- regression phát sinh;
- test gaps;
- lint/typecheck/build failures;
- integration failures;
- runtime/live-E2E failures;
- CI failures;
- review comments true positive;
- số fix rounds;
- lỗi lọt qua mock nhưng bị runtime bắt;
- lỗi bị phát hiện sau integration.

### Speed evidence

Ghi nhận khi phù hợp:

- total wall time;
- time-to-first-useful-write;
- Agent execution time;
- verification time;
- số retry;
- số lần Agent điều tra lại vấn đề đã biết;
- số tool calls/read/search không cần thiết;
- thời gian do environment/tool failure;
- thời gian do scope không rõ;
- thời gian do prompt thiếu evidence;
- thời gian do duplicate work;
- thời gian từ dispatch → verified green.

Không tối ưu dựa trên cảm giác "có vẻ nhanh".

---

## 3. Root-cause review

Sau khi có evidence, Hermes xác định:

**Điều gì làm chất lượng tăng/giảm?  
Điều gì làm công việc nhanh/chậm?**

Phân loại nguyên nhân:

- PROJECT
- AGENT
- MODEL
- TOOL
- ENVIRONMENT
- ORCHESTRATOR
- PROCESS
- PROMPT
- VERIFICATION
- INTEGRATION

Không lưu triệu chứng nếu root cause chưa được xác nhận.

Ví dụ:

Sai:

> "Cline chạy chậm."

Đúng:

> "Cline mất 18 phút đọc lại 6 file mà task card đã tóm tắt; không có target-file write trong 15 phút. Completion card mang sẵn verified findings giảm vòng sau xuống 7 phút."

Bài học phải chỉ ra **cause → intervention → verified outcome** khi có thể.

---

## 4. Candidate lesson extraction

Chỉ tạo candidate lesson thuộc một trong các nhóm:

1. **Confirmed root cause**
2. **Verified fix**
3. **Effective workflow**
4. **Dead-end to avoid**
5. **Sếp correction**
6. **Agent routing lesson**
7. **Tool/environment quirk**
8. **Verification improvement**
9. **Integration improvement**
10. **Speed improvement without quality regression**

Không lưu:

- speculation;
- unverified Agent explanation;
- one-off noise;
- transient log event;
- incidental timing;
- duplicate lesson;
- finding không thay đổi cách làm tương lai.

---

## 5. Lesson admission gate

Một candidate chỉ được giữ nếu PASS tất cả câu hỏi cần thiết:

### Evidence
- Root cause đã được xác nhận chưa?
- Fix/workflow đã được test hoặc quan sát thực tế chưa?

### Reuse
- Có khả năng xuất hiện lại không?
- Bài học có giúp lần sau ra quyết định tốt hơn không?

### Actionability
- Có thể biến thành hành động cụ thể không?
- Có thể đưa vào prompt, routing, test, guard, preflight, CI hoặc verifier không?

### Quality
- Có giữ hoặc nâng correctness không?
- Có giữ hoặc nâng verification coverage không?
- Có tăng regression/security risk không?

Nếu giảm quality → **REJECT**.

### Speed
- Có giảm wall time, retry, duplicate work, unnecessary reads hoặc unnecessary Agent usage không?
- Hoặc có ngăn một failure tốn thời gian trong tương lai không?

Nếu không cải thiện chất lượng, tốc độ hoặc độ ổn định → **DROP**.

---

## 6. Prefer mechanism over prose

Nếu bài học có thể enforce bằng cơ chế, không chỉ ghi chú nó.

Thứ tự ưu tiên:

**test  
→ verifier  
→ guard  
→ preflight  
→ CI gate  
→ launcher/task-card rule  
→ routing rule  
→ prose lesson**

Ví dụ:

Một lỗi lặp lại:

> "Agent quên chạy integration test."

Không chỉ thêm câu:

> "Hãy nhớ chạy integration test."

Thay bằng:

> Final Verify gate tự kiểm integration test và FAIL nếu thiếu evidence.

Mục tiêu:

> **Một lỗi đã học phải ngày càng khó tái diễn về mặt cơ chế.**

---

## 7. Learning destination

Đưa bài học vào nơi hẹp nhất nhưng đủ dùng.

### Project-local

Nếu chỉ đúng với một project:

→ `.orchestrator/` / project documentation / tests / tooling.

### Agent/tool-specific

Nếu thuộc riêng Devin, Cline, OpenCode, Codemap, browser, Freqtrade...:

→ cập nhật **owning Skill**.

### Lead orchestration

Nếu ảnh hưởng routing, verification, escalation, integration hoặc multi-agent workflow nói chung:

→ cập nhật `lead-orchestrator`.

### Memory

Chỉ dùng Memory khi bài học:

- đúng qua nhiều project;
- có giá trị qua nhiều phiên;
- khó suy lại từ project state;
- không phải implementation detail tạm thời.

Không dùng Memory như event log.

---

## 8. Contradiction and deduplication

Trước khi thêm bài học mới:

1. tìm rule tương tự;
2. kiểm tra có duplicate không;
3. kiểm tra có mâu thuẫn với rule cũ không.

Nếu rule mới chứng minh rule cũ sai:

**REPLACE / MERGE rule cũ.**

Không append cả hai.

Mỗi failure pattern chỉ nên có **một canonical lesson**.

---

## 9. Agent routing learning

Sau mỗi task đáng kể, cập nhật evidence:

```text
Agent
Task type
Difficulty
First-try pass?
Retries
Wall time
Quality defects
Verification defects
Final outcome
```

Dùng dữ liệu này để điều chỉnh routing.

Ví dụ:

> **Pre-D-015 historical lessons** (Cline/OpenCode coding lanes retired in D-015; Devin CLI is sole coding agent). Retained for context.

```text
OpenCode:
docs/tests/light cleanup → nhanh + ổn định

Cline:
medium implementation → tốt
fuzzy architecture → dễ over-explore

Devin CLI:
unknown-root-cause / architecture / hard integration → tốt
light boilerplate → không đáng chi phí/thời gian
```

Không thay routing chỉ vì một lần thành công/thất bại ngẫu nhiên.

---

## 10. Optimize the bottleneck, not the gate

Nếu workflow chậm, xác định thời gian đang mất ở đâu:

```text
Recon
Planning
Agent thinking
Implementation
Retry
Verification
Integration
CI
Environment
```

Sau đó tối ưu bottleneck.

Ví dụ:

Nếu verification chiếm thời gian:

Không bỏ verification.

Thay vào đó:

- dùng CRG để scope test;
- chạy targeted test trước;
- chạy full gate sau;
- reuse verified environment;
- parallelize independent gates;
- cache dependency setup;
- micro-probe trước E2E dài.

Nếu Agent thinking quá lâu:

- cung cấp evidence pack tốt hơn;
- freeze decision trước dispatch;
- dùng write-first deadline;
- route sang Agent phù hợp hơn.

Nếu retry nhiều:

- cải thiện task card;
- đưa root-cause evidence từ lần trước;
- strengthen preflight;
- fix environment trước dispatch.

---

## 11. Quality-speed outcome classification

Sau mỗi meaningful task/wave, Hermes phân loại:

```text
Q↑ S↑  = BEST
Q↑ S→  = GOOD
Q→ S↑  = GOOD
Q→ S→  = ACCEPTABLE
Q↑ S↓  = REVIEW BOTTLENECK
Q↓ S↑  = REJECT
Q↓ S→  = REJECT
Q↓ S↓  = REJECT
```

Trong đó:

- `Q` = verified quality;
- `S` = verified execution speed/efficiency.

**Bất kỳ `Q↓` nào đều không được coi là optimization thành công.**

---

## 12. Post-run questions

Sau mỗi task/wave, Hermes tự trả lời ngắn gọn:

1. **Quality:** Có lỗi nào Hermes bắt được mà Agent bỏ sót?
2. **Speed:** Phần nào tiêu tốn thời gian nhiều nhất?
3. **Cause:** Root cause thật sự là gì?
4. **Reuse:** Điều này có khả năng lặp lại không?
5. **Lesson:** Có bài học nào đủ evidence để giữ?
6. **Mechanism:** Có thể biến bài học thành test/guard/preflight/verifier không?
7. **Routing:** Agent có được giao đúng loại task không?
8. **Contradiction:** Bài học mới có thay thế rule cũ không?
9. **Destination:** Project, owning Skill, lead-orchestrator hay Memory?
10. **Next-round effect:** Lần sau cụ thể sẽ nhanh hơn hoặc chắc hơn ở đâu?

Nếu không có bài học đủ chuẩn:

**ghi nhận "NO REUSABLE LESSON" và không lưu gì.**

Không ép mỗi task phải sinh ra lesson.

---

## 13. Success criteria

Learning loop thành công khi qua nhiều vòng:

- first-pass success rate tăng;
- số retry giảm;
- integration defects giảm;
- lỗi bị phát hiện sớm hơn;
- time-to-first-useful-write giảm;
- time-to-green giảm;
- duplicate investigation giảm;
- Agent routing chính xác hơn;
- số lần cùng một root cause tái diễn giảm;
- quality gates không bị nới lỏng.

Chỉ số quan trọng nhất:

> **cùng một lỗi đã xác nhận không nên tiếp tục xuất hiện vì cùng một nguyên nhân.**

Và nguyên tắc tối cao:

> **Nhanh hơn bằng cách bớt lãng phí, không phải bằng cách bớt kiểm chứng.**

> **Chất lượng không được hy sinh cho tốc độ; tốc độ phải được cải thiện bên trong một quality floor bắt buộc.**

---

## Kit mapping (where each part lives operationally)

- Rules of this loop are executed from the Hermes skill `lead-orchestrator` §22 (Post-Run Learning Loop) + §23 (audit cadence) — the skill holds the condensed operative form.
- §9 routing evidence accumulates in `docs/agent-matrix.md` → *Routing memory* (living table; update at DONE).
- §6 mechanism ladder instantiates through the kit gates: `scripts/preflight.sh` · `scripts/agent-hooks/test-guard.sh` · `scripts/smoke-test.sh` · project CI.
- §2 evidence conventions match `templates/result.json` (agent result contract) + each project's `.orchestrator/VERIFICATION.md` round ledger.

Adopted 2026-10-11 (D-010) — source: Sếp's brief "Post-Run Learning Loop — Quality × Speed"; canonical copy = this file.