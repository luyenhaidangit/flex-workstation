# Tasks triển khai: Bảng điện thị trường demo

**Branch**: `000012-market-board`  
**Nguồn**: [spec.md](spec.md), [plan.md](plan.md)  
**Mục tiêu MVP**: Hiển thị bảng điện FXS và hỗ trợ hai tài khoản demo đặt/hủy lệnh qua giao diện công khai.

## Phase 1: Setup

**Mục đích**: Chuẩn bị cấu hình và cấu trúc feature Angular, không thay đổi Exchange API.

- [X] T001 [P] Thêm `exchangeApiBaseUrl`, `marketBoardPollingIntervalMs` và danh sách hai broker demo vào `flex-microfrontend/src/environments/environment.ts`.
- [X] T002 [P] Đồng bộ các key cấu hình `exchangeApiBaseUrl`, `marketBoardPollingIntervalMs` và broker demo cho production trong `flex-microfrontend/src/environments/environment.prod.ts`.
- [X] T003 Tạo khung feature module và thư mục `flex-microfrontend/src/app/exchange/` theo cấu trúc trong `plan.md`.

## Phase 2: Foundational

**Mục đích**: Hoàn tất nền tảng dùng chung trước khi triển khai từng user story.

- [X] T004 [P] Tạo typed model cho order book, trade tape, lệnh demo, broker demo và trạng thái bảng điện trong `flex-microfrontend/src/app/exchange/exchange.models.ts`.
- [X] T005 [P] Tạo Angular feature module `ExchangeModule` và khai báo component dự kiến trong `flex-microfrontend/src/app/exchange/exchange.module.ts`.
- [X] T006 Tạo service `ExchangeApiService` với base URL lấy từ environment, header `X-Correlation-Id` cho command và các kiểu response trong `flex-microfrontend/src/app/exchange/exchange-api.service.ts`.

**Checkpoint**: Cấu hình, model và service boundary sẵn sàng; không có migration hoặc thay đổi backend.

## Phase 3: User Story 1 — Quan sát bảng điện (Priority: P1) — MVP

**Goal**: Người xem nhận biết giá FXS, tối đa năm mức mua/bán, khối lượng chờ và trade tape; dữ liệu tự làm mới và tải lại trang đọc lại từ Exchange.

**Independent Test**:

1. Khởi động Exchange HTTP profile và Angular dev server, mở `/exchange` khi order book/trade tape trống.
2. Xác nhận giao diện hiển thị trạng thái trống; tạo dữ liệu FXS bằng API hiện có rồi chờ tối đa 3 giây.
3. Xác nhận giá gần nhất, tối đa năm mức bid/ask, tổng khối lượng chờ, trade tape và thời điểm cập nhật đúng thứ tự; refresh browser và xác nhận snapshot được đọc lại từ Exchange.

### Tests for User Story 1

- [X] T007 [P] [US1] Viết unit test cho mapping `GET /api/orderbook` và `GET /api/trades`, header correlation, giữ snapshot cũ khi refresh lỗi trong `flex-microfrontend/src/app/exchange/exchange-api.service.spec.ts`.
- [X] T008 [P] [US1] Viết component test cho render dữ liệu trống/có dữ liệu, giới hạn năm mức giá, thứ tự trade tape và trạng thái loading/error trong `flex-microfrontend/src/app/exchange/market-board.component.spec.ts`.
- [X] T009 [US1] Viết test polling lifecycle bảo đảm interval 2 giây, không tạo request chồng lấn và dừng khi component bị destroy trong `flex-microfrontend/src/app/exchange/market-board.component.spec.ts` (phụ thuộc T008).

### Implementation for User Story 1

