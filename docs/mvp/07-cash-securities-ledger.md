# MVP 07 — Ledger tiền và chứng khoán

## Mục tiêu

Thay số dư có thể sửa trực tiếp bằng sổ ghi nhận bất biến và kiểm toán được.

## Phạm vi

- Ledger double-entry rút gọn cho tiền và chứng khoán trong từng tenant.
- Trạng thái tiền/CK: `available`, `reserved`, `receivable`, `payable`.
- Bút toán cho nạp số dư demo, phong tỏa lệnh, khớp, phí và hủy lệnh.

## Quy tắc

- Một bút toán phải có tham chiếu giao dịch nguồn và tổng debit bằng tổng credit.
- Khớp lệnh chỉ chuyển tài sản sang trạng thái phải thu/phải trả; chưa thành sở hữu khả dụng.
- Không sửa hay xóa bút toán; điều chỉnh bằng bút toán đảo/điều chỉnh.

## Kịch bản demo

Một giao dịch Alpha mua/Beta bán tạo đúng các bút toán hai phía; xem được trace từ lệnh đến các dòng ledger và số cân đối.

## Điều kiện hoàn thành

- Có kiểm tra cân bằng ledger và idempotency khi nhận lại event khớp.
- Chưa chạy thanh toán T+, đối chiếu hoặc margin.
