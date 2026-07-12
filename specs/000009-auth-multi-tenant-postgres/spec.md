# Đặc tả tính năng: Multi-tenant hoá flex-auth-service + migrate PostgreSQL

**Branch**: `000009-auth-multi-tenant-postgres`
**Ngày tạo**: 2026-07-13
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Mô tả người dùng: "Chuyển đổi flex-auth-service từ single-tenant sang multi-tenant identity provider dùng chung cho toàn hệ thống Flex: quản lý tenant, thành viên và vai trò (owner/editor/viewer) theo từng tenant, phát hành JWT chứa tenant_id + role. Đồng thời migrate datastore của flex-auth-service từ Oracle sang PostgreSQL. Đây là nền tảng identity dùng chung để flex-agent-service (000008-agent-platform-mvp) và các sản phẩm multi-tenant khác trong tương lai gọi qua, thay vì mỗi service tự quản lý user/tenant/membership riêng."

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

`flex-auth-service` hiện là dịch vụ xác thực single-tenant, chạy trên Oracle. Tính năng `000008-agent-platform-mvp` (nền tảng AI Agent đa tenant) cần một cơ chế identity biết về khái niệm tenant và vai trò theo tenant (chủ tenant/biên tập/xem) — nếu để `flex-agent-service` tự xây dựng identity riêng, hệ thống Flex sẽ có nhiều nguồn sự thật khác nhau về "người dùng là ai, thuộc tenant nào, có quyền gì", gây trùng lặp logic đăng nhập/phân quyền và khó mở rộng khi có thêm sản phẩm multi-tenant khác sau này.

Song song đó, hệ thống Flex đang trong lộ trình bỏ Oracle dần (đã áp dụng cho các tính năng mới như `000005-mysql-tenant-db`, `000008-agent-platform-mvp`); `flex-auth-service` là một trong các dịch vụ còn phụ thuộc Oracle cần được refactor theo lộ trình này. `flex-auth-service` hiện chưa có consumer hay dữ liệu người dùng thật chạy production, nên đây là thời điểm phù hợp để thực hiện cả hai thay đổi cùng lúc mà không phải xử lý tương thích ngược hay migrate dữ liệu cũ.

**Tổng quan tính năng**:

Chuyển `flex-auth-service` thành **identity provider dùng chung** cho toàn hệ thống Flex: quản lý tenant, user, thành viên và vai trò theo từng tenant (owner/editor/viewer), phát hành JWT mang theo `tenant_id` + vai trò. Datastore chuyển từ Oracle sang PostgreSQL. Các sản phẩm multi-tenant khác (bắt đầu với `flex-agent-service`) xác thực người dùng và đọc thông tin tenant/vai trò qua dịch vụ này thay vì tự quản lý.

---

## 1. Mục tiêu

- **MT-001**: Một sản phẩm multi-tenant mới trong hệ thống Flex (bắt đầu là `flex-agent-service`) xác thực người dùng và xác định đúng tenant + vai trò của người dùng đó thông qua `flex-auth-service`, không cần tự xây dựng lại cơ chế user/tenant/membership.
- **MT-002**: `flex-auth-service` vận hành hoàn toàn trên datastore mới (PostgreSQL), không còn phụ thuộc Oracle.
- **MT-003**: Quản trị viên nền tảng khởi tạo được tenant mới và tài khoản chủ tenant đầu tiên tại một nơi duy nhất, dùng chung cho mọi sản phẩm multi-tenant.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Khởi tạo tenant mới trong `flex-auth-service` kèm tài khoản chủ tenant đầu tiên (đăng ký vào danh bạ tenant dùng chung).
- **MVP-002**: Quản lý thành viên và vai trò (owner/editor/viewer) trong phạm vi một tenant.
- **MVP-003**: Đăng nhập và phát hành JWT chứa `tenant_id` + vai trò của người dùng, dùng được bởi bất kỳ sản phẩm nào trong hệ thống Flex tin cậy `flex-auth-service`.
- **MVP-004**: Một API/cơ chế để sản phẩm khác (ví dụ `flex-agent-service`) xác minh JWT và đọc thông tin tenant/vai trò mà không cần truy vấn trực tiếp dữ liệu nội bộ của `flex-auth-service`.
- **MVP-005**: Toàn bộ dữ liệu identity (user, tenant, membership) vận hành trên datastore mới, không còn dữ liệu hay kết nối tới Oracle.
- **MVP-006**: Giới hạn MVP: không bao gồm SSO/OAuth với nhà cung cấp ngoài, không đổi mật khẩu qua email, không MFA — giữ đúng các khả năng hiện có của `flex-auth-service` cộng thêm khái niệm tenant/vai trò.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**:

- **Quản trị viên nền tảng**: khởi tạo tenant mới, quản lý danh bạ tenant toàn hệ thống.
- **Chủ tenant**: quản lý thành viên và vai trò trong tenant của mình.
- **Thành viên tenant**: đăng nhập, được cấp vai trò biên tập hoặc xem trong tenant.
- **Sản phẩm/dịch vụ khác trong hệ thống Flex** (ví dụ `flex-agent-service`): xác thực người dùng cuối và đọc thông tin tenant/vai trò qua `flex-auth-service` thay vì tự quản lý.

**Bối cảnh sử dụng**: Quản trị viên nền tảng và chủ tenant thao tác qua giao diện/API quản trị của `flex-auth-service`. Các sản phẩm khác gọi `flex-auth-service` ở mỗi lần người dùng đăng nhập hoặc mỗi khi cần xác minh phiên làm việc.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Quản trị viên nền tảng là kỹ thuật. Chủ tenant và thành viên là người dùng nghiệp vụ, không chuyên kỹ thuật.

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khởi tạo tenant và chủ tenant trong identity provider dùng chung (Ưu tiên: P1)

Quản trị viên nền tảng khởi tạo một tenant mới trong `flex-auth-service`. Hệ thống đăng ký tenant vào danh bạ dùng chung và tạo tài khoản chủ tenant đầu tiên, để chủ tenant đăng nhập được ngay sau đó — bất kể tenant này sẽ dùng cho sản phẩm nào (agent platform hay sản phẩm khác sau này).

**Lý do ưu tiên**: Là nền tảng cho mọi kịch bản khác; không có tenant/chủ tenant thì không có gì để phân quyền hay xác thực.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Tạo tenant mới, xác nhận chủ tenant đăng nhập được và nhận JWT chứa đúng `tenant_id` + vai trò owner.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một yêu cầu tạo tenant hợp lệ, **Khi** quản trị viên nền tảng khởi tạo tenant, **Thì** tenant xuất hiện trong danh bạ dùng chung ở trạng thái hoạt động và tài khoản chủ tenant được tạo với vai trò owner.
2. **AC-002**: **Cho trước** một tenant đã tồn tại, **Khi** khởi tạo lại với cùng định danh, **Thì** hệ thống từ chối và báo tenant đã tồn tại.

---

### US-002 — Quản lý thành viên và vai trò trong tenant (Ưu tiên: P1)

Chủ tenant mời thành viên vào tenant của mình và gán vai trò: biên tập hoặc xem. Chỉ chủ tenant được quản lý thành viên và thay đổi vai trò.

**Lý do ưu tiên**: Là điều kiện để các sản phẩm tiêu thụ identity provider (như `flex-agent-service`) có RBAC theo tenant hoạt động đúng ngay từ đầu.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Chủ tenant thêm một thành viên vai trò xem, xác nhận thành viên đăng nhập được và JWT phản ánh đúng vai trò xem.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** chủ tenant đã đăng nhập, **Khi** thêm thành viên mới với một vai trò, **Thì** thành viên xuất hiện trong danh sách tenant với đúng vai trò đã gán.
2. **AC-004**: **Cho trước** một thành viên đã có vai trò, **Khi** chủ tenant đổi vai trò, **Thì** lần đăng nhập/JWT kế tiếp của thành viên đó phản ánh vai trò mới.
3. **AC-005**: **Cho trước** người dùng không phải chủ tenant, **Khi** cố quản lý thành viên, **Thì** hệ thống từ chối.