- [X] T010 [US1] Triển khai các hàm query order book/trades, mapping dữ liệu và chuyển lỗi thành trạng thái UI trong `flex-microfrontend/src/app/exchange/exchange-api.service.ts` (phụ thuộc T004, T006, T007).
- [X] T011 [US1] Tạo routing lazy-loaded cho `/exchange` không gắn `AuthGuard` trong `flex-microfrontend/src/app/exchange/exchange-routing.module.ts` và tích hợp route trong `flex-microfrontend/src/app/app-routing.module.ts` (phụ thuộc T005).
- [X] T012 [US1] Tạo component điều phối snapshot, polling có lifecycle bounded, refresh sau command và giữ snapshot cuối khi query lỗi trong `flex-microfrontend/src/app/exchange/market-board.component.ts` (phụ thuộc T006, T009, T010).
- [X] T013 [US1] Dựng layout hiển thị mã FXS, giá gần nhất, năm mức bid/ask, khối lượng chờ, trade tape, thời điểm cập nhật và trạng thái empty/loading/error trong `flex-microfrontend/src/app/exchange/market-board.component.html` (phụ thuộc T012).
- [X] T014 [US1] Tạo style desktop dễ đọc, phân biệt bid/ask/trade và trạng thái lỗi mà không mở rộng phạm vi responsive trong `flex-microfrontend/src/app/exchange/market-board.component.scss` (phụ thuộc T013).

**Definition of Done**:

- Route `/exchange` truy cập được khi chưa đăng nhập và không đi qua `AuthGuard`.
- Bảng điện hiển thị đúng dữ liệu Exchange, không tự tính lại giá/khối lượng/trạng thái.
- Polling dừng khi rời trang, giữ snapshot cuối khi lỗi và refresh browser không tạo command mới.
- T007–T009 pass và Independent Test US1 hoàn tất.

**Checkpoint**: User Story 1 có thể demo độc lập trước khi thêm thao tác lệnh.

## Phase 4: User Story 2 — Đặt và hủy lệnh demo (Priority: P1)

**Goal**: Người dùng chọn một trong hai broker demo, đặt lệnh hợp lệ, nhận kết quả thật từ Exchange và hủy được lệnh còn chờ.

**Independent Test**:

1. Chọn từng broker trong allow-list, nhập buy/sell, giá và khối lượng hợp lệ; gửi lệnh và xác nhận chỉ có một command được tạo.
2. Kiểm tra thông báo accepted/rejected giữ đúng ý nghĩa lỗi nghiệp vụ từ Exchange.
3. Hủy một lệnh còn chờ đúng broker, xác nhận thành công hoặc lý do từ chối; đặt hai lệnh đối ứng và xác nhận bảng điện/trade tape cập nhật.

### Tests for User Story 2

- [X] T015 [P] [US2] Viết unit test cho request `POST /api/orders`, query `GET /api/orders/{orderId}` và `DELETE /api/orders/{orderId}`, broker allow-list, correlation header và mapping lỗi trong `flex-microfrontend/src/app/exchange/exchange-api.service.spec.ts`.
- [X] T016 [P] [US2] Viết component test cho validation broker/side/price/quantity, khóa submit khi đang xử lý, hiển thị accepted/rejected và không báo thành công giả khi cancel lỗi trong `flex-microfrontend/src/app/exchange/market-board.component.spec.ts`.

### Implementation for User Story 2

- [X] T017 [US2] Bổ sung typed command methods `placeOrder`, `getOrder` và `cancelOrder` theo contract trong `flex-microfrontend/src/app/exchange/exchange-api.service.ts` (phụ thuộc T006, T015).
- [X] T018 [US2] Bổ sung Reactive Form với allow-list broker từ environment, side, price, quantity và validation thông báo tại trường trong `flex-microfrontend/src/app/exchange/market-board.component.ts` (phụ thuộc T004, T016).
- [X] T019 [US2] Hiển thị form đặt lệnh, kết quả command, danh sách lệnh demo còn chờ và thao tác cancel trong `flex-microfrontend/src/app/exchange/market-board.component.html` (phụ thuộc T017, T018).
- [X] T020 [US2] Xử lý submit/cancel một lần, disable thao tác đang chờ, giữ nguyên lý do từ chối, giới hạn broker demo và gọi refresh snapshot sau kết quả trong `flex-microfrontend/src/app/exchange/market-board.component.ts` (phụ thuộc T012, T017, T018, T019).
- [X] T021 [US2] Bổ sung style cho form, kết quả accepted/rejected và lệnh đang chờ trong `flex-microfrontend/src/app/exchange/market-board.component.scss` (phụ thuộc T019).

**Definition of Done**:

- Chỉ hai broker cấu hình sẵn được gửi lên; không có token/secret trong UI hoặc lỗi hiển thị.
- Place/cancel chỉ coi là thành công khi Exchange xác nhận; thao tác lặp bị khóa trong thời gian request.
- Sau place/cancel hoặc matching, bảng điện được refresh và phản ánh order book/trade tape thật.
- T015–T016 pass và Independent Test US2 hoàn tất.

