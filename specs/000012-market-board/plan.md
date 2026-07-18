# Kế hoạch triển khai: Bảng điện thị trường demo

**Branch**: `000012-market-board` | **Ngày**: 2026-07-18 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả nghiệp vụ từ `specs/000012-market-board/spec.md`.

## Tóm tắt

**Yêu cầu chính từ spec**: Tạo một bảng điện công khai cho mã FXS, hiển thị order book/trade tape và cho phép hai tài khoản demo đặt/hủy lệnh mà không cần đọc log hoặc đăng nhập.

**Hướng tiếp cận kỹ thuật dự kiến**: Thêm một Angular feature module lazy-loaded tại `/exchange` trong `flex-microfrontend`. Feature dùng typed models, một API service gọi trực tiếp các endpoint MVP 02 của `flex-exchange-service`, polling mặc định 2 giây và giữ snapshot cuối khi refresh lỗi. Không thay đổi matching engine, database hoặc public API của Exchange.

**Kết quả sau research**: Các quyết định về route công khai, URL Exchange riêng, polling, typed contract, broker demo và không migration đã được ghi trong [research.md](research.md).

## Phạm vi kỹ thuật

**Trong phạm vi**:

- `flex-microfrontend/src/app/exchange/`: feature module, routing, page component, API service, typed models, form validation và SCSS.
- `flex-microfrontend/src/app/app-routing.module.ts`: route lazy-loaded `/exchange` ngoài `AuthGuard`.
- `flex-microfrontend/src/environments/environment.ts` và `environment.prod.ts`: cấu hình `exchangeApiBaseUrl`, polling interval và hai broker demo.
- Unit/component tests cho mapping, polling lifecycle, validation, success/rejection/error state và không submit lặp.
- Contract smoke/integration test consumer với Exchange API hiện có nếu harness frontend hỗ trợ.

**Ngoài phạm vi kỹ thuật**:

- Không sửa `flex-exchange-service` domain/matching/application contract trong MVP này.
- Không thêm database, migration, cache nghiệp vụ, SignalR/WebSocket, JWT/Keycloak hoặc portfolio.
- Không cập nhật Swagger/OpenAPI vì không thay đổi API contract; contract consumer được ghi tại [contracts/market-board-ui.md](contracts/market-board-ui.md).

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**:
- Frontend: Angular 16.1, TypeScript 5.1, RxJS 7.8, SCSS.
- Exchange: .NET 9 / ASP.NET Core controller API; MVP 02 đã hoàn tất các endpoint cần dùng.

**Service/App liên quan**:
- `flex-microfrontend` là ứng dụng browser cần triển khai feature.
- `flex-exchange-service` là nguồn sự thật cho order book, trades và order commands.

**Phụ thuộc chính**:
- Angular `HttpClient`, Reactive Forms, Router, RxJS.
- `flex-exchange-service` routes `/api/orderbook`, `/api/trades`, `/api/orders`.
- `AppHttpInterceptor` hiện có để loading/error; feature phải tránh phụ thuộc vào auth guard.

**Lưu trữ**: Không áp dụng; state nghiệp vụ nằm trong Exchange process hiện có.

**Kiểm thử**: Jasmine/Karma component tests; .NET API contract tests hiện có; manual browser smoke theo [quickstart.md](quickstart.md).

**Nền tảng chạy**: Browser desktop hiện đại, Angular dev server hoặc static build; Exchange chạy local/demo.

**Đơn vị deploy**: Frontend build của `flex-microfrontend`; Exchange deploy độc lập không đổi.

**Loại project**: `web-frontend` tích hợp `web-service` hiện có.

**Mục tiêu hiệu năng**:
- Polling mặc định 2 giây, cập nhật dữ liệu trong tối đa 3 giây khi Exchange khỏe.
- Phản hồi thao tác đặt/hủy được hiển thị trong tối đa 5 giây theo NFR-001.

**Ràng buộc**:
- Không hard-code base URL trong component.
- Không gửi broker ngoài allow-list frontend; backend vẫn xác nhận nghiệp vụ.
- Không để lỗi/refresh làm mất snapshot cuối hoặc tạo command lặp.

