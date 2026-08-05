# Đặc tả tính năng: Khôi phục hạ tầng lõi AI (Ollama)

**Branch**: `000027-restore-ollama-core`
**Ngày tạo**: 2026-08-05
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Khôi phục lại hạ tầng lõi chạy AI cục bộ bằng Ollama (model `qwen2.5:1.5b`) trong môi trường phát triển — pattern triển khai đã có từ trước nhưng hiện đang bị comment/vô hiệu hóa.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hạ tầng chạy mô hình AI cục bộ (Ollama) từng được triển khai trong môi trường phát triển (`flex-environment`) nhưng hiện đang bị vô hiệu hóa: định nghĩa dịch vụ trong Docker Compose bị comment, cấu hình định tuyến qua reverse proxy bị tắt, và dịch vụ chỉ còn tồn tại dưới dạng bản sao lưu trữ ngoài stack đang chạy. Kết quả là bất kỳ tính năng nào cần khả năng AI cục bộ (chatbot, trợ lý, RAG) đều không có runtime để hoạt động, kể cả khi đã có cấu hình sẵn sàng để kết nối tới nó. Việc này chặn toàn bộ các sáng kiến AI tiếp theo (ví dụ nền tảng AI Agent) vì chưa có nền tảng lõi để xây dựng lên.

**Tổng quan tính năng**:

Khôi phục lại hạ tầng lõi chạy mô hình AI cục bộ bằng Ollama, sử dụng mô hình `qwen2.5:1.5b`, để dịch vụ này hoạt động ổn định, có thể truy cập được bởi các dịch vụ nội bộ khác trong môi trường phát triển, và sẵn sàng làm nền tảng cho các tính năng AI hiện tại và tương lai. Đây là công việc bật lại hạ tầng đã có pattern triển khai trước đó, không phải xây mới, và không bao gồm việc xây dựng sản phẩm/tính năng AI cụ thể nào.

---

## 2. Mục tiêu

- **MT-001**: Đội ngũ kỹ thuật có một dịch vụ AI cục bộ (Ollama) chạy ổn định trong môi trường phát triển, sẵn sàng phục vụ yêu cầu suy luận (inference) từ các dịch vụ khác.
- **MT-002**: Mô hình `qwen2.5:1.5b` được nạp sẵn và sử dụng được ngay khi dịch vụ khởi động, không cần thao tác thủ công bổ sung.
- **MT-003**: Các dịch vụ nội bộ đã có cấu hình trỏ tới Ollama (ví dụ `flex-ai-gateway`) kết nối và nhận phản hồi thành công mà không cần thay đổi cấu hình của chính chúng.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Bật lại dịch vụ chạy mô hình AI cục bộ (Ollama) trong stack hạ tầng phát triển, khôi phục từ pattern đã comment/lưu trữ trước đó.
- **MVP-002**: Đảm bảo mô hình `qwen2.5:1.5b` được tự động nạp khi dịch vụ khởi động lần đầu.
- **MVP-003**: Khôi phục đường định tuyến nội bộ (routing) để các dịch vụ khác trong môi trường phát triển gọi được tới dịch vụ AI này bằng địa chỉ nội bộ đã quy ước trước đó.
- **MVP-004**: Giới hạn MVP: chỉ khôi phục hạ tầng lõi (runtime model + routing). Không bao gồm việc bật lại vector database (Qdrant), không xây dựng hoặc sửa logic nghiệp vụ của `flex-ai-gateway` hay bất kỳ tính năng sản phẩm AI nào (ví dụ nền tảng AI Agent) — các phần đó thuộc phạm vi các spec khác.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Kỹ sư phát triển và vận hành nội bộ của đội Flex — người cần môi trường phát triển có sẵn khả năng AI cục bộ để xây dựng và kiểm thử các tính năng phụ thuộc vào nó.

**Bối cảnh sử dụng**: Trong quá trình phát triển local hoặc môi trường dev dùng chung, khi cần một dịch vụ nào đó (chatbot, agent, tính năng gợi ý...) gọi tới mô hình AI để lấy phản hồi.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật (đội ngũ phát triển/vận hành nội bộ).

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khởi động môi trường dev có sẵn dịch vụ AI cục bộ (Ưu tiên: P1)

