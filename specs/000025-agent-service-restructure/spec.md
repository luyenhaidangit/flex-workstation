# Đặc tả tính năng: Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture

**Branch**: `[000025-agent-service-restructure]`
**Ngày tạo**: 2026-07-30
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Tái cấu trúc `flex-agent-service` (hiện là 1 project phẳng) thành cấu trúc nhiều project (Domain / Infrastructures / API) tương tự `flex-auth-service`, không thay đổi hành vi nghiệp vụ hiện có.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

`flex-agent-service` hiện tại là một project ASP.NET Core duy nhất (`FlexAgentService.csproj`), gộp chung API controller, business logic, EF Core persistence và hạ tầng cross-cutting trong cùng một project (`Channels/`, `Data/`, `Shared/`). Khi số lượng kênh (channel) tích hợp tăng lên (Instagram, sắp tới Facebook Messenger, Zalo...), cấu trúc phẳng này khiến:

- Ranh giới giữa domain logic, hạ tầng (infra) và API không rõ ràng, dễ dẫn tới coupling chéo.
- Khó tái sử dụng các thành phần cross-cutting (logging, response wrapper, exception handling, resilience...) theo cách nhất quán với các service khác trong hệ Flex.
- Dev mới tham gia khó định hướng vì cấu trúc không giống với service tham chiếu (`flex-auth-service`), làm tăng thời gian onboarding và review code.
- Việc mở rộng thêm channel hoặc domain mới có nguy cơ tiếp tục làm phình to một project duy nhất thay vì phân lớp rõ ràng.

Việc này cần xử lý trước khi agent-service tiếp tục mở rộng thêm channel mới, để tránh chi phí tái cấu trúc tăng theo thời gian.

**Tổng quan tính năng**:

Tái cấu trúc mã nguồn `flex-agent-service` thành nhiều project theo mô hình Clean Architecture (Domain / Infrastructures / API host), theo đúng khuôn mẫu đã áp dụng ổn định tại `flex-auth-service`. Đối tượng hưởng lợi là đội ngũ kỹ sư backend Flex — người trực tiếp phát triển, bảo trì và mở rộng agent-service.

---

## 2. Mục tiêu

- **MT-001**: Ranh giới domain / infrastructure / API được tách rõ thành các project riêng biệt, cùng chuẩn đặt tên và tổ chức thư mục với `flex-auth-service`.
- **MT-002**: Toàn bộ hành vi nghiệp vụ hiện có (API endpoint, luồng OAuth/webhook Instagram, schema dữ liệu) hoạt động không đổi sau khi tái cấu trúc.
- **MT-003**: Dev team có thể thêm channel hoặc domain mới trong tương lai theo đúng vị trí quy ước mà không cần "đoán" cấu trúc.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Tách `flex-agent-service` thành đúng 3 project theo layer kiến trúc, đặt tên theo namespace `Flex.Agent.*` (nhất quán với `Flex.Auth.*`): `Flex.Agent.Domain` (entity, enum nghiệp vụ như `ChannelType`), `Flex.Agent.Infrastructures` (EF Core `AppDbContext`, migrations, các dịch vụ hạ tầng như mã hoá token), và `Flex.Agent` (API host: controllers, DI, `Program.cs`). Không tách thêm project riêng theo từng channel (Instagram, Facebook...) — các channel nằm trong thư mục con của project theo layer tương ứng.
- **MVP-002**: Toàn bộ tính năng Instagram Business hiện có (`Channels/Instagram/*`) được di chuyển vào cấu trúc project mới mà không đổi hành vi, route, hay contract API.
- **MVP-003**: Solution file (`.sln`) được tạo để build toàn bộ các project cùng lúc, thay cho project đơn `FlexAgentService.csproj`.
- **MVP-004**: Toàn bộ test hiện có (`tests/Channels/*`) tiếp tục pass sau khi tái cấu trúc, được cập nhật theo namespace/project mới nếu cần.
- **MVP-005**: Giới hạn MVP: chỉ tái cấu trúc mã nguồn C# hiện có (không bao gồm Dockerfile, Jenkinsfile, hay docs/ vận hành); không thêm channel mới, không thay đổi schema dữ liệu, không thay đổi API contract trong phạm vi này.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Kỹ sư backend trong đội Flex — người phát triển, review và bảo trì `flex-agent-service`.