**Quy mô/Phạm vi**: Một mã FXS, một màn hình, hai broker demo, dữ liệu bounded bởi năm mức giá và trade tape Exchange hiện có.

## Kiểm tra constitution

*GATE: Đã kiểm tra trước Phase 0 và sẽ kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|---|---|---|---|
| Scope Gate | Pass | Pass | Chỉ thêm bảng điện demo, đúng ngoài phạm vi auth/portfolio/multi-symbol. |
| Traceability Gate | Pass | Pass | US/FR P1 có mapping tới feature path, contract, model và test. |
| Test Gate | Pass | Pass | Có unit/component, contract và manual smoke cho luồng chính/lỗi. |
| Security Gate | Pass | Pass | Route demo công khai có allow-list broker; không lưu token/secret; Exchange là authority. |
| Compatibility Gate | Pass | Pass | Không đổi endpoint/payload backend; chỉ thêm consumer. |
| Observability Gate | Pass | Pass | UI có correlation cho command, trạng thái stale và logging an toàn qua backend. |
| Complexity Gate | Pass | Pass | Polling đơn giản thay cho realtime transport; không thêm abstraction ngoài feature boundary. |
| Release Gate | Pass | Pass | Có quickstart, rollback frontend và không có migration. |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Có cần migration/backfill không? **Đã resolve**: Không; UI đọc state từ Exchange.
- **TQ-002**: Dùng flow/module hiện có hay extension point mới? **Đã resolve**: Feature module riêng lazy-loaded, tái sử dụng `HttpClient`, interceptor và style hiện có.
- **TQ-003**: Contract hiện tại có cần giữ backward compatibility không? **Đã resolve**: Có; consumer dùng additive contract, không sửa API MVP 02.

## Thiết kế tổng quan

**Luồng chính**:

1. Router tải `ExchangeModule` khi người dùng mở `/exchange`, không yêu cầu `AuthGuard`.
2. `MarketBoardComponent` khởi tạo form và gọi `ExchangeApiService` lấy order book/trades; một RxJS timer refresh bounded theo lifecycle.
3. Service map JSON sang `MarketBoardViewModel`, giới hạn hiển thị năm mức và giữ snapshot cuối khi một query lỗi.
4. Người dùng submit place/cancel; component khóa thao tác, service thêm `X-Correlation-Id`, map response accepted/rejected/cancelled và refresh lại board.
5. UI hiển thị trạng thái loading/stale/error/success và không log token, secret hoặc raw sensitive response.

**Component/module tham gia**:

- `ExchangeModule`: khai báo feature component, routing và Reactive Forms.
- `MarketBoardComponent`: orchestration UI, form state, refresh lifecycle và render board/order/trade sections.
- `ExchangeApiService`: typed HTTP calls, URL config, correlation id và mapping lỗi transport.
- `exchange.models.ts`: DTO và view model public của feature.
- `environment*.ts`: Exchange URL, polling interval, symbol và broker allow-list.
- `flex-exchange-service` controllers/contracts hiện có: authoritative source, không sửa trong MVP.

**Điểm mở rộng/thay đổi chính**:

- Feature path mới `src/app/exchange/` thay vì đặt logic vào `pages` hoặc `AppComponent`.
- Adapter riêng cho Exchange API để sau này đổi gateway/auth không lan vào component.
- Cấu hình URL riêng cho môi trường để không phụ thuộc `apiBaseUrl` của auth/gateway.

**Luồng thay thế/lỗi chính**:

- Query thất bại: giữ `lastSuccessfulBoard`, đặt `stale=true`, hiển thị retry/thông báo an toàn.
- Place/cancel bị từ chối: hiển thị reason nghiệp vụ, mở lại form, không refresh thành công giả.
- HTTP 429: không retry tự động command; giữ dữ liệu hiện tại.
- Request bị hủy khi rời route: unsubscribe qua `takeUntil`/lifecycle, không cập nhật component đã destroy.

**Thay đổi boundary giữa service/module**:

