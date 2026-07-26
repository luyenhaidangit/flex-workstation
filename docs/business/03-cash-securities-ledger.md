# Nghiệp vụ MVP 07 — Ledger tiền và chứng khoán

## Mục đích và phạm vi

MVP này mô phỏng sổ theo dõi tài sản của một công ty chứng khoán sau khi lệnh được tiếp nhận và khớp. Mục tiêu là bảo đảm mọi thay đổi tiền và chứng khoán đều có lịch sử cân bằng, có thể giải thích và truy vết lại từ lệnh hoặc giao dịch nguồn. MVP này tập trung vào ghi nhận và kiểm tra số dư; thanh toán T+, đối chiếu cuối ngày và kết nối hệ thống bên ngoài sẽ được thực hiện ở các MVP sau. Chi tiết nguồn được ghi trong [đặc tả tính năng](../../specs/000016-cash-securities-ledger/spec.md).

## Bối cảnh nghiệp vụ

Trong giao dịch chứng khoán, một lệnh mua hoặc bán không chỉ tạo ra trạng thái “đã khớp”. Nó còn làm thay đổi tiền mặt, số chứng khoán được phép sử dụng, phần tài sản đang bị giữ cho lệnh và các khoản phải thu hoặc phải trả. Khi có phí giao dịch hoặc hủy lệnh, người vận hành cần biết chính xác tài sản nào đã thay đổi, vì lý do gì và thay đổi đó liên quan đến giao dịch nào.

MVP này dùng một sổ nghiệp vụ bất biến: mỗi biến động được ghi thành một cặp tăng/giảm cân bằng. Số dư hiện tại được suy ra từ lịch sử đó, thay vì sửa trực tiếp một con số mà không còn dấu vết.

## Vai trò trong thị trường thực tế