---

### US-003 — Đăng nhập và xác thực qua identity provider dùng chung (Ưu tiên: P1)

Người dùng (chủ tenant hoặc thành viên) đăng nhập vào `flex-auth-service`. Hệ thống xác thực và trả về JWT chứa danh tính, `tenant_id` và vai trò trong tenant đó. Bất kỳ sản phẩm nào trong hệ thống Flex tin cậy `flex-auth-service` đều xác minh được JWT này mà không cần hỏi lại thông tin thành viên/vai trò.

**Lý do ưu tiên**: Là giá trị cốt lõi của việc có một identity provider dùng chung — nếu sản phẩm khác vẫn phải tự tra cứu vai trò, mục tiêu MT-001 không đạt được.

**Liên quan yêu cầu**: FR-006, FR-007, FR-008

**Test độc lập**: Đăng nhập, lấy JWT, xác minh JWT ở một dịch vụ khác (giả lập) và đọc đúng `tenant_id` + vai trò mà không gọi thêm API tra cứu.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** thông tin đăng nhập hợp lệ của một thành viên tenant, **Khi** đăng nhập, **Thì** hệ thống trả về JWT chứa `tenant_id` và vai trò đúng với thành viên đó.
2. **AC-007**: **Cho trước** một JWT hợp lệ do `flex-auth-service` phát hành, **Khi** một dịch vụ khác xác minh JWT, **Thì** dịch vụ đó xác định đúng danh tính, tenant và vai trò mà không cần gọi thêm API.
3. **AC-008**: **Cho trước** JWT hết hạn hoặc không hợp lệ, **Khi** dùng để gọi một dịch vụ khác, **Thì** yêu cầu bị từ chối.

---

### US-004 — Vận hành hoàn toàn trên datastore mới, không còn phụ thuộc Oracle (Ưu tiên: P1)

Quản trị viên nền tảng triển khai `flex-auth-service` phiên bản mới; toàn bộ dữ liệu user, tenant, membership được lưu trữ trên datastore mới. Không còn kết nối hay phụ thuộc vào Oracle ở bất kỳ luồng nào.

**Lý do ưu tiên**: Là yêu cầu bắt buộc theo lộ trình bỏ Oracle của hệ thống; vì `flex-auth-service` chưa có dữ liệu/consumer thật, đây là thời điểm ít rủi ro nhất để thực hiện.

**Liên quan yêu cầu**: FR-009, FR-010

**Test độc lập**: Khởi động `flex-auth-service` phiên bản mới trong môi trường không có Oracle, thực hiện trọn luồng US-001 đến US-003 thành công.

**Acceptance Criteria**:

1. **AC-009**: **Cho trước** môi trường triển khai không có Oracle, **Khi** `flex-auth-service` khởi động và vận hành, **Thì** mọi luồng tạo tenant, quản lý thành viên, đăng nhập đều hoạt động bình thường.
2. **AC-010**: **Cho trước** cấu hình dịch vụ, **Khi** kiểm tra kết nối/dependency, **Thì** không còn tham chiếu tới Oracle (connection string, wallet, driver) trong cấu hình chạy.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Hệ thống mới chưa có tenant nào → danh bạ tenant trống, chỉ quản trị viên nền tảng thao tác được.
- **Dữ liệu không hợp lệ**: Thông tin tạo tenant/thành viên thiếu trường bắt buộc hoặc sai định dạng bị từ chối kèm lý do.
- **Không có quyền**: Thao tác ngoài vai trò được cấp bị từ chối, không lộ dữ liệu ngoài phạm vi tenant.
- **Lỗi hệ thống**: Nếu datastore không sẵn sàng, yêu cầu đăng nhập/xác thực bị từ chối rõ ràng, không để hệ thống ở trạng thái không xác định.
- **Timeout**: Không áp dụng — nằm trong yêu cầu phi chức năng NFR-001.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng ở MVP — thao tác quản lý thành viên là ghi đè trực tiếp, không có luồng chỉnh sửa đồng thời phức tạp.
- **Người dùng thao tác lặp lại**: Khởi tạo lại tenant đã tồn tại bị từ chối (AC-002). Thêm lại thành viên đã tồn tại trong tenant → cập nhật vai trò thay vì tạo bản ghi trùng.
- **Trường hợp biên khác**: Xoá vai trò của thành viên cuối cùng có vai trò owner trong một tenant → hệ thống KHÔNG ĐƯỢC cho phép, tenant luôn phải có ít nhất một owner.

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cho phép quản trị viên nền tảng khởi tạo tenant mới và ghi vào danh bạ tenant dùng chung.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống KHÔNG ĐƯỢC tạo trùng tenant với cùng định danh.
  **Liên quan**: US-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI tạo tài khoản chủ tenant đầu tiên (vai trò owner) khi khởi tạo tenant.
  **Liên quan**: US-001, AC-001