- Không thay đổi boundary API Exchange; frontend chỉ tiêu thụ contract đã có.
- `exchangeApiBaseUrl` là boundary cấu hình giữa browser và Exchange.

**Idempotency/Concurrency**:

- Chỉ một place/cancel đang pending trên form; disable nút trong request.
- Polling không chạy chồng; mỗi tick dùng request hiện tại và hủy subscription khi component destroy.
- Command retry thủ công chỉ thực hiện sau khi người dùng thấy kết quả; không tự retry POST/DELETE.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---|---|---|---|---|---|---|---|
| US-001 / FR-001 | P1 | Đủ rõ | Route công khai và page board cố định `FXS` | `flex-microfrontend/src/app/app-routing.module.ts`, `src/app/exchange/` | UI route `/exchange` | `MarketBoardViewModel` | Component/E2E |
| US-001 / FR-002 | P1 | Đủ rõ | Map snapshot, sắp xếp/giới hạn 5 bids/asks, tính latest price từ trade tape | `exchange-api.service.ts`, `market-board.component.ts` | `GET /api/orderbook`, `GET /api/trades` | `OrderBookSnapshot`, `PriceLevel`, `TradeTapeEntry` | Service/component/contract |
| US-001 / FR-003 | P1 | Đủ rõ | Timer polling 2 giây, teardown và stale state | `market-board.component.ts` | `GET /api/orderbook`, `GET /api/trades` | `MarketBoardViewModel` | RxJS/component/manual |
| US-001 / FR-007 | P1 | Đủ rõ | UI không yêu cầu log/technical id; label và state rõ ràng | `exchange.component.html`, `exchange.component.scss` | Không đổi | Không áp dụng | Component/manual |
| US-002 / FR-004 | P1 | Đủ rõ | Reactive form với broker allow-list, side/price/quantity validation | `market-board.component.ts/html` | `POST /api/orders` | `PlaceOrderFormModel`, `DemoBrokerOption` | Component |
| US-002 / FR-005 | P1 | Đủ rõ | Map accepted/reason và cancel result; không coi HTTP 200 là success tuyệt đối | `exchange-api.service.ts`, component | `POST /api/orders`, `DELETE /api/orders/{id}` | `DemoOrderViewModel` | Contract/component |
| US-002 / FR-006 | P1 | Đủ rõ | Refresh sau command thành công và sau polling | `market-board.component.ts` | `GET /api/orderbook`, `GET /api/trades`, `GET /api/orders/{id}` | `MarketBoardViewModel` | Integration/manual |
| BR-001–BR-005 / SEC-001–SEC-002 | P1 | Đủ rõ | Cố định symbol, allow-list broker, không lưu credential, backend là authority | `environment*.ts`, service, component | Existing Exchange contracts | `DemoBrokerOption`, order response | Negative/security/component |
| NFR-001–NFR-004 | P1 | Đủ rõ | Timeout/error state, bounded polling, desktop layout và refresh-safe behavior | `exchange-api.service.ts`, component, SCSS | Existing endpoints | Client state | Component/manual/performance smoke |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---|---|---|---|
| Database/Migration | Không có | Không áp dụng | Xác nhận không có file migration/schema mới |
| API/Contract | Không đổi endpoint/payload; thêm consumer | Sai mapping enum/nullable có thể làm UI lỗi | Contract assertions và smoke API |
| Permission/Security | Route demo không qua auth; allow-list hai broker | Có thể bị dùng ngoài demo nếu deploy nhầm public | Review route, config và negative tests |
| Logging/Audit | Không tạo audit mới; correlation command đi qua API | Không được log token/raw response | Kiểm tra browser/backend log |
| UI/UX | Thêm route và màn hình bảng điện | Có thể xung đột style/layout hiện có | Component test và manual desktop smoke |
| Job/Worker/Integration | Không có worker; polling gọi HTTP bounded | API unavailable/rate limit | Timeout/error test và rate-limit smoke |

## API/Contract Detail

