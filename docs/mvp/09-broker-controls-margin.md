# MVP 09 — Kiểm soát CTCK nâng cao

## Mục tiêu

Cho từng tenant có chính sách riêng và mô phỏng một số nghiệp vụ rủi ro cao của CTCK.

## Phạm vi

- Cấu hình phí, room và quy tắc duyệt theo tenant.
- Maker-checker cho chuyển tiền nội bộ hoặc điều chỉnh dữ liệu khách hàng.
- Margin rút gọn: mã đủ điều kiện, sức mua có vay, tỷ lệ duy trì, margin call và force-sell mô phỏng.
- Một corporate action bắt buộc: cổ tức tiền hoặc cổ tức cổ phiếu.

## Quy tắc

- Giao dịch cần duyệt không có hiệu lực cho tới khi checker khác maker phê duyệt.
- Tỷ lệ và room của Alpha không ảnh hưởng Beta.
- Force-sell chỉ sinh đề xuất/lệnh mô phỏng có audit trail, không phải quyết định đầu tư tự động ngoài mô hình.

## Kịch bản demo

Biến động giá làm tài khoản Alpha xuống dưới ngưỡng; hệ thống tạo margin call. Một thao tác cần duyệt được maker tạo và checker phê duyệt; Beta có ngưỡng khác.

## Điều kiện hoàn thành

- Không làm đầy đủ lệnh điều kiện, phái sinh hay mọi loại corporate action.