- **FR-004** `[P1]`: Chủ tenant PHẢI quản lý được thành viên trong tenant của mình: thêm, đổi vai trò, gỡ khỏi tenant.
  **Liên quan**: US-002, AC-003, AC-004
- **FR-005** `[P1]`: Hệ thống PHẢI chặn người dùng không phải chủ tenant thực hiện quản lý thành viên.
  **Liên quan**: US-002, AC-005
- **FR-006** `[P1]`: Hệ thống PHẢI xác thực đăng nhập và phát hành JWT chứa danh tính người dùng, `tenant_id` và vai trò trong tenant đó.
  **Liên quan**: US-003, AC-006
- **FR-007** `[P1]`: Sản phẩm khác trong hệ thống Flex PHẢI xác minh được JWT do `flex-auth-service` phát hành và đọc đúng `tenant_id` + vai trò mà không cần gọi thêm API tra cứu.
  **Liên quan**: US-003, AC-007
- **FR-008** `[P1]`: Hệ thống PHẢI từ chối JWT hết hạn hoặc không hợp lệ.
  **Liên quan**: US-003, AC-008
- **FR-009** `[P1]`: Toàn bộ dữ liệu user, tenant, membership PHẢI được lưu trữ và vận hành trên datastore mới, không phải Oracle.
  **Liên quan**: US-004, AC-009
- **FR-010** `[P1]`: Cấu hình vận hành của `flex-auth-service` KHÔNG ĐƯỢC còn tham chiếu tới Oracle (connection string, driver, wallet).
  **Liên quan**: US-004, AC-010
- **FR-011** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép một tenant không còn thành viên nào giữ vai trò owner.
  **Liên quan**: US-002, mục 5 "Trường hợp biên khác"

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Mỗi tenant luôn có ít nhất một thành viên vai trò owner; không cho phép thao tác khiến tenant rơi vào trạng thái không có owner.
- **BR-002**: Chỉ chủ tenant (owner) được quản lý thành viên và vai trò trong tenant của mình; người biên tập và người xem không có quyền này.
- **BR-003**: Danh tính tenant và vai trò của một yêu cầu PHẢI được hệ thống xác định từ JWT đã xác thực, KHÔNG ĐƯỢC tin theo giá trị do client tự khai.
- **BR-004**: Một tài khoản người dùng thuộc về một tenant; MVP không hỗ trợ một người dùng có vai trò ở nhiều tenant cùng lúc.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| (chưa có) | Khởi tạo tenant | Tenant hoạt động, có 1 owner | Quản trị viên nền tảng |
| Tenant hoạt động | Thêm thành viên | Thành viên có vai trò trong tenant | Chỉ chủ tenant |
| Thành viên có vai trò | Đổi vai trò | Vai trò mới có hiệu lực | Chỉ chủ tenant, không được xoá owner cuối cùng |
| Thành viên có vai trò | Gỡ khỏi tenant | Không còn quyền truy cập tenant | Chỉ chủ tenant, không được gỡ owner cuối cùng |

---