**Có thay đổi contract không**: Không. Frontend consumer contract được mô tả tại [contracts/market-board-ui.md](contracts/market-board-ui.md).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|---|---|---|---|---|
| `/api/orderbook`, `/api/trades`, `/api/orders` | API | Không đổi; chỉ thêm consumer Angular | Có | `flex-microfrontend` mới |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---|---|---|---|---|---|---|
| Người truy cập demo | Có | Có | Không áp dụng | Có (hủy order của broker đã chọn) | Không áp dụng | Chỉ hai broker demo; backend vẫn kiểm tra ownership |
| Người dùng có auth thật | Không áp dụng trong MVP | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Sẽ thiết kế ở feature auth riêng |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Migration**: Không áp dụng; Exchange state hiện có được dùng trực tiếp.

**Backfill/Cleanup**: Không áp dụng.

**Tương thích dữ liệu cũ**: UI tolerant với danh sách rỗng và field nullable từ API MVP 02.

**Rủi ro dữ liệu**: Browser không lưu nghiệp vụ; rủi ro chính là stale view, xử lý bằng cờ `stale` và refresh.

**Cách xác minh**: Tải lại trang sau place/cancel/trade và đối chiếu với API orderbook/trades.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|---|---|---|---|---|
| DEC-001 | Angular lazy feature module `/exchange` | Phù hợp cấu trúc NgModule hiện tại và route công khai | Component trong `AppComponent` | Làm phình composition root, khó test/lazy-load |
| DEC-002 | Polling 2 giây, không SignalR | Đủ NFR-002, ít thay đổi backend và dễ rollback | SignalR/WebSocket | Thêm server contract/vận hành realtime ngoài MVP |
| DEC-003 | `exchangeApiBaseUrl` riêng | Tách Exchange khỏi auth/gateway URL và hỗ trợ deploy config | Hard-code/URL tương đối | Không portable hoặc phụ thuộc gateway route |
| DEC-004 | Typed models + adapter service | Giữ contract rõ và component mỏng | `any` trong component | Mất compile-time safety và khó xử lý nullable/error |
| DEC-005 | Giữ snapshot cuối khi query lỗi | UX không nhấp nháy/mất dữ liệu và phản ánh stale rõ | Xóa board khi lỗi | Người dùng hiểu nhầm thị trường không có dữ liệu |
| DEC-006 | Không tự retry command | POST/DELETE có thể tạo side effect lặp | Retry tự động | Không có idempotency key durable trong MVP |

## Chiến lược kiểm thử

**Unit test**:
- `ExchangeApiService`: URL, request body, headers, enum/reason mapping và Problem Details mapping.
- Pure helpers: giới hạn/sắp xếp price levels, latest price, broker allow-list.

**Integration test**:
- HTTP test với mock `HttpClientTestingModule` cho load board, refresh, place, cancel và lỗi 429/5xx.
- Nếu môi trường cho phép, smoke consumer với Exchange chạy local để xác nhận CORS và JSON contract.

**Contract test**:
- Assert các endpoint/field/enum MVP 02 trong `contracts/market-board-ui.md`; không thay đổi server contract.

**Permission/security test**:
- Không render broker ngoài allow-list.
- Không ghi `Authorization`, token hoặc secret vào model/log/UI.
- Route `/exchange` không bị `AuthGuard` chặn nhưng command vẫn chỉ gửi broker demo.

**E2E/manual test**:
- Hai lệnh đối ứng, lệnh chờ/hủy, rejection, polling, refresh browser và mất kết nối theo [quickstart.md](quickstart.md).

**Regression test**:
- `npm run build`, frontend test suite hiện có.
- `dotnet build/test` toàn bộ Exchange để chứng minh không đổi behavior backend.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000012-market-board/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── market-board-ui.md
└── checklists/requirements.md
```

### Source code

```text
flex-microfrontend/
├── src/app/app-routing.module.ts                 # thêm lazy route /exchange
├── src/app/exchange/
│   ├── exchange.module.ts
│   ├── exchange-routing.module.ts
│   ├── market-board.component.ts
│   ├── market-board.component.html
│   ├── market-board.component.scss
│   ├── market-board.component.spec.ts
│   ├── exchange-api.service.ts
│   ├── exchange-api.service.spec.ts
│   └── exchange.models.ts
└── src/environments/
    ├── environment.ts                             # URL/config dev
    └── environment.prod.ts                        # URL/config deploy
