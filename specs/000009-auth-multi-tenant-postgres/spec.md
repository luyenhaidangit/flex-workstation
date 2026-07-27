# Đặc tả tính năng: Migrate datastore flex-auth-service từ Oracle sang PostgreSQL

**Branch**: `000009-auth-multi-tenant-postgres`
**Ngày tạo**: 2026-07-13
**Cập nhật**: 2026-07-27 — thu hẹp phạm vi (bỏ multi-tenant, chỉ giữ phần migrate datastore); bổ sung ràng buộc dùng chung quy ước migration PostgreSQL + Liquibase như database `hnx`
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Mô tả người dùng: "Trước đây auth service sử dụng Oracle, giờ cần chuyển sang sử dụng PostgreSQL, cần tạo db và migrate code." (Cập nhật 2026-07-27: stakeholder xác nhận chưa cần multi-tenant/tenant/role/JWT ở giai đoạn này — phạm vi chỉ còn migrate datastore.)

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

`flex-auth-service` hiện là dịch vụ xác thực chạy trên Oracle. Hệ thống Flex đang trong lộ trình bỏ Oracle dần (đã áp dụng cho các tính năng mới như `000005-mysql-tenant-db`, `000008-agent-platform-mvp`); `flex-auth-service` là một trong các dịch vụ còn phụ thuộc Oracle cần được refactor theo lộ trình này.

`flex-auth-service` hiện chưa có consumer hay dữ liệu người dùng thật chạy production, nên đây là thời điểm phù hợp để chuyển đổi datastore mà không phải xử lý tương thích ngược hay migrate dữ liệu cũ.

**Tổng quan tính năng**:

Tạo mới một PostgreSQL database cho `flex-auth-service` và migrate toàn bộ code truy cập dữ liệu (schema, query, tầng data access) từ Oracle sang PostgreSQL, giữ nguyên toàn bộ hành vi nghiệp vụ xác thực hiện có. Đây thuần túy là thay đổi datastore, không thay đổi mô hình nghiệp vụ (không multi-tenant, không thêm tenant/role/JWT — các nội dung này được để lại cho một tính năng riêng trong tương lai nếu cần).

---

## 1. Mục tiêu

- **MT-001**: `flex-auth-service` vận hành hoàn toàn trên datastore mới (PostgreSQL), không còn phụ thuộc Oracle.
- **MT-002**: Toàn bộ chức năng xác thực hiện có (đăng ký/đăng nhập/quản lý người dùng hiện tại) hoạt động đúng như trước, không có thay đổi hành vi nghiệp vụ do việc đổi datastore gây ra.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Tạo mới một PostgreSQL database dùng cho `flex-auth-service`, có schema tương đương với schema Oracle hiện tại (cùng thực thể, cùng ràng buộc nghiệp vụ).
- **MVP-002**: Migrate toàn bộ tầng truy cập dữ liệu của `flex-auth-service` (schema, query, ORM/data access code) sang PostgreSQL.
- **MVP-003**: Sau khi hoàn tất, không còn dữ liệu, kết nối hay cấu hình nào của `flex-auth-service` trỏ tới Oracle.
- **MVP-004**: Giới hạn MVP: không bao gồm multi-tenant, tenant/role, phát hành JWT theo tenant, SSO/OAuth ngoài, đổi mật khẩu qua email, MFA — giữ đúng các khả năng hiện có của `flex-auth-service`, chỉ đổi datastore bên dưới.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**:

- **Quản trị viên/kỹ sư vận hành hệ thống Flex**: thực hiện việc tạo database mới và triển khai phiên bản `flex-auth-service` đã migrate.
- **Người dùng cuối hiện có của `flex-auth-service`**: không nhận thấy thay đổi hành vi đăng ký/đăng nhập/quản lý tài khoản.

**Bối cảnh sử dụng**: Quản trị viên/kỹ sư vận hành thực hiện việc chuyển đổi trong môi trường phát triển/triển khai của `flex-auth-service`. Người dùng cuối tiếp tục sử dụng các chức năng xác thực như bình thường sau khi chuyển đổi hoàn tất.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Quản trị viên/kỹ sư vận hành là kỹ thuật. Người dùng cuối không cần biết về thay đổi này.

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Tạo PostgreSQL database mới cho flex-auth-service (Ưu tiên: P1)

Quản trị viên/kỹ sư vận hành tạo mới một PostgreSQL database dành riêng cho `flex-auth-service`, với schema phản ánh đúng các thực thể và ràng buộc nghiệp vụ hiện có trên Oracle.

**Lý do ưu tiên**: Là điều kiện tiên quyết để migrate code; không có database đích thì không thể chuyển đổi tầng truy cập dữ liệu.

