Chia sẻ
Bạn đã nói:
Mình đang chạy dự án hermes-orchestrator (kit điều phối multi-agent trên máy Windows). Em cần anh phân tích hiện trạng đã verify và tư vấn phương án hoàn thiện tốt nhất.
Bạn đã nói:
Mình đang chạy dự án hermes-orchestrator (kit điều phối multi-agent trên máy Windows). Em cần anh phân tích hiện trạng đã verify và tư vấn phương án hoàn thiện tốt nhất.

A. SỰ THẬT ĐÃ VERIFY (2026-10-18, output thật):- Kit: commit 78b4163 đã push, remote synced, repo public xegheplimo-web/hermes-orchestrator- 4 lane CLI đều LIVE: cline 3.0.73, opencode 1.18.35, devin 3000.11.3, hermes 0.22.2- Cline lane: -P opencode -m opencode/deepseek-v4.1-flash-free — live probe PONG- OpenCode lane: default deepseek-v4.1-flash-free — PONG- Devin lane: CLI-only, flag --respect-workspace-trust=false (fix 17/10 nằm uncommitted, đã land); doctor 2/2; dry-run canonical- Guard hook: bản live == bản kit IDENTICAL, test 19/19, hooks doctor healthy, log 9316 ALLOW/96 BLOCK- Gates: preflight 14/14, smoke 43/43, guard 19/19, doc-stats 10/10, bootstrap chạy OK trên dir throwaway- Sweep 9 model free qua key mới: 7 solid (deepseek-v4.1-flash-free, beam, longcat-2.5-preview, mimo-v2.6, nemotron-3-ultra, nemotron-3.5-super-vl, space-bunny); glm-5.3 hay 500 transient; nemotron-3.5-lightning flaky (run rỗng)- Control plane: 14/14 task done, D-012 ghi quyết định model resync- CRG MCP enabledB. GAPS CÒN LẠI (đã kiểm chứng):1. Telemetry RUNS.jsonl (skill quy định mỗi run ghi 1 dòng) KHÔNG tồn tại — bootstrap không scaffold file này, kit đang dùng VERIFICATION.md làm ledger thay thế. Rule hiện chỉ là prose.2. verify-doc-refs báo 9 MISSING — phần lớn false-positive: tool không expand biến môi trường kiểu %USERPROFILE% (file thật tồn tại) và URL kiểu devin.ai/... bị tính thành path.3. Devin live run end-to-end chưa chạy (theo thiết kế: quota-billed nên chỉ doctor + dry-run).C. CÂU HỎI:1. RUNS.jsonl: nên scaffold vào bootstrap (~15 dòng) hay chấp nhận VERIFICATION.md làm ledger canonical và sửa skill cho khớp?2. verify-doc-refs false-positive: vá tool (expand %VAR% + skip URL scheme) hay thêm skip-list tại chỗ gọi?3. Model routing: cả cline lẫn opencode cùng dùng deepseek-v4.1-flash-free có hợp lý không, hay nên phân model theo loại task?4. Devin live E2E: có đáng burn 1 quota run để chứng minh lane hard chạy thật end-to-end không?5. Nhìn tổng thể, kit đã đủ tiêu chí hoàn thành chưa, mục tiêu tiếp theo nên là gì?
…
Xem thêm
Đã xử lý trong 4m 42s
ChatGPT đã nói:
Đánh giá Hermes Orchestrator — 18/10/2026

Kết luận: Hermes Orchestrator đã đủ trưởng thành để sử dụng thực tế. Không cần xây lại, không cần thêm agent và chưa cần thêm framework điều phối.

Mình đã đối chiếu báo cáo kiểm chứng với mã nguồn trong repository xegheplimo-web/hermes-orchestrator, bao gồm bootstrap, launcher, preflight, smoke tests, governance, routing matrix, result contract và control plane.

Có một điểm cần phân biệt:

Kit vận hành: đã đủ điều kiện sử dụng hằng ngày theo kết quả kiểm chứng được cung cấp.

Kit hoàn thiện: còn một số vấn đề nhỏ về telemetry, document verification và bằng chứng E2E của Devin.

Hệ thống tự tối ưu: chưa thể coi là hoàn thành khi quy trình học từ kết quả chạy chưa được thực thi và đo lường nhất quán.

