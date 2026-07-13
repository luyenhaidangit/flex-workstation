# MVP 08 — Clearing, settlement và đối chiếu

## Mục tiêu

Mô phỏng đúng giai đoạn sau khớp: giao dịch tạo nghĩa vụ trước, rồi mới hoàn tất thanh toán.

## Phạm vi

- `ClearingSettlement` ảo nhận giao dịch đã khớp.
- Tạo nghĩa vụ tiền/CK theo broker; day cycle T+ tua nhanh.
- Statement EOD giả lập và job đối chiếu với ledger CTCK.
- Có chế độ tiêm một lỗi lệch xác định trước.

## Luồng chính

1. Trade ở T tạo `SettlementObligation`.
2. Đến T+, hệ thống kiểm tra nghĩa vụ và chuyển `receivable/payable` thành số dư đã thanh toán.
3. CTCK nhận statement EOD, đối chiếu tổng và chi tiết, sau đó ghi nhận kết quả.

## Kịch bản demo

Chạy một ngày ảo có giao dịch, tua đến T+, xem CK/tiền thành khả dụng. Lặp lại với một lỗi tiêm để thấy reconciliation alert có reference tới giao dịch nguồn.

## Điều kiện hoàn thành

- Không kết nối VSDC, ngân hàng hay file thật.
- Chưa dùng AI để tự xử lý chênh lệch.