**Bối cảnh sử dụng**: Trong quá trình phát triển tính năng mới (thêm channel, thêm domain), sửa lỗi, hoặc onboard thành viên mới vào codebase.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật (dev/engineer nội bộ).

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Dev tìm đúng vị trí đặt code mới (Ưu tiên: P1)

Là một backend engineer, khi cần thêm entity, service hoặc controller mới cho agent-service, tôi muốn cấu trúc project cho tôi biết ngay vị trí đặt code (domain/infra/API) dựa trên quy ước đã áp dụng ở `flex-auth-service`, để tôi không mất thời gian đoán hoặc hỏi lại team.

**Lý do ưu tiên**: Đây là giá trị cốt lõi của việc tái cấu trúc — nếu không đạt được, mục tiêu nhất quán cấu trúc không có ý nghĩa.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Kiểm tra cấu trúc thư mục/project mới có project Domain, Infrastructures, API tương ứng vai trò rõ ràng, đối chiếu với cấu trúc `flex-auth-service`.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** solution `flex-agent-service` sau tái cấu trúc, **Khi** dev mở solution, **Thì** dev thấy tối thiểu 3 project tách biệt theo vai trò domain/infrastructure/API, đặt tên nhất quán với `flex-auth-service` (tiền tố `Flex.*`).
2. **AC-002**: **Cho trước** cấu trúc mới, **Khi** dev cần thêm entity nghiệp vụ mới, **Thì** vị trí đặt entity (project Domain) là duy nhất và không mơ hồ.

---

### US-002 — Nghiệp vụ hiện có không bị gián đoạn (Ưu tiên: P1)

Là một backend engineer/QA, tôi muốn toàn bộ API và luồng nghiệp vụ Instagram Business hiện tại (kết nối tài khoản Meta, OAuth, webhook) tiếp tục hoạt động đúng như trước sau khi tái cấu trúc, để việc refactor không gây rủi ro cho các tính năng đang chạy.

**Lý do ưu tiên**: Tái cấu trúc chỉ có giá trị nếu không phá vỡ hành vi hiện có; đây là điều kiện bắt buộc, không phải tuỳ chọn.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Chạy lại toàn bộ test suite hiện có và kiểm thử thủ công các endpoint Instagram (OAuth, webhook, kết nối page) sau khi tái cấu trúc, so sánh kết quả với trước khi refactor.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** bộ test hiện có của `tests/Channels`, **Khi** chạy lại sau tái cấu trúc, **Thì** toàn bộ test pass với cùng độ phủ nghiệp vụ như trước.
2. **AC-004**: **Cho trước** các endpoint API hiện có (Instagram OAuth, webhook, quản lý kết nối page), **Khi** gọi lại sau tái cấu trúc, **Thì** route, request/response contract và hành vi giữ nguyên.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Không áp dụng — tái cấu trúc mã nguồn, không đổi dữ liệu.
- **Dữ liệu không hợp lệ**: Không áp dụng.
- **Không có quyền**: Không áp dụng.
- **Lỗi hệ thống**: Nếu build solution mới thất bại, dev PHẢI nhận thông báo lỗi build rõ ràng để xác định project gây lỗi.
- **Timeout**: Không áp dụng.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng.
- **Người dùng thao tác lặp lại**: Không áp dụng.
- **Trường hợp biên khác**: Migration EF Core hiện có (`Data/Migrations`) PHẢI tiếp tục áp dụng đúng lên cùng schema database sau khi di chuyển sang project infrastructure mới, không phát sinh migration trùng hoặc xung đột.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Solution PHẢI có project riêng `Flex.Agent.Domain` cho tầng domain (entity nghiệp vụ, enum như `ChannelType`), không phụ thuộc vào project infrastructure hoặc API.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Solution PHẢI có project riêng `Flex.Agent.Infrastructures` cho tầng infrastructure (EF Core `DbContext`, migrations, dịch vụ hạ tầng như mã hoá token) tách khỏi project API.
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Solution PHẢI có project API host `Flex.Agent` (controllers, DI, entrypoint) sử dụng project domain và infrastructure. Đúng 3 project theo layer (Domain/Infrastructures/API); KHÔNG tách thêm project riêng theo từng channel.
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Toàn bộ endpoint API, luồng OAuth và webhook Instagram Business hiện có PHẢI giữ nguyên route và hành vi sau khi tái cấu trúc.
  **Liên quan**: US-002, AC-004
