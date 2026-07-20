# Data model: HNX reference data migration

## Phạm vi model

Phase đầu chỉ chuyển HNX reference data; các bảng order, order history, trade và outbox đã tồn tại trong database nhưng chưa được cutover trong phase này.

## Entities

### HNX Instrument

Nguồn nghiệp vụ mô tả một mã công cụ giao dịch trên HNX.

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `instrument_id` | Identity ổn định của instrument | Không đổi trong vòng đời instrument |
| `symbol` | Mã giao dịch | Duy nhất trong HNX, không rỗng |
| `market` | Thị trường sở hữu dữ liệu | Phải là HNX trong phase này |
| `status` | Trạng thái sử dụng | Giá trị phải thuộc tập trạng thái được BE hỗ trợ |
| `created_at` | Thời điểm tạo | UTC/offset-aware |

Database mapping hiện có: `exchange_instruments` trong `flex-database/hnx/changelog/releases/1.0.0.0/001-create-reference-tables.sql`.

### Reference data source state

Trạng thái vận hành của nguồn đọc reference data, không phải business entity:

- `LegacyOnly`: chỉ nguồn cũ.
- `DualRead`: đọc và đối chiếu nguồn cũ với DB.
- `Database`: DB là nguồn phục vụ chính.

State này phải được cấu hình có kiểm soát, ghi audit/telemetry khi thay đổi và không làm thay đổi dữ liệu nghiệp vụ.

### Migration comparison

Kết quả đối chiếu cho một lần kiểm tra:

- batch/check identifier;
- số lượng bản ghi mỗi nguồn;
- số bản ghi khớp, thiếu, khác thuộc tính;
- trạng thái `Matched`, `Mismatch`, `Failed`;
- correlation/time/actor nếu thao tác được vận hành thủ công.

Đây là dữ liệu vận hành/audit; cách lưu bền vững hay chỉ lưu log sẽ được quyết định trong implementation theo yêu cầu observability, nhưng kết quả phải truy nguyên được.

## Relationships

- Một HNX Instrument có thể được tham chiếu bởi nhiều order/trade ở phase sau qua `instrument_id`.
- Reference data không chứa trực tiếp order, trade hoặc tenant-owned account data.

## Invariants

- Không có hai instrument cùng `symbol` trong HNX.
- Không coi dual-read là khớp nếu identity hoặc bất kỳ thuộc tính nghiệp vụ được kiểm tra khác nhau.
- Không cutover khi có mismatch chưa được xử lý.
- Retry seed/backfill không tạo bản ghi trùng.