1. Đánh giá hiện trạng

Thành phần

	

Bằng chứng

	

Đánh giá




4 CLI lanes

	

Versions, probes, doctor

	

Đạt theo phạm vi từng lane




Model/provider

	

PONG, 7 model ổn trong sweep

	

Đạt cho connectivity




Devin execution

	

Doctor + dry-run

	

Chưa chứng minh live E2E




Guard hook

	

19/19, 9.316 ALLOW, 96 BLOCK

	

Đạt synthetic và vận hành; cần đánh giá false-positive




Preflight

	

14/14

	

Đạt




Smoke test

	

43/43

	

Đạt




Bootstrap

	

Throwaway OK

	

Đạt cho scaffold hiện hành




Control plane

	

14/14 task

	

Đạt workflow được kiểm chứng




Telemetry

	

RUNS.jsonl chưa tồn tại

	

Thiếu




Document verification

	

9 MISSING có false-positive

	

Cần sửa




Learning loop

	

Có policy, thiếu dữ liệu chạy có cấu trúc

	

Chưa đạt đầy đủ

Cần lưu ý: các kết quả PONG xác nhận model/provider hoạt động, chưa chứng minh khả năng sửa code chất lượng cao. Tương tự, 96 lần BLOCK xác nhận hook đã chặn lệnh, nhưng chưa đủ để kết luận cả 96 đều là true-positive.

2. Quyết định số 1 — RUNS.jsonl

Chọn scaffold RUNS.jsonl, không thay thế bằng VERIFICATION.md.

Kiểm tra source cho thấy:

bootstrap-project.sh tạo .orchestrator/, agent_logs/ và các worktree.

VERIFICATION.md ghi bằng chứng kiểm chứng của Hermes.

templates/result.json định nghĩa báo cáo kết quả từ agent.

governance.md yêu cầu thu thập thông tin agent, model, thời gian và retry để audit.

Chưa có một luồng machine-readable thống nhất cho toàn bộ dữ liệu đó.

Vì vậy, hai loại ledger nên có trách nhiệm khác nhau.

Artifact

	

Vai trò




RUNS.jsonl

	

Telemetry có cấu trúc cho mỗi lần thực thi




VERIFICATION.md

	

Bằng chứng và kết luận nghiệm thu của Hermes