- **FR-005** `[P1]`: Toàn bộ test hiện có PHẢI được cập nhật theo cấu trúc project mới và PHẢI pass sau khi tái cấu trúc.
  **Liên quan**: US-002, AC-003
- **FR-006** `[P2]`: Solution PHẢI có file `.sln` cho phép build toàn bộ project cùng lúc.
  **Liên quan**: US-001, AC-001
- **FR-007** `[P1]`: Hệ thống KHÔNG ĐƯỢC thay đổi schema database hiện có (tên bảng, cột, index, ràng buộc) trong phạm vi tái cấu trúc này.
  **Liên quan**: US-002, AC-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Project domain KHÔNG ĐƯỢC phụ thuộc vào project infrastructure hoặc API (tuân theo nguyên tắc Clean Architecture đã áp dụng ở `flex-auth-service`).
- **BR-002**: Mọi logic nghiệp vụ (business rule) hiện có trong `Channels/Instagram/*` PHẢI được giữ nguyên hành vi khi di chuyển sang cấu trúc mới, không âm thầm thay đổi rule.
- **BR-003**: Cấu trúc thư mục và quy ước đặt tên project mới PHẢI dùng tiền tố `Flex.Agent.*`, phân chia đúng 3 project `Flex.Agent.Domain` / `Flex.Agent.Infrastructures` / `Flex.Agent` (API), tham chiếu trực tiếp theo `flex-auth-service`.

**Luồng trạng thái nếu có**: Không áp dụng.

---

## 9. Thực thể dữ liệu

- **Không áp dụng** — đây là tái cấu trúc tổ chức mã nguồn, không tạo thực thể nghiệp vụ mới. Các entity hiện có (`MetaAccountConnection`, `InstagramPageConnection`) được di chuyển nguyên trạng sang project domain/infrastructure mới.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Không áp dụng — không có thay đổi về phân quyền người dùng cuối.

**Ai được thao tác**: Đội kỹ sư backend Flex thực hiện tái cấu trúc và review.

**Ai không được phép**: Không áp dụng.

**Dữ liệu nhạy cảm**: Không — dịch vụ mã hoá token kênh (`ChannelTokenEncryptionService`) hiện có PHẢI được di chuyển nguyên trạng, không làm suy yếu cơ chế mã hoá hiện tại.

- **SEC-001**: Không áp dụng (không có thay đổi luồng xác thực/phân quyền người dùng cuối trong phạm vi này).
- **SEC-002**: Không áp dụng.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng — đây là thay đổi cấu trúc mã nguồn nội bộ, không phải thay đổi dữ liệu nghiệp vụ.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Sau tái cấu trúc, thời gian build toàn bộ solution KHÔNG được tăng đáng kể so với hiện tại (dùng cảm nhận dev làm chuẩn đo, không có số liệu benchmark chính thức trong phạm vi spec).
- **NFR-002**: Tính năng không được làm gián đoạn các luồng nghiệp vụ hiện có (API, webhook, kết nối kênh) trong và sau quá trình tái cấu trúc.
- **NFR-003**: Cấu trúc mới PHẢI cho phép dev mới định hướng vào đúng project cần sửa mà không cần tài liệu bổ sung ngoài quy ước đã có ở `flex-auth-service`.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% test hiện có pass sau khi tái cấu trúc, không giảm độ phủ so với trước.
- **SC-002**: 100% endpoint API hiện có (Instagram OAuth, webhook, quản lý kết nối) hoạt động đúng như trước sau tái cấu trúc, xác nhận qua kiểm thử thủ công hoặc tự động.
- **SC-003**: Dev có thể xác định đúng project cần sửa (domain/infra/API) cho một thay đổi cho trước mà không cần hỏi lại người khác, xác nhận qua review nội bộ với ít nhất 1 kỹ sư ngoài người thực hiện refactor.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- `flex-auth-service` (project Flex.Auth / Flex.Domain / Flex.Infrastructures) là chuẩn tham chiếu cấu trúc được đội ngũ chấp nhận cho các service .NET trong hệ Flex.
- Không có yêu cầu phải thêm ngay channel mới hoặc tính năng nghiệp vụ mới trong phạm vi tái cấu trúc này.
- Database schema và dữ liệu hiện có của `flex-agent-service` không cần di chuyển hay thay đổi.

