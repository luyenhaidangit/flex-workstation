# Đặc tả tính năng: Review và cải tiến API Gateway theo Best Practices

**Branch**: `000023-api-gateway-review`
**Ngày tạo**: 2026-07-29
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Review API Gateway hiện tại (flex-api-gateway) đối chiếu với checklist best practices, xác định các khoảng trống (gap) và đề xuất cải tiến cần thực hiện.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

API Gateway hiện tại (`flex-api-gateway`) là điểm vào duy nhất cho toàn bộ traffic tới các service backend, nhưng chưa được đối chiếu có hệ thống với checklist best practices ngành (`docs/architecture/api-gateway-best-practices.md`). Rà soát sơ bộ cho thấy một số khoảng trống đáng lo ngại: chính sách CORS ở production đang cho phép mọi origin, khóa ký JWT được lưu dưới dạng plaintext trong file cấu hình, và cấu hình cluster/health-check/load-balancing giúp gateway chịu lỗi mới chỉ tồn tại ở môi trường dev — production chưa có cấu hình tương đương. Đồng thời, tài liệu kỹ thuật hiện có (`PRODUCTION-READY-GATEWAY.md`) mô tả một số hạng mục là "đã hoàn thành" trong khi triển khai thực tế chưa đạt, gây rủi ro hiểu lầm khi ra quyết định vận hành. Nếu không được rà soát và xử lý, các khoảng trống này có thể dẫn tới rủi ro bảo mật (truy cập trái phép, lộ khóa xác thực) hoặc mất khả năng chịu lỗi khi backend gặp sự cố ở production.

**Tổng quan tính năng**:

Thực hiện review toàn diện gateway hiện tại đối chiếu với checklist best practices (11 hạng mục: AuthN/AuthZ, Rate Limiting, Bảo mật, Routing/Load Balancing, Resilience, Observability, Caching, Versioning, Hiệu năng, High Availability, Developer Experience), tạo báo cáo khoảng trống có ưu tiên rõ ràng, và khắc phục các khoảng trống mức độ nghiêm trọng nhất (bảo mật, khả năng chịu lỗi production) trong phạm vi MVP. Đối tượng hưởng lợi là platform/backend team vận hành gateway và toàn bộ hệ thống phụ thuộc vào gateway để hoạt động an toàn, ổn định.

---

## 2. Mục tiêu

- **MT-001**: Đóng khoảng trống bảo mật nghiêm trọng ở cấu hình CORS (mở mọi origin) trước khi gateway được xem là sẵn sàng production. Khoảng trống khóa JWT plaintext được ghi nhận là rủi ro chấp nhận tạm thời, xử lý ở lộ trình sau MVP (xem §15, §16).
- **MT-002**: Đảm bảo khả năng chịu lỗi và tính sẵn sàng cao (failover, health check) hoạt động thực sự ở production, không chỉ tồn tại trong cấu hình dev.
- **MT-003**: Có báo cáo rõ ràng, có ưu tiên về toàn bộ khoảng trống so với best practices để lập kế hoạch xử lý tiếp theo.
- **MT-004**: Tài liệu kỹ thuật của gateway phản ánh đúng trạng thái triển khai thực tế, tránh gây hiểu lầm khi ra quyết định vận hành.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Báo cáo gap analysis đầy đủ cho toàn bộ 11 hạng mục best practices, có mức ưu tiên (P0/P1/P2) và chỉ rõ điểm sai lệch giữa tài liệu và triển khai thực tế.
- **MVP-002**: Chính sách CORS ở production được giới hạn theo danh sách domain được phép — lấy baseline là các domain production hiện tại của frontend/service đang gọi qua gateway (ví dụ `flex-microfrontend`) — thay vì cho phép mọi origin.
- ~~**MVP-003**: Khóa ký JWT không còn được lưu dưới dạng plaintext trong file cấu hình được commit vào source.~~ Đã rút khỏi phạm vi MVP theo quyết định stakeholder (2026-07-30) — chuyển sang lộ trình sau MVP, xem §15 Ngoài phạm vi và §16 Rủi ro.
- **MVP-004**: Cấu hình cluster/destination/health-check/load-balancing được kích hoạt ở production tương đương với cấu hình đã có ở dev.
- **MVP-005**: Gateway có endpoint kiểm tra tình trạng (health/readiness) riêng, độc lập với health check của các cluster downstream.
- **MVP-006**: Tài liệu kỹ thuật của gateway được cập nhật để phản ánh đúng trạng thái sau khi các mục MVP hoàn tất.

