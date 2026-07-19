# Data model: Ledger tiền và chứng khoán

## Nguyên tắc

- Mọi journal thuộc đúng một `TenantId` và có `SourceReference` ổn định.
- Journal chỉ append khi tổng debit bằng tổng credit theo cùng asset/currency.
- Entry không sửa/xóa; điều chỉnh tạo journal mới liên kết `ReversalOfJournalId`.
- Balance được project từ entries, không phải nguồn ghi mutable độc lập.

## Entities

### Journal

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `JournalId` | Định danh journal | Duy nhất trong runtime |
| `TenantId` | Tenant sở hữu | Bắt buộc, dùng cho scope |
| `SourceReference` | Lệnh/event/fee/seed nguồn | Bắt buộc, dùng idempotency |
| `EventType` | `Opening`, `Reserve`, `Fill`, `Fee`, `Cancel`, `Adjustment` | Bắt buộc |
| `OccurredAt` | Thời điểm nghiệp vụ | UTC |
| `CorrelationId` | Trace request | Có thể null với event nền |
| `ReversalOfJournalId` | Journal gốc nếu điều chỉnh | Chỉ có với Adjustment |
| `Entries` | Các dòng debit/credit | Ít nhất một debit và một credit |

### LedgerEntry

| Thuộc tính | Ý nghĩa | Ràng buộc |
|---|---|---|
| `EntryId` | Định danh dòng | Duy nhất trong journal |
| `JournalId` | Journal chứa dòng | Bắt buộc |
| `TenantId` | Tenant của dòng | Phải trùng journal |
| `AccountId` | Tài khoản tài sản | Bắt buộc |
| `AssetType` | `Cash` hoặc `Security` | Bắt buộc |
| `AssetCode` | Currency hoặc symbol | Bắt buộc |
| `Bucket` | `Available`, `Reserved`, `Receivable`, `Payable` | Bắt buộc |
| `Debit` / `Credit` | Giá trị dòng | Không âm; không đồng thời khác 0 |
| `Description` | Diễn giải nghiệp vụ | Không chứa secret |

### LedgerAccountBalance

| Thuộc tính | Ý nghĩa |
|---|---|
| `TenantId`, `AccountId`, `AssetType`, `AssetCode` | Khóa balance |
| `Available`, `Reserved`, `Receivable`, `Payable` | Tổng theo bucket |
| `AsOfJournalSequence` | Mốc journal đã project |

### SourceTransaction

Nguồn nghiệp vụ được biểu diễn qua `SourceReference` và `EventType`, không tạo aggregate riêng trong MVP. Các nguồn gồm opening seed, broker order reserve, `TradeExecuted`, fee và cancel.

## Transition rules

| Nguồn | Quy tắc | Bucket sau transition |
|---|---|---|
| Opening cash/security | Tài khoản demo đối ứng opening equity | `Available` |
| Buy reserve | Giảm cash available, tăng cash reserved | `Reserved` |
| Sell reserve | Giảm security available, tăng security reserved | `Reserved` |
| Buy fill | Consume cash reserved; purchase value thành phải thu theo rule MVP | `Receivable` |
| Sell fill | Consume security reserved; proceeds thành phải thu/phải trả theo bên | `Receivable`/`Payable` |
| Fee | Debit tài khoản bên phát sinh; credit fee income đối ứng | Theo asset/currency fee |
| Cancel/release | Chuyển phần reserved còn lại về available | `Available` |

Chi tiết account mapping phải được giữ trong contract và task; không dùng settlement T+ trong phase này.

## Invariants

1. Tổng debit = tổng credit theo `TenantId + AssetType + AssetCode` trong mỗi journal.
2. Không bucket nào âm sau projection.
3. Duplicate `(TenantId, SourceReference, EventType)` không tạo journal mới.
4. Entry/journal đã append không bị mutation.
5. Query phải lọc tenant trước khi trả balance/trace.
