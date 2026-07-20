# Research: Persist MVP 1 Matching Engine bằng DB

## Phạm vi khảo sát

- `flex-exchange-service`: matching rules, order book và các state hiện đang in-memory.
- `flex-database/hnx`: Liquibase migrations cho bốn bảng MVP 1: `exchange_instruments`, `exchange_sessions`, `exchange_orders`, `exchange_trades`.
- `flex-microfrontend`: exchange API consumers cần giữ contract.

## Quyết định

### TQ-001 — Bảng nào thuộc MVP 1?

Chỉ dùng `exchange_instruments`, `exchange_sessions`, `exchange_orders`, `exchange_trades`. Không tạo `exchange_order_history`, `exchange_outbox` hoặc bảng `exchange_order_book` riêng.

### TQ-002 — Order book lưu thế nào?

Không lưu snapshot riêng. Dựng order book từ các order chưa `FILLED`/`CANCELLED` với `remaining_quantity > 0`, sắp xếp price-time ở query/service.

### TQ-003 — Transaction boundary?

Một matching operation phải cập nhật buy order, sell order và insert trade trong cùng database transaction.

### TQ-004 — Persistence boundary?

Application định nghĩa focused ports; Infrastructure dùng Npgsql. Không thêm generic repository hoặc database-specific type vào Application.

### TQ-005 — Migration safety?

Liquibase forward-only, changeset mới không sửa changeset đã chạy. Seed instrument/session idempotent. Không dùng destructive rollback.

### TQ-006 — `market` biểu diễn khái niệm gì?

`market` là phân đoạn giao dịch nơi lệnh và công cụ được quản lý, không phải tên tổ chức sở hữu sàn. Vì vậy không dùng `VNX` làm giá trị `market`: VNX là công ty mẹ của HOSE và HNX, không phải thị trường khớp lệnh.

Các giá trị định hướng khi mở rộng gồm:

| Giá trị | Phân đoạn giao dịch | Đơn vị vận hành | Sản phẩm chính |
| --- | --- | --- | --- |
| `HOSE` | Cổ phiếu niêm yết tại TP. Hồ Chí Minh | HOSE | Cổ phiếu, ETF, chứng quyền, quỹ niêm yết |
| `HNX` | Cổ phiếu niêm yết tại Hà Nội | HNX | Cổ phiếu niêm yết |
| `UPCOM` | Cổ phiếu đăng ký giao dịch | HNX | Cổ phiếu công ty đại chúng chưa niêm yết |
| `GOV_BOND` | Trái phiếu Chính phủ | HNX | Trái phiếu Chính phủ, chính quyền địa phương, được Chính phủ bảo lãnh |
| `CORP_BOND_LISTED` | Trái phiếu doanh nghiệp niêm yết | HNX | Trái phiếu doanh nghiệp niêm yết |
| `CORP_BOND_PRIVATE` | Trái phiếu doanh nghiệp riêng lẻ | HNX | Trái phiếu doanh nghiệp phát hành riêng lẻ |
| `DERIVATIVES` | Chứng khoán phái sinh | HNX | Hợp đồng tương lai và các sản phẩm phái sinh |

HNX hiện công bố vận hành các thị trường cổ phiếu niêm yết, UPCoM, trái phiếu Chính phủ, trái phiếu doanh nghiệp, trái phiếu doanh nghiệp riêng lẻ và chứng khoán phái sinh. Nguồn: [HNX — Hỏi đáp](https://upcom.hnx.vn/vi-vn/hoi-dap.html).

MVP 1 chỉ mô phỏng khớp lệnh cổ phiếu niêm yết tại HNX. Vì vậy `exchange_instruments.market` và `exchange_sessions.market` chỉ nhận giá trị `HNX` trong phạm vi feature này. Các giá trị còn lại là quy ước mở rộng, không phải yêu cầu triển khai hiện tại.

### TQ-007 — `correlation_id` dùng UUID thế nào?

Giữ `correlation_id UUID` trong `exchange_orders` và `exchange_trades`. BE xác thực `X-Correlation-Id` là UUID tại API boundary; header không hợp lệ trả `400 Problem Details`. Nếu header không được gửi, BE tự sinh UUID hợp lệ. Quyết định này là breaking change có chủ đích đối với client đang gửi chuỗi không phải UUID, nhưng tránh phải ép UUID sang `VARCHAR` hoặc thực hiện mapping mất tính truy vết.

### TQ-008 — Trạng thái order map sang DB thế nào?

BE dùng `Open`, `PartiallyFilled`, `Filled`, `Cancelled`, `Rejected` làm trạng thái domain/API. Persistence adapter sẽ map chúng lần lượt sang `open`, `partially_filled`, `filled`, `cancelled`, `rejected` ở DB. `Pending` bị loại bỏ vì không có ý nghĩa riêng với `Open` trong MVP 1. Việc đổi giá trị `status` trả bởi `GET /api/orders/{id}` từ `Pending` sang `Open` là breaking change có chủ đích.

## Kết luận

MVP 1 là một vertical slice DB-backed cho matching engine. Các nghiệp vụ order history, event delivery, account/balance và settlement sẽ được tách thành feature sau.