Các hạng mục nâng cao hơn (caching, API versioning, distributed tracing, metrics/Prometheus, developer portal) được đưa vào báo cáo dưới dạng đề xuất lộ trình, **không** nằm trong phạm vi implement của MVP này (xem §15 Ngoài phạm vi).

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Platform/Backend team và DevOps chịu trách nhiệm vận hành `flex-api-gateway`.

**Bối cảnh sử dụng**: Trước khi công bố gateway "production ready" hoặc theo chu kỳ review định kỳ về bảo mật/vận hành hạ tầng dùng chung.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật (đội ngũ vận hành hạ tầng và bảo mật).

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Nhận báo cáo gap analysis đối chiếu best practices (Ưu tiên: P1)

Platform team thực hiện review gateway hiện tại đối chiếu checklist best practices và nhận được báo cáo liệt kê rõ từng khoảng trống, mức độ ưu tiên và điểm sai lệch giữa tài liệu với triển khai thực tế, để lên kế hoạch xử lý.

**Lý do ưu tiên**: Là bước bắt buộc đầu tiên — không thể ưu tiên xử lý đúng nếu chưa biết rõ khoảng trống nằm ở đâu và mức độ nghiêm trọng ra sao.

**Liên quan yêu cầu**: FR-001, FR-002, FR-007

**Test độc lập**: Có thể xác minh độc lập bằng cách đối chiếu báo cáo với checklist gốc — mỗi hạng mục trong checklist phải xuất hiện trong báo cáo kèm trạng thái và bằng chứng.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** checklist tại `docs/architecture/api-gateway-best-practices.md`, **Khi** review được thực hiện đối chiếu với gateway hiện tại, **Thì** có báo cáo liệt kê đầy đủ cả 11 hạng mục kèm trạng thái (đạt/một phần/thiếu) và mức ưu tiên (P0/P1/P2).
2. **AC-002**: **Cho trước** báo cáo gap, **Khi** so sánh với tài liệu kỹ thuật hiện có của gateway (README, PRODUCTION-READY-GATEWAY.md...), **Thì** mọi điểm tài liệu mô tả "đã hoàn thành" nhưng triển khai thực tế chưa đạt đều được nêu rõ.

---

### US-002 — Khắc phục khoảng trống bảo mật CORS nghiêm trọng (Ưu tiên: P1)

DevOps/Security xử lý khoảng trống bảo mật CORS (mở mọi origin) để gateway an toàn trước khi được xem là sẵn sàng production. Khoảng trống khóa JWT plaintext không thuộc MVP này (xem §15 Ngoài phạm vi).

**Lý do ưu tiên**: Rủi ro bảo mật ảnh hưởng trực tiếp tới toàn bộ hệ thống phía sau gateway; cần xử lý trước các cải tiến khác.

**Liên quan yêu cầu**: FR-003

**Test độc lập**: Có thể test độc lập bằng cách kiểm tra cấu hình CORS chỉ chấp nhận domain trong whitelist.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** cấu hình CORS hiện tại cho phép mọi origin, **Khi** cải tiến được áp dụng, **Thì** chỉ các domain trong danh sách được duyệt mới truy cập được gateway ở production; request từ origin khác bị từ chối.

---

