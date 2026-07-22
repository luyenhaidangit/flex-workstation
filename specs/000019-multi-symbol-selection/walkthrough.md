# Walkthrough: Tùy chọn mã chứng khoán và lưu trạng thái hiển thị trên Market Board

Tài liệu này tổng kết các thay đổi kỹ thuật, kết quả kiểm thử và hướng dẫn xác minh tính năng chọn nhiều mã chứng khoán & tự động ghi nhớ trạng thái trên bảng điện Market Board.

## Summary of Changes

### 1. Database Seed Data (`flex-database`)
- **Tập tin**: [003-seed-multi-symbols.sql](file:///c:/Workspace/Project/flex-workstation/flex-database/hnx/changelog/releases/1.0.0.0/003-seed-multi-symbols.sql), [changelog.xml](file:///c:/Workspace/Project/flex-workstation/flex-database/hnx/changelog/releases/1.0.0.0/changelog.xml)
- **Thay đổi**: Thêm Liquibase changeset bổ sung các mã chứng khoán `FXS`, `HNX`, `VND` vào bảng `exchange_instruments` với trạng thái `active`.

### 2. Backend API (`flex-exchange-service`)
- **Tập tin**:
  - [InstrumentsController.cs](file:///c:/Workspace/Project/flex-workstation/flex-exchange-service/src/Flex.Exchange.Api/Controllers/InstrumentsController.cs)
  - [ExchangeService.cs](file:///c:/Workspace/Project/flex-workstation/flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs)
  - [IExchangeService.cs](file:///c:/Workspace/Project/flex-workstation/flex-exchange-service/src/Flex.Exchange.Application/Services/IExchangeService.cs)
  - [OrderBookController.cs](file:///c:/Workspace/Project/flex-workstation/flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrderBookController.cs)
  - [TradesController.cs](file:///c:/Workspace/Project/flex-workstation/flex-exchange-service/src/Flex.Exchange.Api/Controllers/TradesController.cs)
- **Thay đổi**:
  - Cung cấp REST API `GET /api/instruments` lấy danh sách mã chứng khoán đang hoạt động.
  - Quản lý đa Sổ lệnh độc lập cho từng mã `symbol` thông qua `ConcurrentDictionary<string, MatchingEngine>`.
  - Cập nhật `GET /api/orderbook` và `GET /api/trades` nhận query parameter `?symbol=XYZ` (mặc định fallback về `FXS`).

### 3. Frontend Microfrontend (`flex-microfrontend`)
- **Tập tin**:
  - [exchange.models.ts](file:///c:/Workspace/Project/flex-workstation/flex-microfrontend/src/app/exchange/exchange.models.ts)
  - [exchange-api.service.ts](file:///c:/Workspace/Project/flex-workstation/flex-microfrontend/src/app/exchange/exchange-api.service.ts)
  - [market-board.component.html](file:///c:/Workspace/Project/flex-workstation/flex-microfrontend/src/app/exchange/market-board.component.html)
  - [market-board.component.ts](file:///c:/Workspace/Project/flex-workstation/flex-microfrontend/src/app/exchange/market-board.component.ts)
- **Thay đổi**:
  - Thêm ô chọn Dropdown chọn mã chứng khoán (`FXS`, `HNX`, `VND`) ở phần header Market Board.
  - Tự động lưu vết và đọc mã theo thứ tự ưu tiên 3 cấp: URL Query Param (`?symbol=XYZ`) ➔ `localStorage` (`flex_selected_symbol`) ➔ Default symbol.
  - Khi thay đổi mã trên Dropdown, UI tự động gọi API nạp lại Sổ lệnh/Giao dịch khớp mới và cập nhật cả URL địa chỉ lẫn `localStorage`.

---

## Verification & Test Results

### 1. Backend Automated Test Suite
- **Lệnh chạy**: `dotnet test flex-exchange-service/Flex.Exchange.sln`
- **Kết quả**: **51 / 51 tests passed** (25 Domain tests + 26 API integration tests).

```text
Passed!  - Failed: 0, Passed: 25, Skipped: 0, Total: 25 - Flex.Exchange.Domain.Tests.dll
Passed!  - Failed: 0, Passed: 26, Skipped: 0, Total: 26 - Flex.Exchange.Api.Tests.dll
```

### 2. End-to-End Verification Scenarios

| Kịch bản | Thao tác | Kết quả mong đợi | Trạng thái |
| :--- | :--- | :--- | :--- |
| **Kịch bản 1: Chọn mã chứng khoán** | Chọn `HNX` từ Dropdown mã chứng khoán trên UI | Sổ lệnh & Băng khớp lệnh xóa dữ liệu cũ, tải dữ liệu mã `HNX`. URL cập nhật thành `?symbol=HNX`. | ✅ Pass |
| **Kịch bản 2: Ghi nhớ khi F5 Reload** | Nhấn F5 khi đang ở `?symbol=HNX` | Dropdown vẫn giữ `HNX`, URL giữ `?symbol=HNX` và dữ liệu nạp đúng mã `HNX`. | ✅ Pass |
| **Kịch bản 3: Khôi phục từ localStorage** | Mở tab mới truy cập `/exchange` không có query param | Tự động khôi phục mã `HNX` đã chọn trước đó từ `localStorage`. | ✅ Pass |
| **Kịch bản 4: Đặt lệnh theo mã chọn** | Đặt lệnh MUA 100 cổ phiếu `HNX` | Lệnh gửi đi thành công với `symbol: "HNX"`, Sổ lệnh `HNX` ghi nhận lượng mua chờ. | ✅ Pass |
