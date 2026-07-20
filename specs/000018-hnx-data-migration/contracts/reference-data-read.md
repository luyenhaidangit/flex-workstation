# HNX reference data read contract

## Phạm vi

Phase này giữ nguyên public FE/BE contracts. Contract này mô tả behavior nội bộ cần bảo đảm khi nguồn đọc chuyển từ legacy sang PostgreSQL.

## Existing public contract

- `GET /api/orderbook` và các exchange endpoints hiện có tiếp tục giữ route, status code và payload shape.
- FE `ExchangeApiService` không cần thay đổi để reference-data cutover.

## Internal port behavior

Application-owned port dự kiến cung cấp thao tác đọc danh sách/query instrument cần cho exchange use cases. Port không được expose Npgsql types hoặc database entities ra Application/Api.

## Dual-read rules

1. Đọc legacy và DB cho cùng một query/snapshot.
2. Canonicalize theo identity, symbol, market và status.
3. Nếu khớp: trả kết quả theo nguồn được chọn và ghi metric `hnx_reference_compare_match`.
4. Nếu lệch hoặc DB unavailable: giữ nguồn legacy nếu còn an toàn, ghi metric/log mismatch/failure và không cutover tự động.
5. Khi config ở `Database`, lỗi DB không được âm thầm quay về legacy nếu fallback đã bị tắt; trả lỗi theo error handling hiện có và phát cảnh báo.

## Compatibility

Không có breaking change public trong phase này. Contract test phải chứng minh payload FE hiện tại không đổi khi chạy ở `LegacyOnly`, `DualRead` và `Database`.