**Checkpoint**: MVP 3 hoàn chỉnh khi US1 và US2 đều pass độc lập.

## Final Phase: Polish & Cross-Cutting Concerns

- [X] T022 [P] Kiểm tra route `/exchange` công khai, broker allow-list và không render token/secret/header nội bộ trong `flex-microfrontend/src/app/exchange/market-board.component.spec.ts`.
- [ ] T023 [P] Bổ sung test regression cho Angular route, service và component bằng `flex-microfrontend/package.json` (`npm test -- --watch=false` và `npm run build`).
- [ ] T024 [P] Chạy kiểm tra regression Exchange không thay đổi contract bằng `flex-exchange-service/Flex.Exchange.slnx` (`dotnet build` và test hiện có).
- [X] T025 Cập nhật hướng dẫn chạy và smoke flow nếu có khác biệt so với [quickstart.md](quickstart.md), chỉ trong `specs/000012-market-board/quickstart.md`.
- [ ] T026 Chạy toàn bộ validation commands và ghi kết quả demo/rollback trong `specs/000012-market-board/quickstart.md`.

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 | T007–T014, T022–T026 |
| FR-001 | T004, T008, T012–T014 |
| FR-002 | T004, T007–T010, T013 |
| FR-003 | T007–T013 |
| AC-001 | T008, T013, Independent Test US1 |
| AC-002 | T007, T009, T010, T012, T013 |
| AC-003 | T011, T012, T026 |
| US-002 | T015–T021, T022–T026 |
| FR-004 | T004, T016, T018, T019 |
| FR-005 | T015, T016, T017, T020 |
| FR-006 | T012, T020 |
| FR-007 | T011, T018, T022 |
| BR-001 | T012, T013 |
| BR-002 / SEC-001 | T016, T018, T020, T022 |
| BR-003 | T007, T010, T012 |
| BR-004 / BR-005 | T015–T020 |
| SEC-002 | T015, T022 |
| NFR-001 | T015–T020, T026 |
| NFR-002 | T009, T012, T026 |
| NFR-003 | T011, T012, T026 |
| NFR-004 | T008, T013, T016, T021 |

## Dependencies & Execution Order

### Phase dependencies

1. Phase 1 (T001–T003) không phụ thuộc phase khác.
2. Phase 2 (T004–T006) phụ thuộc Phase 1 và chặn user stories.
3. US1 (T007–T014) bắt đầu sau Phase 2.
4. US2 (T015–T021) phụ thuộc T012 và service/model của Phase 2; có thể bắt đầu sau US1 hoàn tất để tránh conflict trên cùng component/service files.
5. Polish (T022–T026) phụ thuộc US1 và US2.

### Parallel opportunities

- T001 và T002 có thể chạy song song; T004 và T005 có thể chạy song song.
- T007–T009 có thể viết song song vì cùng là test preparation nhưng phải tích hợp trên cùng test files trước khi chạy.
- T015 và T016 có thể viết song song về mặt logic; merge cùng test files cần xử lý tuần tự.
- T022–T024 có thể chạy song song trên các file/project khác nhau.
- Không đánh dấu `[P]` cho các task cùng sửa một file production.

## Implementation Strategy

### MVP first

1. Hoàn tất T001–T006.
2. Hoàn tất T007–T014 và dừng để validate bảng điện US1 độc lập.
3. Hoàn tất T015–T021 để bổ sung đặt/hủy lệnh US2.
4. Chạy T022–T026 trước khi demo hoặc deploy frontend.

### Validation commands

- Frontend tests: `cd flex-microfrontend; npm test -- --watch=false`.
- Frontend build: `cd flex-microfrontend; npm run build`.
- Exchange regression: `cd flex-exchange-service; dotnet build; dotnet test`.
- Manual smoke: chạy profile HTTP Exchange trên `http://localhost:5266`, chạy Angular dev server và mở `/exchange` theo [quickstart.md](quickstart.md).

### Không áp dụng

- Không có database migration, seed, rollback schema hoặc backend endpoint implementation trong MVP này.
- Không thêm SignalR/WebSocket, JWT/Keycloak, portfolio hoặc thay đổi Swagger/OpenAPI vì contract Exchange không đổi.