**Liên quan yêu cầu**: FR-001, FR-002

**Test độc lập**: Tạo database mới, xác nhận schema có đầy đủ thực thể và ràng buộc tương đương Oracle hiện tại.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** yêu cầu tạo datastore mới cho `flex-auth-service`, **Khi** thực hiện, **Thì** một PostgreSQL database mới được tạo với schema tương đương Oracle hiện tại (cùng thực thể, cùng ràng buộc).

---

### US-002 — Vận hành hoàn toàn trên datastore mới, không còn phụ thuộc Oracle (Ưu tiên: P1)

Quản trị viên/kỹ sư vận hành triển khai `flex-auth-service` phiên bản đã migrate; toàn bộ chức năng xác thực hiện có (đăng ký, đăng nhập, quản lý người dùng) hoạt động đúng trên PostgreSQL. Không còn kết nối hay phụ thuộc vào Oracle ở bất kỳ luồng nào.

**Lý do ưu tiên**: Là yêu cầu bắt buộc theo lộ trình bỏ Oracle của hệ thống; vì `flex-auth-service` chưa có dữ liệu/consumer thật, đây là thời điểm ít rủi ro nhất để thực hiện.

**Liên quan yêu cầu**: FR-003, FR-004

**Test độc lập**: Khởi động `flex-auth-service` phiên bản mới trong môi trường không có Oracle, thực hiện trọn luồng đăng ký/đăng nhập/quản lý người dùng hiện có thành công.

**Acceptance Criteria**:

1. **AC-002**: **Cho trước** môi trường triển khai không có Oracle, **Khi** `flex-auth-service` khởi động và vận hành, **Thì** mọi luồng xác thực hiện có (đăng ký, đăng nhập, quản lý người dùng) đều hoạt động bình thường như trước khi migrate.
2. **AC-003**: **Cho trước** cấu hình dịch vụ, **Khi** kiểm tra kết nối/dependency, **Thì** không còn tham chiếu tới Oracle (connection string, wallet, driver) trong cấu hình chạy.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Database PostgreSQL mới khởi tạo chưa có dữ liệu người dùng nào — đúng như giả định (chưa có dữ liệu thật cần bảo toàn).
- **Dữ liệu không hợp lệ**: Giữ nguyên hành vi validate hiện có của `flex-auth-service` (không thay đổi do việc đổi datastore).
- **Lỗi hệ thống**: Nếu datastore không sẵn sàng, yêu cầu xác thực bị từ chối rõ ràng, không để hệ thống ở trạng thái không xác định.
- **Timeout**: Không áp dụng — nằm trong yêu cầu phi chức năng NFR-001.
- **Người dùng thao tác lặp lại**: Giữ nguyên hành vi hiện có của `flex-auth-service` (không thay đổi do việc đổi datastore).

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI có một PostgreSQL database mới dành cho `flex-auth-service` với schema tương đương Oracle hiện tại.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Schema PostgreSQL mới PHẢI bảo toàn các ràng buộc nghiệp vụ hiện có trên Oracle (ví dụ định danh duy nhất của tài khoản người dùng).
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Toàn bộ dữ liệu và tầng truy cập dữ liệu của `flex-auth-service` PHẢI được vận hành trên PostgreSQL, không phải Oracle.
  **Liên quan**: US-002, AC-002
- **FR-004** `[P1]`: Cấu hình vận hành của `flex-auth-service` KHÔNG ĐƯỢC còn tham chiếu tới Oracle (connection string, driver, wallet).
  **Liên quan**: US-002, AC-003

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Việc chuyển đổi datastore KHÔNG ĐƯỢC làm thay đổi hành vi nghiệp vụ xác thực hiện có của `flex-auth-service`.

---

## 8. Thực thể dữ liệu

- **Người dùng**: Tài khoản đăng nhập hiện có của `flex-auth-service`, giữ nguyên các thuộc tính hiện tại, chỉ chuyển nơi lưu trữ từ Oracle sang PostgreSQL.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**: Không thay đổi so với hành vi hiện có của `flex-auth-service`.

**Ai được thao tác**: Quản trị viên/kỹ sư vận hành: tạo database mới, triển khai phiên bản đã migrate.

**Dữ liệu nhạy cảm**:
- Có. Mật khẩu/thông tin xác thực người dùng. Không thay đổi cách bảo vệ dữ liệu nhạy cảm hiện có khi chuyển sang PostgreSQL.

