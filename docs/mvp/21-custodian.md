# MVP 21 — Hệ thống lưu ký (Custodian)

## Mục tiêu

Tách biệt lớp lưu ký chứng khoán khỏi sổ sách của CTCK, phản ánh đúng vai trò VSD trong thị trường Việt Nam — nơi lưu ký là bên thứ ba độc lập giữ tài sản.

## Actor và phạm vi

- Custodian service (mô phỏng VSD): lưu danh sách sở hữu CK theo tài khoản lưu ký cuối mỗi ngày.
- Tài khoản lưu ký (securities account) phân biệt với tài khoản giao dịch tại CTCK.
- Custodian xác nhận số CK khả dụng cho CTCK trước khi CTCK cho phép bán.
- Sau settlement T+, custodian cập nhật số dư sở hữu và CTCK đối chiếu với ledger của mình.
- Chuyển khoản CK giữa custodian (gift, pledge, off-market transfer) có audit trail.

## Luồng settlement

1. Trade tại T ghi vào `SettlementObligation` (từ MVP 08).
2. Đến T+2, custodian nhận lệnh chuyển CK từ bên bán sang bên mua.
3. Custodian confirm → CTCK giải phóng tiền thanh toán (DVP đơn giản hoá).
4. Custodian phát EOD statement; CTCK reconcile số CK với ledger.

## Kịch bản demo

Khách hàng mua FXS tại T; đến T+2 tua thời gian; custodian chuyển CK vào tài khoản người mua; người mua thấy số CK khả dụng tăng và có thể bán trong phiên tiếp theo.

## Điều kiện hoàn thành

- Số CK tại custodian luôn khớp với tổng ledger CTCK sau reconcile.
- Bán CK chưa về custodian (chưa qua T+) bị từ chối tại bước kiểm tra trước giao dịch.
- Chưa có pledging CK làm tài sản đảm bảo vay hay custody bank thật.
