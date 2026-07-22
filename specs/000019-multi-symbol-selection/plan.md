# Kế hoạch triển khai: Tùy chọn Mã chứng khoán & Lưu trạng thái Market Board

**Branch**: `000019-multi-symbol-selection` | **Ngày**: 2026-07-21 | **Đặc tả**: [spec.md](file:///c:/Workspace/Project/flex-workstation/specs/000019-multi-symbol-selection/spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000019-multi-symbol-selection/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
1. Cho phép người dùng chuyển đổi xem Sổ lệnh (Order Book), Băng khớp lệnh (Trade Tape) và đặt lệnh cho nhiều mã chứng khoán (`FXS`, `HNX`, `VND`...).
2. Tự động lưu trữ và khôi phục mã chứng khoán đã chọn khi làm mới (reload) trang theo thứ tự ưu tiên: URL Query Parameter ➔ `localStorage` ➔ Default Symbol.

**Hướng tiếp cận kỹ thuật dự kiến**:
- **Backend (`flex-exchange-service`)**: Thêm API `GET /api/instruments`, cập nhật `GET /api/orderbook` và `GET /api/trades` nhận query `symbol`, hỗ trợ multi-matching-engine trong `ExchangeService`.
- **Frontend (`flex-microfrontend`)**: Bỏ hardcode `symbol = 'FXS'`, thêm Dropdown chọn mã, kết nối Angular Router `QueryParams` và `localStorage` service.
- **Database (`flex-database`)**: Seed các mã chứng khoán mẫu mới (`HNX`, `VND`) qua Liquibase.

**Kết quả sau research**: Đã hoàn tất các quyết định kỹ thuật trong `research.md`.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-database`: Changeset seed mã chứng khoán mới (`HNX`, `VND`).
- `flex-exchange-service`: API `GET /api/instruments`, cập nhật `OrderBookController`, `TradesController`, `OrdersController` và `ExchangeService`.
- `flex-microfrontend`: Angular `ExchangeApiService`, `MarketBoardComponent`, `market-board.component.html`, đồng bộ `queryParams` và `localStorage`.

**Ngoài phạm vi kỹ thuật**:
- Quản lý danh mục yêu thích (Watchlist) hoặc đa màn hình Dashboard.
- Đồng bộ lựa chọn mã lên Server Database theo User Account (ở v1).

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET 8 / C# 12 (Backend), Angular 16 / TypeScript (Frontend).

**Service/App liên quan**: `flex-exchange-service`, `flex-microfrontend`, `flex-database`.

**Phụ thuộc chính**: ASP.NET Core Web API, Angular Router, RxJS, Liquibase.

**Lưu trữ**: PostgreSQL (`exchange_instruments`), Browser `localStorage`.

**Kiểm thử**: xUnit (Backend), Karma/Jasmine (Frontend), Quickstart E2E Manual.

**Nền tảng chạy**: Cross-platform (.NET Core & Node.js/Angular).

---

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Spec trước code | Pass | Pass | Đã hoàn tất spec.md & requirements.md |
| Thay đổi phẫu thuật và đơn giản | Pass | Pass | Chỉ thêm API/Component cần thiết, giữ tương thích ngược |
| Điều phối workspace, không trộn sub-repo | Pass | Pass | Code thuộc sub-repo tương ứng |

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Ưu tiên URL Query Param ➔ `localStorage` ➔ Default Symbol | Linh hoạt cho cả chia sẻ link và cá nhân hóa reload | Chỉ dùng `localStorage` | Không chia sẻ được link cụ thể |
| DEC-002 | `ConcurrentDictionary<string, MatchingEngine>` trong Backend | Độc lập sổ lệnh giữa các mã, thread-safe | 1 MatchingEngine duy nhất | Không hỗ trợ nhiều mã chứng khoán |

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Thêm API lấy danh sách mã & Dropdown trên FE | `flex-exchange-service/src/Flex.Exchange.Api/Controllers/InstrumentsController.cs`, `flex-microfrontend/src/app/exchange/market-board.component.html` | `GET /api/instruments` | `exchange_instruments` | Unit / Manual |
| US-001 / FR-002 | P1 | Đủ rõ | Cập nhật API OrderBook & Trades nhận parameter `symbol` | `flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrderBookController.cs`, `flex-microfrontend/src/app/exchange/exchange-api.service.ts` | `GET /api/orderbook?symbol={symbol}`, `GET /api/trades?symbol={symbol}` | `exchange_orders`, `exchange_trades` | Integration / Unit |
| US-002 / FR-004, FR-005 | P1 | Đủ rõ | Đồng bộ mã chứng khoán với URL `queryParams` & `localStorage` | `flex-microfrontend/src/app/exchange/market-board.component.ts` | Không áp dụng | Client State | Unit test FE / Manual |

---

## API/Contract Detail

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `GET /api/instruments` | API | Mới: Lấy danh sách mã `ACTIVE` | Có | `flex-microfrontend` |
| `GET /api/orderbook` | API | Cập nhật: Nhận `[FromQuery] string? symbol` | Có (Mặc định `FXS`) | `flex-microfrontend` |
| `GET /api/trades` | API | Cập nhật: Nhận `[FromQuery] string? symbol` | Có (Mặc định `FXS`) | `flex-microfrontend` |

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không đổi schema, chỉ seed thêm bản ghi vào `exchange_instruments`.

**Migration**: ChangeSet Liquibase thêm các mã chứng khoán mẫu `HNX`, `VND` vào `exchange_instruments`.

---

## Chiến lược kiểm thử

- **Unit test Backend**: Kiểm tra `InstrumentsController` và `ExchangeService` với nhiều mã `symbol`.
- **Unit test Frontend**: Kiểm tra `MarketBoardComponent` xử lý khôi phục mã từ `queryParams` và `localStorage`.
- **Manual Verification**: Thực hiện theo [quickstart.md](file:///c:/Workspace/Project/flex-workstation/specs/000019-multi-symbol-selection/quickstart.md).

---

## Cấu trúc project

### Tài liệu cho feature này
```text
specs/000019-multi-symbol-selection/
├── plan.md              # File này
├── research.md          # Kết quả nghiên cứu kỹ thuật
├── data-model.md        # Mô hình dữ liệu & Client state
├── quickstart.md        # Hướng dẫn kiểm thử nhanh
└── contracts/
    └── exchange-api-contracts.md # Định nghĩa API contracts
```

### Source code tham gia
```text
flex-database/
└── changelog/          # Liquibase seed changeset mới

flex-exchange-service/
└── src/
    ├── Flex.Exchange.Api/Controllers/
    │   ├── InstrumentsController.cs  # Controller mới
    │   ├── OrderBookController.cs    # Cập nhật [FromQuery] symbol
    │   └── TradesController.cs       # Cập nhật [FromQuery] symbol
    └── Flex.Exchange.Application/Services/
        └── ExchangeService.cs        # Quản lý Multi MatchingEngine

flex-microfrontend/
└── src/app/exchange/
    ├── exchange-api.service.ts       # Cập nhật gọi API theo symbol
    ├── market-board.component.ts     # Đồng bộ queryParams & localStorage
    └── market-board.component.html   # Dropdown chọn mã chứng khoán
```

---

## Observability & Debug

- **Log field**: Log thông tin `symbol` trong tất cả log đặt lệnh, hủy lệnh, lấy sổ lệnh.
- **Trace**: Giữ nguyên `X-Correlation-Id` UUID trên mọi request.

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.
- [x] Thiết kế tổng quan đã mô tả luồng chính và component tham gia.
- [x] Mỗi `US`/`FR` P1/P2 có mapping sang module/path, API/contract và kiểm thử.
- [x] Tác động tới DB, API contract và UI đã được đánh giá.
- [x] Cấu trúc project chỉ chứa path thật trong repository.
- [x] Constitution gate pass.