Một kỹ sư khởi động môi trường phát triển (`flex-environment`) như thường lệ. Sau khi khởi động xong, dịch vụ AI cục bộ tự động chạy và đã có sẵn mô hình `qwen2.5:1.5b`, không cần thêm bước thủ công nào để tải mô hình.

**Lý do ưu tiên**: Đây là điều kiện tiên quyết để bất kỳ tính năng AI nào khác có thể được phát triển hoặc kiểm thử.

**Liên quan yêu cầu**: FR-001, FR-002

**Test độc lập**: Khởi động lại toàn bộ stack hạ tầng từ đầu (clean state) và xác nhận dịch vụ AI cục bộ ở trạng thái sẵn sàng với mô hình đã nạp mà không cần can thiệp thủ công.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** stack hạ tầng phát triển chưa từng chạy dịch vụ AI (clean state), **Khi** kỹ sư khởi động stack, **Thì** dịch vụ AI cục bộ khởi động thành công và mô hình `qwen2.5:1.5b` sẵn sàng nhận yêu cầu mà không cần thao tác thủ công thêm.
2. **AC-002**: **Cho trước** dịch vụ AI cục bộ đang chạy, **Khi** kỹ sư khởi động lại stack (restart), **Thì** dịch vụ khởi động lại thành công và giữ nguyên mô hình đã nạp mà không cần tải lại từ đầu.

---

### US-002 — Dịch vụ nội bộ khác gọi tới AI cục bộ qua cấu hình sẵn có (Ưu tiên: P1)

Một dịch vụ nội bộ đã có sẵn cấu hình trỏ tới dịch vụ AI cục bộ (ví dụ `flex-ai-gateway` với biến môi trường đã khai báo từ trước) gửi yêu cầu suy luận và nhận được phản hồi hợp lệ, mà không cần sửa cấu hình của dịch vụ đó.

**Lý do ưu tiên**: Mục tiêu cốt lõi của việc khôi phục hạ tầng là để các dịch vụ phụ thuộc dùng lại được ngay, không phát sinh công sức tích hợp lại.

**Liên quan yêu cầu**: FR-003

**Test độc lập**: Gửi một yêu cầu suy luận từ dịch vụ đã có cấu hình sẵn (hoặc công cụ gọi thử tương đương) tới địa chỉ nội bộ đã quy ước, xác nhận nhận được phản hồi hợp lệ.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** dịch vụ AI cục bộ đang chạy và một dịch vụ khác đã có cấu hình kết nối sẵn từ trước, **Khi** dịch vụ đó gửi yêu cầu suy luận, **Thì** yêu cầu được xử lý thành công và trả về phản hồi từ mô hình `qwen2.5:1.5b`.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Không áp dụng.
- **Dữ liệu không hợp lệ**: Không áp dụng.
- **Không có quyền**: Không áp dụng (dịch vụ nội bộ trong môi trường phát triển, không có lớp phân quyền người dùng cuối).
- **Lỗi hệ thống**: Nếu dịch vụ AI cục bộ không khởi động được (ví dụ thiếu tài nguyên), hệ thống hạ tầng PHẢI báo lỗi rõ ràng qua log/trạng thái container thay vì âm thầm chạy thiếu.
- **Timeout**: Nếu mô hình chưa nạp xong mà đã có yêu cầu gọi tới, dịch vụ gọi PHẢI nhận được lỗi/timeout rõ ràng thay vì treo vô thời hạn.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng.
- **Người dùng thao tác lặp lại**: Khởi động lại stack nhiều lần PHẢI không làm hỏng hoặc tải lại không cần thiết mô hình đã có sẵn.
- **Trường hợp biên khác**: Không áp dụng.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI khôi phục dịch vụ chạy mô hình AI cục bộ (Ollama) trong stack hạ tầng phát triển, ở trạng thái hoạt động (không còn bị comment/tắt).
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI tự động nạp mô hình `qwen2.5:1.5b` khi dịch vụ AI cục bộ khởi động lần đầu, không yêu cầu thao tác thủ công.
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI khôi phục đường định tuyến nội bộ để các dịch vụ khác gọi được tới dịch vụ AI cục bộ bằng địa chỉ/quy ước đã có từ cấu hình cũ, không cần các dịch vụ đó thay đổi cấu hình.
  **Liên quan**: US-002, AC-003