### US-003 — Đảm bảo khả năng chịu lỗi thực sự hoạt động ở production (Ưu tiên: P2)

Vận hành cần gateway có khả năng failover và health check hoạt động thực sự ở production, không chỉ tồn tại trong cấu hình môi trường dev.

**Lý do ưu tiên**: Ảnh hưởng trực tiếp tới tính sẵn sàng của toàn hệ thống khi một backend gặp sự cố; mức độ khẩn cấp thấp hơn nhóm bảo mật nhưng vẫn cần trong MVP.

**Liên quan yêu cầu**: FR-005, FR-006

**Test độc lập**: Có thể test độc lập bằng cách mô phỏng một destination downstream lỗi ở production và xác nhận gateway tự động loại destination đó khỏi load balancing; gọi endpoint health/readiness và nhận phản hồi đúng trạng thái.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** cấu hình cluster/load-balancing/health-check hiện chỉ có ở môi trường dev, **Khi** cải tiến được áp dụng, **Thì** production có cấu hình tương đương và được xác nhận hoạt động (destination lỗi bị loại khỏi load balancing tự động).
2. **AC-006**: **Cho trước** gateway chưa có endpoint kiểm tra tình trạng riêng, **Khi** cải tiến được áp dụng, **Thì** gọi endpoint health/readiness của gateway trả về đúng trạng thái, độc lập với health check của downstream cluster.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Không áp dụng.
- **Dữ liệu không hợp lệ**: Không áp dụng.
- **Không có quyền**: Request từ origin không nằm trong whitelist CORS PHẢI bị từ chối rõ ràng, không được forward tới downstream.
- **Lỗi hệ thống**: Khi một destination downstream lỗi, gateway PHẢI loại destination đó khỏi vòng load balancing thay vì tiếp tục forward request tới đích đang lỗi.
- **Timeout**: Không áp dụng riêng cho spec này (đã có resilience timeout hiện hữu, không nằm trong phạm vi thay đổi MVP).
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng.
- **Người dùng thao tác lặp lại**: Không áp dụng.
- **Trường hợp biên khác**: Khi tất cả destination trong một cluster đều lỗi, gateway PHẢI trả về lỗi rõ ràng cho client thay vì treo hoặc timeout mơ hồ.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI có báo cáo review đối chiếu đầy đủ 11 hạng mục best practices (AuthN/AuthZ, Rate Limiting, Bảo mật, Routing/Load Balancing, Resilience, Observability, Caching, Versioning, Hiệu năng, High Availability, Developer Experience) với trạng thái hiện tại cho từng hạng mục.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Báo cáo PHẢI chỉ rõ các điểm sai lệch giữa tài liệu kỹ thuật hiện có và triển khai thực tế của gateway.
  **Liên quan**: US-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI giới hạn CORS ở production theo danh sách domain được duyệt — baseline là các domain production hiện tại của frontend/service đang gọi qua gateway — không sử dụng cấu hình cho phép mọi origin.
  **Liên quan**: US-002, AC-003
- ~~**FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC lưu trữ khóa ký xác thực (JWT signing key) dưới dạng plaintext trong file cấu hình được commit vào source.~~ Đã rút khỏi phạm vi MVP (xem §15 Ngoài phạm vi) — đưa vào đề xuất lộ trình ở FR-007.
- **FR-005** `[P2]`: Hệ thống PHẢI kích hoạt cấu hình cluster/destination/health-check/load-balancing ở production tương đương với cấu hình đã có ở môi trường dev.
  **Liên quan**: US-003, AC-005
- **FR-006** `[P2]`: Hệ thống PHẢI cung cấp endpoint kiểm tra tình trạng gateway (health/readiness) độc lập, phục vụ giám sát và load balancer.
  **Liên quan**: US-003, AC-006
- **FR-007** `[P2]`: Báo cáo PHẢI đề xuất lộ trình ưu tiên cho các hạng mục còn thiếu nằm ngoài phạm vi MVP (caching, versioning, distributed tracing, metrics, developer portal).
  **Liên quan**: US-001