- **SEC-001**: Việc migrate KHÔNG ĐƯỢC làm suy yếu cơ chế bảo vệ mật khẩu/thông tin xác thực hiện có.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng ở phạm vi migrate datastore này — không có thay đổi về audit trail so với hành vi hiện có của `flex-auth-service`.

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Các luồng xác thực (đăng ký, đăng nhập) trả về kết quả trong thời gian tương đương trải nghiệm hiện tại của `flex-auth-service`, không bị chậm đi do đổi datastore.
- **NFR-002**: Việc chuyển đổi datastore không được làm gián đoạn các dịch vụ khác đang chạy trong môi trường phát triển Flex hiện có.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: `flex-auth-service` vận hành ổn định trên PostgreSQL, không còn bất kỳ kết nối hoặc cấu hình nào trỏ tới Oracle.
- **SC-002**: Toàn bộ luồng xác thực hiện có (đăng ký, đăng nhập, quản lý người dùng) hoạt động đúng như trước khi migrate, không phát sinh lỗi hành vi mới.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- `flex-auth-service` hiện chưa có dữ liệu người dùng thật hay consumer nào đang chạy production — xác nhận bởi stakeholder ngày 2026-07-13; vì vậy không cần kịch bản migrate dữ liệu cũ hay giữ tương thích ngược.
- Multi-tenant, tenant/role, phát hành JWT theo tenant KHÔNG thuộc phạm vi tính năng này — stakeholder xác nhận ngày 2026-07-27 là chưa cần ở giai đoạn này; nếu cần, sẽ là một tính năng riêng sau khi migrate datastore hoàn tất.

**Ràng buộc**:
- PHẢI tuân theo lộ trình bỏ Oracle của hệ thống Flex: sau khi hoàn tất, `flex-auth-service` không còn phụ thuộc Oracle ở bất kỳ hình thức nào.
- Code sản phẩm PHẢI nằm trong repo con `flex-auth-service` (theo nguyên tắc I của constitution); workstation chỉ chứa spec/plan/tài liệu.
- Migration schema của database PostgreSQL mới PHẢI tuân theo quy ước migration PostgreSQL + Liquibase SQL-first đã áp dụng cho database `hnx` trong repo `flex-database` (xem `flex-database/docs/convention.md`), để đảm bảo nhất quán cách quản lý migration giữa các database trong hệ thống Flex. Database mới là một database riêng biệt (thay thế `aspnetidentity` hiện có), không lưu chung trong database `hnx`.

---

## 14. Ngoài phạm vi

- Multi-tenant hoá `flex-auth-service` (tenant, thành viên, vai trò owner/editor/viewer).
- Phát hành/xác minh JWT chứa `tenant_id` + vai trò cho các sản phẩm khác (ví dụ `flex-agent-service`).
- SSO/đăng nhập qua nhà cung cấp ngoài (Google, Microsoft…).
- Đổi/khôi phục mật khẩu qua email, xác thực đa yếu tố (MFA).
- Migrate dữ liệu người dùng thật từ Oracle (không có dữ liệu cần giữ theo giả định mục 13).
- Đảm bảo tương thích ngược cho consumer hiện có của `flex-auth-service` (không có consumer thật theo giả định mục 13).

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Giả định "chưa có dữ liệu/consumer thật" sai lệch so với thực tế tại thời điểm triển khai | Thấp | Cao | Xác nhận lại với stakeholder ngay trước khi bắt đầu migrate; nếu phát sinh dữ liệu thật, tạm dừng và bổ sung kịch bản migrate trước khi tiếp tục |
| Sai lệch schema giữa Oracle và PostgreSQL làm mất ràng buộc nghiệp vụ hiện có | Trung | Cao | Đối chiếu schema Oracle hiện tại với schema PostgreSQL mới trước khi implement; kiểm thử ràng buộc là điều kiện chấp nhận |

---

## 16. Phụ thuộc

- Môi trường hạ tầng phát triển hiện có của workspace Flex (`flex-environment`) — cần PostgreSQL sẵn sàng cho `flex-auth-service`.
- Quy ước migration PostgreSQL + Liquibase SQL-first của repo `flex-database` (đã áp dụng cho database `hnx`, xem `flex-database/docs/convention.md`) — database mới của `flex-auth-service` phải tuân theo cùng quy ước này.

---

## 17. Câu hỏi mở

Không còn câu hỏi mở chặn plan kỹ thuật. Các điểm quan trọng nhất (dữ liệu thật cần bảo toàn, consumer hiện có cần tương thích ngược, phạm vi multi-tenant) đã được stakeholder xác nhận tại thời điểm tạo spec (2026-07-13) và cập nhật (2026-07-27); nếu thực tế thay đổi trước khi triển khai, spec này PHẢI được cập nhật trước khi tiếp tục (xem Rủi ro).

---

## 18. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