agent_logs/*_result.json

	

Báo cáo nhiệm vụ do agent tạo




DECISIONS.md

	

Quyết định kỹ thuật đã được phê duyệt

Không nên tạo hai hệ thống độc lập rồi buộc Hermes nhập dữ liệu trùng lặp.

Phương án triển khai

Giữ đường dẫn .orchestrator/RUNS.jsonl như quy định hiện tại. Bootstrap tạo file rỗng, không ghi đè dữ liệu đã có.

Quan trọng hơn, cần một cơ chế append thực sự, vì tạo file rỗng không giải quyết được quy tắc ghi telemetry.

Mỗi lần chạy CLI nên có run_id duy nhất; Hermes ghi các dữ kiện runtime và bổ sung verdict sau independent verification. Nếu retry cùng task, tạo run mới, không ghi đè run cũ.

Ví dụ một record sau khi run đã được nghiệm thu:

JSON

{
  "schema": "hermes.run.v1",
  "run_id": "T-117-opencode-01",
  "task_id": "T-117",
  "agent": "opencode",
  "model": "opencode/deepseek-v4.1-flash-free",
  "task_type": "small-fix",
  "duration_s": 156,
  "exit_code": 0,
  "provider_failure": false,
  "verify_status": "PASS",
  "retry_index": 0,
  "salvaged": false,
  "verified_by": "hermes"
}


Đây là schema đề xuất, không phải dữ liệu lịch sử đã được xác minh.

Tối thiểu, một run phải có đủ thông tin để trả lời: ai thực thi, dùng model nào, nhiệm vụ gì, tốn bao lâu, lỗi ở đâu và Hermes nghiệm thu thế nào.

Về lưu trữ, tôi khuyên telemetry thô ở trạng thái local/gitignored để tránh commit thay đổi liên tục hoặc vô tình đẩy log nhạy cảm lên GitHub public. Những kết quả và quyết định cần lưu vĩnh viễn vẫn được đưa vào VERIFICATION.md, DECISIONS.md và routing memory.

Acceptance gate: bootstrap idempotent, append một run hợp lệ, retry có run riêng, JSONL parse được toàn bộ, record thiếu trường bắt buộc bị từ chối, không ghi bí mật vào log.

3. Quyết định số 2 — verify-doc-refs

Sửa parser/verifier tại nguồn, không dùng skip-list để che 9 lỗi.

Mình đã đọc trực tiếp scripts/verify-doc-refs.py. Có hai vấn đề đáng xử lý hơn việc thêm vài ngoại lệ.

A. Phân loại sai URL và đường dẫn Windows

Verifier đang xác định một token là path chủ yếu dựa trên ký tự / và phần mở rộng. Cách này có thể nhận nhầm devin.ai/... thành local path.

Với %USERPROFILE%, code hiện tại thực chất đã có logic bỏ qua token chứa %, nhưng bộ trích xuất bare path có thể vẫn lấy một đoạn con của Windows path và kiểm tra sai. Vì vậy, chỉ thêm expandvars() chưa chắc xử lý tận gốc.

Nên phân loại reference trước khi kiểm tra:

Reference

	

Cách xử lý




src/module.py

	

Kiểm tra tồn tại dưới repo roots




%USERPROFILE%\...

	

Nhận diện Windows env path riêng




https://devin.ai/...

	

Nhận diện URL, không kiểm tra như file




devin.ai/...

	

Nhận diện domain-style URL khi đủ chắc chắn




--permission-mode

	

Kiểm tra flag trong source thích hợp




Placeholder/example

	

Skip có kiểm soát

Chỉ expand các biến môi trường được cho phép. Với tài liệu phải chạy được trên nhiều máy, nên phân biệt ENV_UNRESOLVED với MISSING: đường dẫn môi trường chưa xác minh được không đồng nghĩa với đường dẫn repo không tồn tại.

B. Token verification còn có nguy cơ tự xác nhận sai

Đây là phát hiện quan trọng từ source.

Verifier dùng:

Python
Chạy
subprocess.run(
    ["grep", "-rl", "-F", "-e", t, str(root)],
    capture_output=True,
    text=True,
)

Nó tìm token trong toàn bộ cây root, kể cả tài liệu đang được kiểm tra nếu tài liệu nằm trong cây đó.

Hệ quả: một tài liệu viết sai tên flag vẫn có thể PASS chỉ vì chính tài liệu ấy có chứa flag đó.

Nên loại tài liệu đầu vào và các tài liệu prose khỏi tập tìm kiếm token, rồi kiểm tra trên source thực thi, cấu hình hoặc schema có thẩm quyền. Giữ được mục tiêu ban đầu: xác minh bằng code, không xác minh prose bằng prose.

Tôi đề xuất bổ sung test riêng cho verifier:

URL có và không có scheme.

Windows env path, cả trường hợp biến chưa khai báo.

Repo-relative path thật và path sai.

Token chỉ tồn tại trong tài liệu, không tồn tại trong source.

Path có :line và :start-end.

Case trên Git Bash/Windows Python.

Skip ngoại lệ có phạm vi hẹp.

Gate đạt: các false-positive được loại bỏ, nhưng deliberately invalid path/flag vẫn FAIL. Không được lấy số MISSING = 0 làm thành công nếu parser bỏ qua cả lỗi thật.

4. Quyết định số 3 — Model routing

Giữ DeepSeek V4.1 Flash Free làm default cho cả Cline và OpenCode ở thời điểm này. Chưa cần ép hai lane dùng model khác nhau.

Lý do: Cline và OpenCode không đơn thuần là hai tên gọi cho một model. Chúng có cách điều khiển công cụ, xây dựng context, quản lý file và thực thi tác vụ khác nhau.

Cùng một model vẫn có thể cho hiệu quả thực thi khác nhau trên hai CLI.

Tuy nhiên, sử dụng chung model tạo ra rủi ro phụ thuộc vào một upstream. Khi provider bị throttling hoặc outage, cả hai lane có thể đồng thời mất khả năng thực thi.

Routing tôi đề xuất

Lane

	

Model mặc định

	

Định hướng




Hermes

	

Giữ cấu hình đã verify

	

Quyết định, phân công, kiểm chứng




OpenCode

	

DeepSeek V4.1 Flash Free

	

Task nhỏ, test, docs, fix rõ phạm vi




Cline

	

DeepSeek V4.1 Flash Free

	

Feature, integration, module




Devin CLI

	

Model của Devin

	

Task khó, root cause chưa biết, kiến trúc

Các model free khác đã PONG thành công nên được giữ trong standby pool, chưa tự động đưa vào sản xuất.

Không chọn model chỉ vì benchmark chung hoặc cảm giác nó thông minh hơn. Hãy đo trên chính task của Hermes.

Cách chọn model sau khi có telemetry

Quality gate	Acceptance pass, regression và defect sau review
Reliability	Timeout, 500, 429, output rỗng, crash
Speed	Wall time đến verified green
Efficiency	Retry, escalation và mức sử dụng quota

Điểm cần sửa thêm trong routing: phân biệt lỗi provider và lỗi năng lực agent.

Ví dụ, DeepSeek trả 500 không nên được tính như OpenCode thất bại trong việc lập trình. Khi có lỗi hạ tầng, thử fallback đã kiểm chứng trong cùng lane trước khi dùng quy tắc escalation theo độ khó.

Fallback phải bảo đảm không có hai tiến trình cùng sửa một worktree sau một lần timeout.

Sau khoảng 10–20 task có phân loại rõ, Hermes có thể xem lại routing matrix. Những mẫu nhỏ hơn vẫn hữu ích để phát hiện lỗi nghiêm trọng nhưng chưa đủ để xếp hạng chất lượng model một cách đáng tin.

5. Quyết định số 4 — Devin live E2E

Có đáng chi một quota run không? Có, nhưng phải là một canary tạo ra giá trị thực tế, không phải một lượt PONG đắt tiền.

Hiện tại, Devin đã chứng minh CLI tồn tại, tham số được chấp nhận và doctor hoạt động. Chưa chứng minh một lệnh thực thi hoàn chỉnh từ prompt đến sản phẩm được Hermes nghiệm thu trên cấu hình mới.

Tôi sẽ dùng một canary như sau:

Devin Hard-Lane Canary

Chưa thực thi

Nhiệm vụ: xử lý lỗi đã được ghi nhận trong agent matrix: MSYS timeout kết thúc wrapper nhưng có thể để tiến trình CLI native sống tiếp.

Phạm vi: worktree riêng, chỉ dùng dummy child process thuộc phép thử; không động đến desktop app, VPS, secret hoặc tiến trình ngoài task.

Chuỗi nghiệm thu:

Devin đọc source và xác định root cause.
Đưa ra bản sửa nhỏ nhất có thể bảo trì.
Bổ sung regression test chạy trên Windows.
Hermes độc lập thử timeout và kiểm tra không còn orphan process của canary.
Hermes chạy smoke, diff review và tích hợp nếu tất cả PASS.

Giới hạn một lần dispatch có ngân sách được duyệt. Nếu gặp lỗi quota/provider, lưu evidence và không tự động chạy lại.

Đây là phép thử phù hợp vì nó kiểm chứng đồng thời Devin CLI và giải quyết một sự cố Windows thực tế của kit.

Một canary PASS sẽ chứng minh lane hard có thể hoàn thành ít nhất một nhiệm vụ E2E trên cấu hình hiện tại. Nó không chứng minh Devin sẽ hoàn thành mọi loại nhiệm vụ khó.

6. Tôi phát hiện thêm hai khoảng trống cần chú ý
A. Log có nguy cơ mất khi cleanup worktree

Trong launch-agent.sh, đường dẫn log mặc định là:

Bash
LOG="$WORKDIR/agent_logs/$TITLE.log"

Nhưng bootstrap đã tạo thư mục _logs ở worktrees root. Khi Hermes xóa worktree sau merge, log nằm bên trong worktree cũng có nguy cơ bị xóa.

Ngoài ra, hai lần chạy cùng một TITLE có thể dùng lại tên log.

Tôi khuyên chuyển log sang vị trí bền vững:

Văn bản thuần túy
my-project-worktrees/
  _logs/
    T-117-opencode-01.log
    T-117-opencode-02.log
    T-118-cline-01.log

Giữ --log override như hiện tại. Không cần thêm log server hoặc database.

B. Guard hook chưa nên được coi là sandbox bảo vệ toàn bộ CLI

Theo governance, hook hiện gắn vào pre_tool_call của Hermes với matcher terminal, và dùng chế độ fail-open.

Điều đó không tự động chứng minh rằng các command do Devin, Cline hoặc OpenCode chạy bên trong tiến trình riêng cũng đi qua cùng hook.

Mặt khác, launcher hiện dùng --permission-mode dangerous cho Devin. Git worktree chỉ cô lập thay đổi Git, không phải ranh giới bảo mật hệ điều hành.

Vì vậy, cần một kiểm chứng riêng về phạm vi áp dụng guard và quyền thực tế của delegated agents. Nếu các CLI không đi qua guard, đừng tuyên bố guard đang bảo vệ chúng.

Trước mắt, với nhiệm vụ rủi ro cao, nên giữ workspace giới hạn, không cấp secret không cần thiết, không cho phép thao tác ngoài scope và yêu cầu phê duyệt với hành động có tác động lớn.

Đây là việc cần xác nhận trước khi nâng mức tự chủ của Hermes.

7. Roadmap tối ưu để đóng dự án

P0 — Runtime evidence

Scaffold RUNS.jsonl, bổ sung append writer tối thiểu, run_id, giữ log qua cleanup và kiểm thử retry. Đảm bảo không có telemetry bị nhập trùng thủ công.

Giao OpenCode phần scaffold/test, Cline phần tích hợp launcher nếu cần.

P1 — Verification correctness

Sửa verify-doc-refs.py ở tầng parser, tránh self-matching token, thêm regression test và kiểm tra lại chín trường hợp MISSING.

Giao OpenCode hoặc Cline tùy scope; Hermes xác minh các false-positive và false-negative.

P2 — Runtime safety & hard lane

Xác nhận giới hạn guard, xử lý process cleanup và thực hiện một Devin E2E canary có kiểm soát.

Hermes chịu trách nhiệm boundaries và independent verification; Devin chỉ thực thi nhiệm vụ khó được giao.

P3 — Data-driven learning

Sau các task vận hành tiếp theo, tổng hợp first-pass success, retry, thời gian, chất lượng review và failure mode để tối ưu routing thực sự.

Giữ DeepSeek làm default đến khi số liệu task-level chứng minh cần thay đổi.
Tiêu chuẩn chốt hoàn thành

Tôi sẽ không yêu cầu làm thêm vô hạn. Chỉ cần đạt các điều kiện sau:

Gate cuối

	

Điều kiện đạt




Existing regression

	

Preflight, smoke, guard, doc-stats tiếp tục PASS




Telemetry

	

Run thật và retry được ghi chính xác, có thể đọc và thống kê




Log retention

	

Log không mất sau worktree cleanup




Doc verification

	

Không còn false-positive đã biết; lỗi thật vẫn bị bắt




Hard lane

	

Một Devin E2E được Hermes nghiệm thu hoặc công bố rõ là chưa verify




Safety scope

	

Phân biệt được bảo vệ của Hermes hook với quyền CLI con




Integration

	

Clean diff, không secret, không regression, remote đồng bộ

8. Quyết định cuối cùng
Hermes Orchestrator
Operational ready

Đủ dùng ngay: Có.

Đủ để đóng toàn bộ hạng mục hoàn thiện: Chưa, nhưng phần còn lại nhỏ và có thể kiểm chứng rõ ràng.

Cần nâng cấp lớn: Không.

Ưu tiên cao nhất: hoàn thiện đường đi của evidence, từ agent run đến verification, telemetry và learning loop.

Tôi đặc biệt không khuyên bổ sung agent-router, model router bằng LLM, database telemetry, dashboard mới hoặc planner thứ hai. Các thành phần đó chưa giải quyết bottleneck đã được chứng minh.

Sau khi đóng P0–P2, mục tiêu tiếp theo nên là chuyển Hermes từ “kit có đầy đủ quy tắc điều phối” thành “kit có khả năng đo chất lượng điều phối và tự điều chỉnh dựa trên evidence đã verify”. Đó là bước nâng cấp có giá trị nhất, đồng thời giữ được kiến trúc Windows CLI hiện tại gọn, dễ sửa và ổn định.

ChatGPT có thể mắc lỗi. Hãy kiểm tra thông tin quan trọng.
Phản hồi mới nhất




Cao