- **FR-008** `[P3]`: Tài liệu kỹ thuật của gateway (README, PRODUCTION-READY-GATEWAY.md...) PHẢI được cập nhật để phản ánh đúng trạng thái triển khai sau khi các mục MVP hoàn tất.
  **Liên quan**: US-001, AC-002

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Một khoảng trống được xếp mức P0/Blocker nếu liên quan trực tiếp tới rò rỉ dữ liệu, khả năng bypass xác thực, hoặc mất khả năng chịu lỗi ở production.
- **BR-002**: Không được công bố hoặc duy trì tài liệu mô tả một hạng mục là "production ready" nếu hạng mục đó chưa được xác minh hoạt động thực tế ở production (không chỉ tồn tại trong cấu hình dev).
- **BR-003**: Mọi thay đổi liên quan tới cấu hình bảo mật (CORS, secret, authentication) PHẢI được review bởi ít nhất một người khác trước khi áp dụng ở production.

**Luồng trạng thái nếu có**: Không áp dụng.

---

## 9. Thực thể dữ liệu

Không áp dụng — tính năng không tạo ra thực thể nghiệp vụ mới, chỉ tạo ra một báo cáo (gap analysis report) và điều chỉnh cấu hình vận hành hiện có của gateway.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Platform/Backend team, DevOps, Security/Compliance.

**Ai được thao tác**: Platform tech lead và người được phân công phê duyệt thay đổi cấu hình production.

**Ai không được phép**: Không áp dụng (phạm vi nội bộ team vận hành).

**Dữ liệu nhạy cảm**:
- Có. Khóa ký JWT và danh sách domain whitelist CORS được coi là thông tin cấu hình nhạy cảm, không được để lộ trong source code công khai.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép thao tác thay đổi cấu hình bảo mật production.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho phép người dùng truy cập dữ liệu ngoài phạm vi được cấp quyền.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có.

Nếu có, hệ thống PHẢI ghi nhận:

- Ai thực hiện thay đổi cấu hình bảo mật/production (qua git history/change log).
- Thao tác gì (CORS, JWT secret, cấu hình cluster/health-check...).
- Thời điểm thực hiện.
- Lý do thay đổi (liên kết tới báo cáo gap analysis tương ứng).

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Endpoint health/readiness của gateway PHẢI phản hồi trong dưới 1 giây trong điều kiện tải bình thường.
- **NFR-002**: Việc áp dụng các cải tiến KHÔNG ĐƯỢC làm gián đoạn các luồng request đang hoạt động qua gateway (triển khai không downtime).
- **NFR-003**: Cấu hình chịu lỗi ở production PHẢI tương đương hoặc tốt hơn cấu hình hiện có ở dev, không được kém hơn.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% các hạng mục trong checklist best practices xuất hiện trong báo cáo với trạng thái và mức ưu tiên rõ ràng.
- **SC-002**: Khoảng trống CORS mở và khoảng trống chịu lỗi production (cluster/health-check) được khắc phục trước khi gateway được công bố là sẵn sàng production. Khoảng trống JWT secret plaintext được ghi nhận là rủi ro chấp nhận, không chặn công bố production trong MVP này (xem §15, §16).
- **SC-003**: Không còn điểm sai lệch giữa tài liệu kỹ thuật của gateway và triển khai thực tế đối với các hạng mục đã được review.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Checklist tại `docs/architecture/api-gateway-best-practices.md` là nguồn tham chiếu chính cho review.
- Hệ thống gateway hiện tại (`flex-api-gateway`) tiếp tục là nền tảng, không thay đổi sang công nghệ gateway khác.
- Platform team có đủ nguồn lực để xử lý các mục MVP sau khi có báo cáo gap.
- Các hạng mục ngoài MVP không có deadline cụ thể từ stakeholder; platform team tự sắp xếp lộ trình theo mức ưu tiên trong báo cáo gap (P0/P1/P2).