## 8. Thực thể dữ liệu

- **Tenant**: Đơn vị tổ chức dùng chung cho mọi sản phẩm multi-tenant trong hệ thống Flex; có định danh duy nhất và trạng thái hoạt động.
- **Người dùng**: Tài khoản đăng nhập, thuộc về đúng một tenant.
- **Thành viên & vai trò**: Quan hệ giữa người dùng và tenant, mang vai trò owner/editor/viewer, quyết định quyền thao tác trong tenant đó và trong các sản phẩm tiêu thụ identity provider này.
- **Phiên đăng nhập/JWT**: Bằng chứng xác thực mang theo danh tính, tenant và vai trò, được các sản phẩm khác tin cậy để xác định quyền truy cập.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**:
- Quản trị viên nền tảng: danh bạ tenant toàn hệ thống.
- Chủ tenant, thành viên: thông tin thành viên và vai trò trong tenant của mình.

**Ai được thao tác**:
- Quản trị viên nền tảng: khởi tạo tenant.
- Chủ tenant: quản lý thành viên và vai trò trong tenant của mình.
- Sản phẩm khác trong hệ thống Flex: xác minh JWT, đọc thông tin tenant/vai trò (không sửa).

**Ai không được phép**:
- Người dùng của tenant A xem hoặc thao tác dữ liệu thành viên của tenant B.
- Thành viên vai trò editor/viewer quản lý thành viên khác.

**Dữ liệu nhạy cảm**:
- Có. Mật khẩu/thông tin xác thực người dùng, danh sách thành viên và vai trò của từng tenant. Không hiển thị mật khẩu hoặc secret ký JWT cho người dùng.

- **SEC-001**: Hệ thống PHẢI kiểm tra vai trò trước khi cho phép quản lý thành viên.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho một tenant truy cập hoặc sửa dữ liệu thành viên của tenant khác.
- **SEC-003**: JWT PHẢI được ký và có thời hạn; sản phẩm tiêu thụ PHẢI xác minh chữ ký trước khi tin nội dung `tenant_id`/vai trò bên trong.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Có

Hệ thống PHẢI ghi nhận:

- Khởi tạo tenant (ai thực hiện, tenant nào, thời điểm, kết quả).
- Thêm/đổi vai trò/gỡ thành viên (ai thực hiện, thành viên nào, vai trò trước/sau, thời điểm).

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Xác thực đăng nhập và xác minh JWT trả về kết quả trong thời gian tương đương trải nghiệm ứng dụng web thông thường (dưới vài giây) để không làm chậm luồng đăng nhập của các sản phẩm tiêu thụ.
- **NFR-002**: Việc chuyển đổi datastore không được làm gián đoạn các dịch vụ khác đang chạy trong môi trường phát triển Flex hiện có.
- **NFR-003**: Cách ly dữ liệu giữa các tenant là tuyệt đối trong mọi luồng đọc/ghi thành viên và vai trò.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Quản trị viên nền tảng khởi tạo một tenant mới và chủ tenant đăng nhập thành công trong vòng vài phút, không cần can thiệp kỹ thuật thủ công.
- **SC-002**: Một sản phẩm khác (ví dụ `flex-agent-service`) xác minh JWT và lấy đúng `tenant_id` + vai trò mà không cần triển khai thêm logic quản lý user/tenant riêng.
- **SC-003**: 100% kiểm thử cách ly xuyên tenant đối với thành viên/vai trò đều bị chặn hoặc không lộ dữ liệu.
- **SC-004**: Sau khi hoàn tất, hệ thống vận hành ổn định mà không còn bất kỳ kết nối hoặc cấu hình nào trỏ tới Oracle.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- `flex-auth-service` hiện chưa có dữ liệu người dùng thật hay consumer nào đang chạy production — xác nhận bởi stakeholder ngày 2026-07-13; vì vậy không cần kịch bản migrate dữ liệu cũ hay giữ tương thích ngược.
- `flex-agent-service` (`000008-agent-platform-mvp`) là consumer đầu tiên và ưu tiên nhất của identity provider dùng chung này; plan của `000008` sẽ được cập nhật để gọi qua `flex-auth-service` thay vì tự quản lý identity.
- Một người dùng chỉ thuộc một tenant ở MVP (BR-004); mở rộng multi-membership để giai đoạn sau nếu cần.