- **FR-004** `[P2]`: Hệ thống KHÔNG ĐƯỢC yêu cầu tải lại mô hình từ đầu mỗi lần khởi động lại dịch vụ khi dữ liệu mô hình đã tồn tại.
  **Liên quan**: US-001, AC-002
- **FR-005** `[P3]`: Hệ thống PHẢI cho phép kỹ sư xác minh trạng thái sẵn sàng của dịch vụ AI cục bộ (đang chạy, mô hình đã nạp) thông qua cơ chế kiểm tra tình trạng hiện có của môi trường hạ tầng.
  **Liên quan**: US-001, AC-001

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Việc khôi phục chỉ áp dụng cho phần hạ tầng lõi (runtime model + routing); không mở rộng sang bật lại các dịch vụ AI khác (ví dụ vector database) trong cùng thay đổi này.
- **BR-002**: Mô hình sử dụng PHẢI là `qwen2.5:1.5b`, giữ nguyên theo cấu hình đã tồn tại trước đó trong workspace, không thay đổi sang phiên bản/mô hình khác.

**Luồng trạng thái nếu có**: Không áp dụng.

---

## 9. Thực thể dữ liệu

Không áp dụng.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Kỹ sư nội bộ có quyền truy cập môi trường phát triển/dev.

**Ai được thao tác**: Kỹ sư nội bộ có quyền quản trị hạ tầng môi trường phát triển.

**Ai không được phép**: Không áp dụng (không có người dùng cuối bên ngoài trong phạm vi tính năng này).

**Dữ liệu nhạy cảm**: Không. Đây là hạ tầng nội bộ trong môi trường phát triển, không xử lý dữ liệu khách hàng.

- **SEC-001**: Hệ thống PHẢI giữ nguyên phạm vi truy cập nội bộ hiện có (không mở dịch vụ AI cục bộ ra ngoài phạm vi mạng nội bộ/dev đã quy ước).
- **SEC-002**: Không áp dụng thêm ràng buộc phân quyền mới ngoài quy ước hạ tầng hiện tại.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng (thay đổi hạ tầng cấu hình môi trường phát triển, không phải nghiệp vụ có audit trail người dùng).

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Dịch vụ AI cục bộ PHẢI đạt trạng thái sẵn sàng trong một khoảng thời gian hữu hạn, có thể quan sát được qua log/trạng thái container; KHÔNG ĐƯỢC treo vô thời hạn khi tài nguyên máy đủ đáp ứng mô hình `qwen2.5:1.5b`. Spec không đặt ngưỡng thời gian cụ thể (xem Clarifications / Session 2026-08-05); ngưỡng cụ thể nếu cần sẽ do plan kỹ thuật xác định.
- **NFR-002**: Việc khôi phục KHÔNG ĐƯỢC làm gián đoạn các dịch vụ khác đang chạy trong cùng môi trường hạ tầng phát triển.
- **NFR-003**: Cấu hình khôi phục PHẢI hoạt động nhất quán trên máy phát triển của các thành viên trong đội theo cùng một quy trình khởi động hạ tầng hiện có.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Sau khi khởi động stack hạ tầng phát triển từ đầu, dịch vụ AI cục bộ sẵn sàng phục vụ yêu cầu suy luận mà không cần bất kỳ thao tác thủ công bổ sung nào.
- **SC-002**: 100% dịch vụ nội bộ đã có cấu hình trỏ tới AI cục bộ (ví dụ `flex-ai-gateway`) kết nối thành công ngay sau khi khôi phục, không cần sửa cấu hình phía dịch vụ gọi.
- **SC-003**: Không phát sinh sự cố gián đoạn cho các dịch vụ hạ tầng khác đang chạy cùng stack sau khi khôi phục.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Máy chạy môi trường phát triển có đủ tài nguyên (CPU/RAM) để chạy mô hình `qwen2.5:1.5b` ở chế độ CPU, không yêu cầu GPU chuyên dụng.
- Các dịch vụ tiêu thụ AI cục bộ (như `flex-ai-gateway`) đã có sẵn cấu hình kết nối đúng như hiện trạng lưu trong workspace và không cần thay đổi.
- Pattern hạ tầng đã comment/lưu trữ trước đó (Docker Compose service, routing) vẫn còn đúng và chỉ cần được kích hoạt lại, không cần thiết kế lại từ đầu.