**Ràng buộc**:
- PHẢI tương thích ngược với API contract hiện tại của các client đang gọi `flex-agent-service` (Instagram OAuth/webhook).
- PHẢI giữ nguyên schema database hiện có (không breaking migration).

---

## 15. Ngoài phạm vi

- Thêm channel mới (Facebook Messenger, Zalo, v.v.) — chỉ chuẩn bị cấu trúc để dễ thêm sau này, không triển khai trong phạm vi này.
- Tách project riêng theo từng channel (ví dụ project riêng cho Instagram) — quyết định là chỉ tách theo layer kiến trúc.
- Thay đổi API contract, request/response, hoặc business rule hiện có.
- Thiết lập CI/CD, Dockerfile, Jenkinsfile, hoặc tài liệu vận hành mới (docs/) tương tự `flex-auth-service` — quyết định là giới hạn phạm vi ở mã nguồn C#.
- Thay đổi cơ chế mã hoá token hoặc bảo mật hiện có ngoài việc di chuyển nguyên trạng.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Di chuyển code giữa project gây lỗi namespace/reference, dẫn tới build fail | Trung | Trung | Refactor theo từng bước nhỏ, build và chạy test sau mỗi bước di chuyển |
| Thay đổi cấu trúc project ảnh hưởng route/API contract ngoài ý muốn | Thấp | Cao | Kiểm thử lại toàn bộ endpoint hiện có trước khi coi refactor hoàn tất |
| EF Core migration bị áp dụng sai thứ tự hoặc trùng lặp sau khi đổi project chứa `AppDbContext` | Thấp | Cao | Kiểm tra `dotnet ef migrations` chạy đúng trên project mới trước khi merge |

---

## 17. Phụ thuộc

- Phụ thuộc vào cấu trúc `flex-auth-service` hiện có làm chuẩn tham chiếu — nếu `flex-auth-service` thay đổi cấu trúc trong lúc thực hiện, cần đồng bộ lại quyết định.

---

## 18. Câu hỏi mở

- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-30] ~~Phạm vi tái cấu trúc chỉ giới hạn ở việc tách project C# (Domain/Infrastructures/API), hay bao gồm cả việc thêm Dockerfile, Jenkinsfile, docs/ tương tự `flex-auth-service`?~~
- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-30] ~~Tên project mới nên đặt theo `Flex.Agent` / `Flex.Agent.Domain` / `Flex.Agent.Infrastructures` (đổi hẳn theo namespace `Flex.*` như auth-service), hay giữ tiền tố `FlexAgentService` hiện tại và chỉ tách thư mục/project mà không đổi tên gốc?~~
- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-30] ~~Có cần tách riêng project theo từng channel (ví dụ project riêng cho Instagram, project riêng cho Facebook Messenger sau này) hay chỉ tách theo layer kiến trúc (Domain/Infrastructures/API) như auth-service hiện tại?~~

---

## Clarifications

### Session 2026-07-30

- Q: Phạm vi tái cấu trúc có bao gồm việc thêm Dockerfile, Jenkinsfile, docs/ (giống flex-auth-service) hay chỉ giới hạn ở việc tách project C# (Domain/Infrastructures/API)? → A: Chỉ mã nguồn C#
- Q: Tên project mới nên đặt theo quy ước nào — đổi hẳn sang namespace `Flex.Agent.*` (như `Flex.Auth.*`) hay giữ tiền tố `FlexAgentService` hiện tại và chỉ tách thư mục/project? → A: Đổi sang `Flex.Agent.*`
- Q: Cấu trúc project mới nên tách theo layer kiến trúc (Domain/Infrastructures/API, giống auth-service) hay tách thêm theo từng channel (ví dụ project riêng cho Instagram, project riêng cho Facebook Messenger sau này)? → A: Chỉ tách theo layer

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở (không áp dụng).
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời (xem Clarifications / Session 2026-07-30).
