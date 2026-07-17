# Quickstart: Xác minh lõi khớp lệnh (FlexSim MVP 01)

**Ngày**: 2026-07-14
**Repo đích**: `flex-exchange-service` (clone tại `C:\Workspace\Project\flex-workstation\flex-exchange-service`)

Hướng dẫn này xác minh feature chạy đúng end-to-end sau khi implement. Chi tiết schema xem [data-model.md](data-model.md) và [contracts/exchange-core.md](contracts/exchange-core.md).

## Điều kiện tiên quyết

- .NET 9 SDK (`dotnet --version` ≥ 9.0).
- Không cần database, message broker hay biến môi trường nào (FR-010).

## Build và chạy service

Chạy từ root repo `flex-exchange-service`:

```powershell
dotnet restore Flex.Exchange.sln
dotnet build Flex.Exchange.sln --configuration Release
dotnet test Flex.Exchange.sln --configuration Release --no-build
dotnet run --project src/Flex.Exchange.Api/Flex.Exchange.Api.csproj --launch-profile http
```

**Kỳ vọng**: Service chạy Kestrel cục bộ; mở Swagger UI tại URL được in trong console. Domain/API tests xác minh các rule và contract trọng yếu; dùng `Flex.Exchange.http` để kiểm chứng thủ công các kịch bản sau.

| Nhóm kịch bản `.http` | Xác minh |
|-----------|----------|
| Không khớp | Lệnh vào sổ nằm chờ, không sinh trade |
| Khớp toàn phần | AC-001, AC-002 |
| Khớp một phần | AC-003, AC-004 |
| Ưu tiên giá | AC-005 (kèm khớp xuyên nhiều mức giá) |
| Ưu tiên thời gian | AC-006 |
| Hủy lệnh | AC-007, AC-008 (kèm hủy lặp lại) |
| Validate lệnh | AC-009 — từng ràng buộc tick/biên độ/lô/khối lượng |
| Determinism | Cùng kịch bản chạy 10 lần → kết quả giống hệt (SC-002) |

## Chạy kịch bản API

Mở `src/Flex.Exchange.Api/Flex.Exchange.http` trong IDE, đặt biến `@baseUrl` theo URL Kestrel rồi gửi request theo thứ tự từng kịch bản. Restart service trước mỗi nhóm để đưa order book về trạng thái trống. Có thể thực hiện cùng request trên Swagger UI.

**Kỳ vọng response theo kịch bản** (SC-001):

1. **Khớp toàn phần**: bán 100 FXS @20.000 rồi mua 100 FXS @20.000 → in `OrderAccepted` ×2, đúng **một** `TradeExecuted` (100 @20.000); snapshot rỗng hai bên.
2. **Khớp một phần**: bán 100 @20.000 rồi mua 200 @20.000 → một `TradeExecuted` (100 @20.000); snapshot: bên mua còn một mức 20.000 khối lượng 100, bên bán rỗng.
3. **Hủy lệnh**: đặt lệnh chờ, gọi `DELETE /api/orders/{orderId}?brokerId=DemoBroker`, nhận `OrderCancelled`; lệnh đối ứng vào sau không khớp — snapshot xác nhận.

## Kiểm tra tính xác định thủ công (tùy chọn)

Khởi động lại service, chạy cùng chuỗi request hai lần và so sánh JSON từ `GET /api/events` cùng `GET /api/orderbook`:

```powershell
Invoke-RestMethod "$baseUrl/api/events" | ConvertTo-Json -Depth 10 > run1-events.json
Invoke-RestMethod "$baseUrl/api/orderbook" | ConvertTo-Json -Depth 10 > run1-book.json
# restart service, chạy lại đúng request, rồi lưu run2-events.json và run2-book.json
git diff --no-index run1-events.json run2-events.json
git diff --no-index run1-book.json run2-book.json
```

(Các payload dùng để so sánh không được chứa timestamp sinh từ đồng hồ máy.)

## Tiêu chí hoàn tất xác minh

- [X] `dotnet build` thành công; Swagger Development tại `http://localhost:5266/swagger/index.html` trả HTTP 200.
- [X] Tám nhóm kịch bản trong `Flex.Exchange.http` được bao phủ bởi `MvpAcceptanceTests`: không khớp, khớp toàn phần/một phần, ưu tiên giá/FIFO, hủy, validation, snapshot/event log và determinism.
- [X] `MvpAcceptanceTests.SameApiCommandSequenceAfterRestartProducesIdenticalResponsesWithinFiveSeconds` đo xử lý API sau khi host đã tạo và hoàn tất dưới 5 giây.
- [X] `MvpAcceptanceTests.SameApiCommandSequenceAfterRestartProducesIdenticalResponsesWithinFiveSeconds` xác minh hai host mới, cùng chuỗi request, cho event log và snapshot giống hệt.
- [X] `src/Flex.Exchange.Domain/Flex.Exchange.Domain.csproj` không tham chiếu package runtime nào (FR-010).
