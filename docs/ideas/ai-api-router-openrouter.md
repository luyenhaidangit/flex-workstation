# AI API Router — Cổng định tuyến LLM trên nền OpenRouter

> Tách ra từ method **B4. Smart API Routing** trong `docs/ideas/mmo-2026-07-21.md`. Đây là bản đề xuất idea độc lập cho hướng triển khai dùng **OpenRouter** làm nền.

## Problem Statement

Người dùng API LLM (SME, freelancer, team nhỏ) đang trả nhiều tiền hơn cần thiết vì gọi cứng một model đắt cho mọi tác vụ, và phải tự xử lý fallback khi model lỗi/quá tải. Làm thế nào để có một lớp trung gian định tuyến mỗi request sang model rẻ nhất còn đủ chất lượng — mà không phải tự tích hợp và bảo trì hàng chục nhà cung cấp?

## Recommended Direction

Xây một **cổng định tuyến (router gateway)** đứng trước OpenRouter: client gọi vào một endpoint OpenAI-compatible duy nhất, router phân loại tác vụ và chọn model phù hợp qua OpenRouter, có fallback và trần chi phí. OpenRouter lo phần "một API — nhiều nhà cung cấp"; giá trị mình thêm vào là **policy định tuyến + kiểm soát chi phí + quan sát được**, không phải tự nối từng provider.

Vì sao dựa trên OpenRouter thay vì tự nối provider:

- **Một API chuẩn OpenAI-compatible** cho hàng trăm model — bỏ được phần tích hợp và bảo trì tốn công nhất.
- **Fallback/định tuyến sẵn có** ở tầng nhà cung cấp; mình chồng thêm policy theo tác vụ và ngân sách.
- **Ship nhanh**: MVP là một reverse proxy mỏng + bảng luật, không phải một hệ tích hợp lớn.
- **Đúng tinh thần B4**: "middleware định tuyến sang model rẻ nhất phù hợp" — OpenRouter là backbone tự nhiên.

Đánh đổi phải chấp nhận: phụ thuộc một vendor (giá, uptime, danh mục model do OpenRouter quyết định) và có thêm một hop độ trễ. Cả hai đưa vào Open Questions / Assumptions để đo trước khi cam kết.

Ba lớp giá trị, xếp chồng theo độ khó:

| Lớp | Nội dung | Giá trị thêm so với gọi thẳng OpenRouter |
| --- | --- | --- |
| 1. Passthrough + đo | Proxy OpenAI-compatible qua OpenRouter, log token/chi phí mỗi request, dashboard | Quan sát được chi tiêu, không đổi code client |
| 2. Định tuyến theo luật | Phân loại tác vụ (đơn giản/suy luận sâu/code…) → chọn tier model theo bảng luật cấu hình được | Giảm chi phí thực tế, có fallback theo policy |
| 3. Kiểm soát & tối ưu | Trần ngân sách theo key/tenant, cache câu lặp, A/B chất lượng vs giá | Tránh vượt chi, tối ưu liên tục |

## Key Assumptions to Validate

- [ ] Định tuyến "rẻ hơn mà đủ tốt" tiết kiệm thật — đo bằng bộ tác vụ mẫu, so chi phí router vs gọi cứng một model, kèm điểm chất lượng
- [ ] Độ trễ thêm do một hop router chấp nhận được (đo p50/p95 so với gọi thẳng OpenRouter)
- [ ] Điều khoản OpenRouter cho phép mô hình proxy/bán lại dịch vụ — đọc ToS trước khi tính thương mại hóa
- [ ] Có người sẵn sàng trả cho "kiểm soát chi phí + định tuyến" thay vì tự gọi OpenRouter — xác thực bằng 3–5 phỏng vấn trước khi build lớp 2
- [ ] Rủi ro phụ thuộc một vendor ở mức chấp nhận — thiết kế lớp abstraction để sau này cắm thêm provider khác nếu cần

## MVP Scope (Lớp 1 + phần đầu Lớp 2)

**In:**

- Endpoint OpenAI-compatible (`/v1/chat/completions`) proxy thẳng qua OpenRouter
- Ghi log mỗi request: model đã dùng, token in/out, chi phí ước tính, độ trễ
- Bảng luật định tuyến tối thiểu: map "loại tác vụ → tier model" cấu hình bằng file, 2–3 tier (rẻ / cân bằng / mạnh)
- Fallback khi model chọn lỗi/timeout sang model dự phòng cùng tier
- Dashboard đơn giản: chi phí theo ngày, phân bố model, tỷ lệ fallback

**Out (MVP):** trần ngân sách per-tenant, caching, A/B chất lượng tự động, phân loại tác vụ bằng ML (MVP dùng luật/heuristic), multi-provider ngoài OpenRouter, UI cấu hình luật (MVP sửa file).

## Not Doing (and Why)

- **Tự tích hợp trực tiếp từng provider (OpenAI, Anthropic, DeepSeek…)** — đó chính là việc OpenRouter đã làm; tự nối lại là phá bỏ lý do chọn nền này. Chỉ cân nhắc khi Assumption phụ-thuộc-vendor thất bại.
- **Train/fine-tune model riêng** — ngoài phạm vi, không phải bài toán của một lớp định tuyến.
- **Phân loại tác vụ bằng ML từ ngày 1** — heuristic/luật đủ để chứng minh giá trị; ML chỉ thêm khi có dữ liệu và luật chạm trần.
- **Lưu nội dung prompt/response của người dùng** — chỉ log metadata (token, chi phí, model); tránh rủi ro dữ liệu nhạy cảm và pháp lý.

## Open Questions

- Vị trí trong workspace: repo con độc lập theo `workstation.json`, hay một service trong dự án đã có?
- Tech stack: tận dụng nền .NET quen thuộc, hay một stack nhẹ hơn cho reverse proxy (mục tiêu nghiêng về học hay ship nhanh)?
- Mô hình dùng: **nội bộ** (chỉ để mình/team kiểm soát chi phí — bỏ qua ToS bán lại) hay **thương mại** (bán dịch vụ — phải kiểm điều khoản OpenRouter trước)?
- Đo chất lượng định tuyến bằng cách nào: bộ tác vụ vàng tự chấm, hay LLM-as-judge? (nếu judge thì dùng model nào để tránh thiên vị)
- Ranh giới với method B4 gốc trong `mmo-2026-07-21.md`: idea này thay thế, hay là bản triển khai chi tiết của B4?