```

**Quyết định cấu trúc**: Co-locate page, adapter, models và tests trong feature `exchange`; giữ `AppRoutingModule` làm composition boundary. Không thêm shared abstraction cho một feature dùng một lần.

## Rollout & Rollback

**Kế hoạch rollout**:

1. Build/test frontend và Exchange regression.
2. Deploy frontend với route `/exchange` và `exchangeApiBaseUrl` trỏ tới Exchange phù hợp môi trường.
3. Chạy `/health` và smoke flow hai lệnh đối ứng, hủy lệnh chờ, refresh browser.
4. Theo dõi lỗi request/polling trong phiên demo trước khi mở rộng người dùng.

**Tương thích ngược**: API Exchange không đổi; build frontend cũ vẫn chạy độc lập. Route mới không ảnh hưởng các route auth hiện tại.

**Feature flag/config**: Không cần feature flag riêng trong MVP; bật/tắt bằng deploy frontend hoặc không công khai route. `exchangeApiBaseUrl`, `exchangeSymbol`, `pollingIntervalMs`, `demoBrokers` là cấu hình deploy.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**:
- Redeploy frontend artifact trước MVP 3 hoặc bỏ route `/exchange`.
- Khôi phục `exchangeApiBaseUrl` nếu cấu hình sai.

**Rollback dữ liệu/migration**: Không áp dụng; hủy order demo đang chờ qua Exchange nếu cần dọn trạng thái phiên.

**Điều kiện kích hoạt rollback**:
- UI báo accepted/cancelled sai so với Exchange.
- Lỗi request hoặc polling tăng bất thường, tạo command lặp, hoặc CORS/config khiến bảng điện không tải được.

## Observability & Debug

**Log cần có**:
- Frontend dev-safe: `operation`, `symbol`, `brokerId` (demo), `orderId` nếu có, `result`, `httpStatus`, `correlationId` và thời gian request; production chỉ dùng cơ chế logging hiện có khi được phép.
- Backend Exchange tiếp tục log structured fields hiện có.

**Dữ liệu không được log**:
- `Authorization`, bearer token, secret, API key, raw Problem Details, request headers và thông tin tài khoản ngoài broker demo.

**Metric cần theo dõi**:
- Tỷ lệ refresh thành công/thất bại, latency place/cancel, số lần rejection, số lần stale và số lỗi network/429 trong phiên demo.

**Trace/Correlation**:
- Mỗi place/cancel gửi `X-Correlation-Id`; giữ id trong state kết quả để đối chiếu backend log.
- Polling query dùng correlation id theo lần refresh hoặc không gửi để backend fallback.

**Cách kiểm tra sau release**:
- Mở `/health`, `/exchange`, thực hiện quickstart, kiểm tra browser network status/latency và đối chiếu `GET /api/orderbook`/`GET /api/trades`.

**Tình huống debug chính**:
- CORS/base URL sai, enum mapping sai, stale do Exchange unavailable, 429 do polling, command lặp hoặc mismatch giữa order status và board.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. Thiết kế giữ một feature module, một adapter service và polling bounded; không thêm mediator, repository, realtime broker hoặc database.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong `research.md`.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module, điểm thay đổi và boundary.
- [x] Idempotency/concurrency/retry đã được đánh giá.
- [x] Mọi US/FR P1 và security/NFR liên quan có mapping tới path, contract, model và test.
- [x] Tác động database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Contract/API thay đổi đã xác nhận không đổi và có compatibility check.
- [x] Dữ liệu/migration/backfill đã ghi rõ không áp dụng.
- [x] Quyết định kỹ thuật chính có lý do và phương án bị loại.
- [x] Chiến lược kiểm thử bao phủ unit, integration, contract, security, E2E/manual và regression.
- [x] Rollout, rollback, config và backward compatibility đã rõ.
- [x] Observability/debug có log field, dữ liệu cấm log, metric/trace và smoke check.
- [x] Không còn cây thư mục mẫu/generic; path source là path thật hoặc path feature sẽ tạo.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