**Ràng buộc**:
- PHẢI tương thích ngược với các client/service đang gọi qua gateway hiện tại — không được phá vỡ hợp đồng API hiện có.
- PHẢI tuân theo quy tắc bảo mật và governance hiện có của tổ chức khi thay đổi cấu hình production.

---

## 15. Ngoài phạm vi

- Thiết kế lại kiến trúc gateway từ đầu hoặc chuyển sang công nghệ gateway khác (Kong, Envoy, Apigee...).
- Triển khai đầy đủ các hạng mục nâng cao ngoài MVP: caching, API versioning, distributed tracing, metrics/dashboard, developer portal — các mục này chỉ được đưa vào đề xuất lộ trình (FR-007), không implement trong spec này.
- Xử lý khóa ký JWT lưu plaintext trong file cấu hình (MVP-003/FR-004 cũ) — dù là khoảng trống bảo mật mức P0 theo BR-001, stakeholder quyết định (2026-07-30) rút khỏi phạm vi MVP và chuyển sang lộ trình sau MVP (đề xuất ưu tiên trong báo cáo gap qua FR-007). Rủi ro liên quan xem §16.
- Thay đổi luồng nghiệp vụ hoặc hợp đồng API của các service downstream.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| CORS mở bị khai thác trước khi kịp khắc phục | Trung | Cao | Ưu tiên xử lý MVP-002 sớm nhất; giới hạn truy cập tạm thời nếu cần trong lúc chờ fix. |
| Khóa JWT plaintext trong source bị khai thác trong thời gian bị hoãn xử lý (ngoài phạm vi MVP) | Trung | Cao | Rủi ro được stakeholder chấp nhận có ý thức (2026-07-30); đề xuất ưu tiên cao nhất trong lộ trình sau MVP (FR-007); hạn chế quyền truy cập repo chứa file cấu hình trong lúc chờ xử lý. |
| Bật cấu hình cluster/health-check ở production bị cấu hình sai, gây gián đoạn traffic | Trung | Cao | Test kỹ ở staging trước khi áp dụng production; chuẩn bị rollback plan. |
| Team thiếu nguồn lực để xử lý hết lộ trình ngoài MVP | Trung | Trung | Ưu tiên theo mức độ rủi ro trong báo cáo, cho phép triển khai theo giai đoạn tiếp theo. |

---

## 17. Phụ thuộc

- Danh sách domain whitelist CORS lấy baseline từ domain production hiện tại của frontend/service đang gọi gateway; xác nhận lại với team frontend/product nếu có domain mới phát sinh sau MVP.
- Việc xử lý khóa ký JWT plaintext (ngoài phạm vi MVP) phụ thuộc vào giải pháp secret management được chọn ở lộ trình sau MVP; không phải phụ thuộc chặn MVP này.

---

## 18. Câu hỏi mở

- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-30]
- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-30]
- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-30]

---

## Clarifications

### Session 2026-07-30

- Q: Danh sách domain chính thức cần whitelist cho CORS ở production là gì? → A: Dùng domain production hiện tại của các frontend/service đang gọi qua gateway (ví dụ `flex-microfrontend`) làm baseline whitelist.
- Q: Tổ chức đã có giải pháp secret management sẵn dùng cho khóa JWT chưa, hay cần chọn mới? → A: Không xử lý trong MVP này — khoảng trống JWT secret plaintext bị rút khỏi phạm vi MVP, chuyển sang lộ trình sau MVP (xem §15 Ngoài phạm vi, §16 Rủi ro).
- Q: Các hạng mục ngoài MVP (caching, versioning, tracing, metrics) có deadline ưu tiên cụ thể từ stakeholder không? → A: Không có deadline cụ thể — platform team tự sắp xếp lộ trình theo mức ưu tiên trong báo cáo gap (P0/P1/P2).

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