```text
Khách hàng → Công ty chứng khoán/Broker → Sàn giao dịch → Lưu ký và thanh toán
                         │                         │
                         └─ Phạm vi MVP 07 ────────┘
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Khách hàng | Đặt lệnh, mua/bán và chịu phí tương ứng | Được đại diện bởi tài khoản demo |
| Broker/công ty chứng khoán | Kiểm tra sức mua, giữ tài sản, ghi nhận giao dịch và phí | Phát sinh các biến động ledger |
| Sàn giao dịch | Khớp lệnh và phát sự kiện giao dịch | Cung cấp sự kiện khớp cho Broker |
| Bộ phận vận hành/kiểm soát | Kiểm tra số dư, truy vết và xử lý điều chỉnh | Xem balance, trace và tạo điều chỉnh được cấp quyền |
| Hệ thống lưu ký/thanh toán | Hoàn tất chuyển giao sau ngày giao dịch | Ngoài phạm vi MVP này |

## Luồng nghiệp vụ đầu-cuối

1. Khách hàng gửi lệnh đến Broker. Việc kiểm tra tài khoản và sức mua thuộc luồng Broker của MVP trước.
2. Broker giữ tiền hoặc chứng khoán để bảo đảm lệnh. **Trong phạm vi MVP 07**, việc giữ này phải được ghi vào sổ.
3. Sàn giao dịch khớp toàn bộ hoặc một phần lệnh. **Trong phạm vi MVP 07**, sự kiện khớp tạo ra biến động tài sản tương ứng.
4. Phí giao dịch được ghi riêng và gắn với bên phát sinh giao dịch. **Trong phạm vi MVP 07**.
5. Nếu lệnh bị hủy, phần tài sản chưa sử dụng được trả về trạng thái có thể dùng. **Trong phạm vi MVP 07**.
6. Người vận hành xem số dư theo từng trạng thái và truy vết từ lệnh/giao dịch đến các dòng sổ. **Trong phạm vi MVP 07**.
7. Các khoản phải thu/phải trả được giữ lại cho đến khi có quy trình thanh toán. **Thanh toán T+ và đối chiếu thuộc MVP 08**.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Tài khoản ledger | Tài khoản tiền hoặc chứng khoán của một khách hàng trong một tenant |
| Dòng sổ | Một biến động tăng hoặc giảm tài sản, không được sửa hoặc xóa |
| Journal | Nhóm dòng sổ cân bằng, đại diện cho một biến động nghiệp vụ |
| Giao dịch nguồn | Lệnh, lần khớp, phí, nạp ban đầu hoặc hủy lệnh làm phát sinh journal |
| Số dư theo trạng thái | Số tài sản đang khả dụng, bị giữ, phải thu hoặc phải trả |
| Trace | Lịch sử journal liên quan đến một lệnh hoặc giao dịch nguồn |

## Quy tắc nghiệp vụ

- **BR-001 — Cân bằng hai phía:** Mỗi biến động phải có tổng tăng bằng tổng giảm. Đây là nguyên tắc kiểm soát sổ sách, giúp phát hiện thiếu hoặc ghi thừa tài sản.
- **BR-002 — Lịch sử bất biến:** Dòng đã ghi không được sửa hoặc xóa. Nếu phát hiện sai, phải tạo một biến động đảo/điều chỉnh có liên kết với dòng gốc để vẫn giữ được lịch sử kiểm toán.
- **BR-003 — Chưa thanh toán thì chưa khả dụng:** Sau khi khớp, tài sản liên quan chuyển sang phải thu/phải trả; không được coi là tiền hoặc chứng khoán có thể sử dụng ngay.
- **BR-004 — Cô lập tenant:** Sổ của tenant này không được dùng để xem hoặc thay đổi tài sản của tenant khác. Đây là yêu cầu bảo mật và phân tách khách hàng.
- **BR-005 — Không ghi trùng:** Một sự kiện nguồn chỉ tạo một journal. Việc gửi lại do retry mạng không được làm tăng số dư lần thứ hai.
- **BR-006 — Phí thuộc về bên phát sinh:** Phí của giao dịch mua/bán được ghi cho đúng bên chịu phí và phải liên kết với giao dịch nguồn để có thể giải thích.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Nạp số dư ban đầu | Tài khoản có số dư khả dụng và có journal opening để đối chiếu |
| Đặt lệnh mua | Tiền mua được chuyển từ khả dụng sang bị giữ |
| Đặt lệnh bán | Chứng khoán bán được chuyển từ khả dụng sang bị giữ |
| Khớp lệnh | Phần đã khớp chuyển sang phải thu/phải trả, không quay lại khả dụng ngay |
| Phát sinh phí | Có dòng phí riêng, ghi cho bên chịu phí và liên kết giao dịch |
| Hủy lệnh còn dư | Phần bị giữ nhưng chưa dùng được trả về khả dụng |
| Nhận lại cùng sự kiện | Trả kết quả journal cũ, không ghi thêm biến động |
| Truy vấn tenant khác | Từ chối và không tiết lộ số dư hay lịch sử |
| Phát hiện journal sai | Không sửa journal cũ; tạo journal điều chỉnh có lý do và liên kết |
| Không có dữ liệu | Trả số dư bằng không và lịch sử rỗng, không coi là lỗi hệ thống |

## Ngoài phạm vi

- **Thanh toán và hậu kiểm:** clearing, settlement T+, nghĩa vụ thanh toán và đối chiếu cuối ngày — dự kiến ở MVP 08.
- **Tích hợp bên ngoài:** kết nối ngân hàng, VSDC hoặc ledger kế toán production — các giai đoạn tích hợp sau.
- **Sản phẩm nâng cao:** margin, collateral, phái sinh và quản trị rủi ro nâng cao — chưa thuộc roadmap MVP hiện tại.
- **Lưu trữ production:** sổ bền vững qua restart, migration và recovery production — MVP này chỉ phục vụ quy mô mô phỏng.

## Truy vết và nguồn tham khảo

- [Cấu trúc thị trường chứng khoán Việt Nam](00-vietnamese-securities-market-structure.md): thuật ngữ và phân biệt VNX/HOSE/HNX/market dùng chung.
- [Đặc tả tính năng](../../specs/000016-cash-securities-ledger/spec.md): mục tiêu, user story, quy tắc và phạm vi MVP.
- [Kế hoạch triển khai](../../specs/000016-cash-securities-ledger/plan.md): thiết kế kỹ thuật và chiến lược kiểm thử dành cho đội phát triển.
- [MVP 06 — Multi-tenant brokers](../mvp/06-multi-tenant-brokers.md): tenant, Broker và tài khoản đầu vào của MVP 07.
- [MVP 08 — Database, pipeline, clearing, settlement và reconciliation](../mvp/08-database-pipeline-clearing-settlement-reconciliation.md): các quy trình tiếp nối sau khi ledger ghi nhận giao dịch.