**Ràng buộc**:
- PHẢI tuân theo lộ trình bỏ Oracle của hệ thống Flex: sau khi hoàn tất, `flex-auth-service` không còn phụ thuộc Oracle ở bất kỳ hình thức nào.
- Code sản phẩm PHẢI nằm trong repo con `flex-auth-service` (theo nguyên tắc I của constitution); workstation chỉ chứa spec/plan/tài liệu.
- Danh tính tenant dùng chung này PHẢI dùng cùng khái niệm `tenant_id` với các repo khác trong hệ thống (ví dụ `tenant_databases` của `000005-mysql-tenant-db`) để tránh có hai định danh tenant khác nhau trong cùng hệ thống — cách hợp nhất cụ thể do plan kỹ thuật quyết định.

---

## 14. Ngoài phạm vi

- SSO/đăng nhập qua nhà cung cấp ngoài (Google, Microsoft…).
- Đổi/khôi phục mật khẩu qua email, xác thực đa yếu tố (MFA).
- Một người dùng có vai trò ở nhiều tenant cùng lúc (multi-membership).
- Migrate dữ liệu người dùng thật từ Oracle (không có dữ liệu cần giữ theo giả định mục 13).
- Đảm bảo tương thích ngược cho consumer hiện có của `flex-auth-service` (không có consumer thật theo giả định mục 13).
- Cập nhật chi tiết kỹ thuật của `flex-agent-service` để gọi qua identity provider mới — thuộc phạm vi cập nhật plan của `000008-agent-platform-mvp`, không phải spec này.

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Giả định "chưa có dữ liệu/consumer thật" sai lệch so với thực tế tại thời điểm triển khai | Thấp | Cao | Xác nhận lại với stakeholder ngay trước khi bắt đầu migrate; nếu phát sinh dữ liệu thật, tạm dừng và bổ sung kịch bản migrate trước khi tiếp tục |
| Khái niệm `tenant_id` của `flex-auth-service` không khớp với `tenant_id` đã dùng ở `000005`/`000008` | Trung | Cao | Plan kỹ thuật PHẢI đối chiếu và hợp nhất định danh tenant giữa các repo trước khi implement |
| Rò rỉ dữ liệu xuyên tenant qua API quản lý thành viên | Thấp | Cao | Kiểm thử cách ly là điều kiện chấp nhận bắt buộc (SC-003) |
| Trì hoãn `000008-agent-platform-mvp` vì phải chờ `flex-auth-service` hoàn tất trước | Trung | Trung | Plan kỹ thuật của cả hai feature cần thống nhất thứ tự/ranh giới rollout |

---

## 16. Phụ thuộc

- `000008-agent-platform-mvp`: là consumer đầu tiên, cần cập nhật plan để tiêu thụ identity provider dùng chung này thay vì tự quản lý identity (theo quyết định đã thống nhất, thay thế DEC-005 cũ của `000008`).
- `000005-mysql-tenant-db`: nguồn khái niệm `tenant_id`/danh bạ tenant hiện có cần đối chiếu để tránh trùng lặp định danh tenant trong hệ thống.
- Môi trường hạ tầng phát triển hiện có của workspace Flex (`flex-environment`) — cần PostgreSQL sẵn sàng cho `flex-auth-service`.

---

## 17. Câu hỏi mở

Không còn câu hỏi mở chặn plan kỹ thuật. Hai điểm quan trọng nhất (dữ liệu thật cần bảo toàn, consumer hiện có cần tương thích ngược) đã được stakeholder xác nhận là "không" tại thời điểm tạo spec (2026-07-13); nếu thực tế thay đổi trước khi triển khai, spec này PHẢI được cập nhật trước khi tiếp tục (xem Rủi ro).

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