**Ràng buộc**:
- PHẢI dùng đúng mô hình `qwen2.5:1.5b` như cấu hình đã có sẵn trong workspace, không đổi sang mô hình khác.
- PHẢI tận dụng lại pattern hạ tầng đã tồn tại trước đó (không xây dựng giải pháp hoàn toàn mới) trừ khi pattern cũ không còn khả thi.

---

## 15. Ngoài phạm vi

- Bật lại vector database (Qdrant) và các tính năng RAG liên quan.
- Tự động nạp model embedding (ví dụ `nomic-embed-text-v2-moe`, `mxbai-embed-large:v1`) — phạm vi này chỉ nạp model chat `qwen2.5:1.5b` (xem Clarifications / Session 2026-08-05).
- Xây dựng hoặc sửa logic nghiệp vụ của `flex-ai-gateway` hoặc bất kỳ dịch vụ tiêu thụ AI nào khác.
- Bất kỳ tính năng sản phẩm AI nào hướng tới người dùng cuối (chatbot, agent, trợ lý...) — các tính năng này thuộc phạm vi các spec riêng (ví dụ nền tảng AI Agent).
- Triển khai hạ tầng AI cục bộ ra môi trường production/staging.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Pattern hạ tầng cũ đã lỗi thời (phiên bản image, cấu hình network) so với trạng thái hiện tại của môi trường dev | Trung | Trung | Kiểm tra và cập nhật tối thiểu cấu hình khi khôi phục, không thay đổi kiến trúc tổng thể |
| Máy phát triển của một số thành viên không đủ tài nguyên chạy mô hình ổn định | Thấp | Trung | Model đã chọn (`qwen2.5:1.5b`) thuộc nhóm nhẹ, phù hợp chạy CPU; theo dõi phản hồi từ đội khi áp dụng |

---

## 17. Phụ thuộc

- Phụ thuộc vào cấu hình hiện có trong `flex-environment` (Docker Compose, routing, biến môi trường của `flex-ai-gateway`) đúng như đã khảo sát — nếu các phần này bị thay đổi trước khi thực hiện, cần khảo sát lại.

---

## 18. Câu hỏi mở

*(Không có câu hỏi cần làm rõ — phạm vi, mô hình sử dụng và ranh giới với các spec khác đã được xác nhận với stakeholder trước khi viết spec.)*

---

## Clarifications

### Session 2026-08-05

- Q: MVP hiện chỉ yêu cầu tự động nạp model chat `qwen2.5:1.5b`. Cấu hình `flex-ai-gateway/.env` còn có sẵn `OLLAMA_EMBED_MODEL=nomic-embed-text-v2-moe`, và pattern gốc đã comment cũng từng pull thêm `mxbai-embed-large:v1`. Phạm vi khôi phục lần này có nên tự động nạp cả model embedding không? → A: Không. Chỉ nạp model chat `qwen2.5:1.5b`; embedding model để lại cho spec khác vì Qdrant/RAG đã ngoài phạm vi (MVP-004).
- Q: NFR-001 yêu cầu dịch vụ AI cục bộ sẵn sàng trong "thời gian hợp lý" — chưa có con số cụ thể. Nên dùng ngưỡng nào? → A: Không đặt ngưỡng thời gian cụ thể ở mức spec; chỉ yêu cầu không treo vô thời hạn và có thể quan sát được qua log/trạng thái container, ngưỡng cụ thể (nếu cần) để lại cho plan kỹ thuật.

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
