# Tasks: Quản lý Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

**Đầu vào**: Design documents từ `specs/000020-session-lifecycle/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Ghi chú quan trọng**: File `tasks.md` trước đó (không do quy trình Speckit tạo) tự khai báo toàn bộ 17 task "Completed", nhưng đối chiếu trực tiếp mã nguồn cho thấy nhiều khai báo đó **sai sự thật** (ví dụ: tự nhận đã "đảo ngược thứ tự ghi CSDL trước khi mutate in-memory" nhưng code vẫn mutate trước; tự nhận đã "xác minh tích hợp Frontend" nhưng `market-board.component.ts` chưa được sửa). File này được viết lại từ khảo sát thật từng dòng code, không dựa trên báo cáo cũ.

**Tests**: Test Gate là bắt buộc theo `plan.md` § Chiến lược kiểm thử. Test tự động cho các bug đã phát hiện PHẢI được viết để fail trước khi sửa, pass sau khi sửa.

**Tổ chức**: Task nhóm theo user story (`US1` = spec US-001, `US2` = spec US-002).

## Format: `[ID] [P?] [Story?] Description with path`

---

## Phase 1: Foundational (Blocking Prerequisites)

**Mục đích**: Hạ tầng lõi (state machine, enum, contract error mapping) PHẢI đúng trước khi bất kỳ user story nào được coi là hoàn chỉnh — cả 2 story đều phụ thuộc `TradingSessionPhase`/`TradingSessionState`/`SessionService.TryAdvance`.

- [x] T001 `TradingSessionPhase` đã mở rộng thành 7 giá trị (`PreOpen, ATO, Continuous, Intermission, ATC, PLO, Close`) trong `flex-exchange-service/src/Flex.Exchange.Domain/TradingSession/TradingSessionState.cs` (dòng 3-14) — khớp FR-001.

- [x] T002 Sửa `TradingSessionState.TryAdvance` trong `flex-exchange-service/src/Flex.Exchange.Domain/TradingSession/TradingSessionState.cs` (dòng 49-72): switch hiện tại map **cố định** `Continuous → Intermission` và `Intermission → Continuous`, không có nhánh nào đưa `Continuous` (sau khi đã qua `Intermission`) sang `ATC`. Kết quả: phiên lặp vô hạn `Continuous ↔ Intermission`, **không bao giờ tự đến `ATC`/`PLO`/`Close`** qua đường chạy thật (`SessionWorker`). Phải thêm cờ đánh dấu đã qua `Intermission` (hoặc dùng `Continuous2DurationSeconds` đã có sẵn nhưng chưa dùng trong `MarketSessionScheduleOptions`, `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/TradingSessionOptions.cs` dòng 11) để phân biệt lượt `Continuous` sáng/chiều. Vi phạm FR-001/BR-001, chặn AC-003/AC-004.

- [x] T003 (phụ thuộc T002) Sửa `SessionService.TryAdvance` trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/SessionService.cs` (dòng 97-129): dòng 101 gọi `current.TryAdvance(...)` **mutate in-memory ngay lập tức**, TRƯỚC khi thử ghi CSDL (dòng 106-124); nếu cả 3 lần ghi CSDL đều thất bại, code vẫn `Publish("SESSION_STATE_CHANGED", ...)` và trả `true` — tức là trạng thái đã đổi dù CSDL chưa lưu được. Vi phạm trực tiếp BR-007 ("trạng thái phiên KHÔNG được coi là đã chuyển... cho đến khi ghi CSDL thành công"). Phải đảo thứ tự: tính state kế tiếp trước, ghi CSDL trước, chỉ mutate in-memory + publish sau khi ghi thành công. Giữ nguyên phần retry 3 lần + `LogCritical` (dòng 108-123, đã đúng NFR-002).

- [x] T004 `OrderType` enum (`LO`, `ATO`, `ATC`) đã tạo trong `flex-exchange-service/src/Flex.Exchange.Domain/Enums/OrderType.cs` — khớp data-model.md.

- [x] T005 `CancelNotAllowedInCurrentSession`, `OrderTypeNotAllowedInCurrentSession` đã thêm vào `flex-exchange-service/src/Flex.Exchange.Domain/Enums/RejectReason.cs`.

- [x] T006 **[CRITICAL]** Thêm `CancelNotAllowedInCurrentSession`, `OrderTypeNotAllowedInCurrentSession` vào enum **riêng** `Flex.Exchange.Application.Contracts.RejectReason` trong `flex-exchange-service/src/Flex.Exchange.Application/Contracts/ExchangeContracts.cs` (dòng 9-22 — đây KHÁC `Domain.Enums.RejectReason` đã sửa ở T005), và thêm 2 case tương ứng vào `ExchangeService.ToContract(DomainRejectReason? reason)` trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (dòng 259-274). Hiện switch không có 2 case này nên rơi vào `_ => throw new ArgumentOutOfRangeException` — **`DELETE /api/orders/{orderId}` sẽ trả lỗi 500 (crash) thay vì từ chối rõ ràng** khi hủy lệnh trong `ATO`/`ATC`. Đây là bug chặn đúng kịch bản chính của AC-001.

- [x] T007 `IsAllowingCancel(market, out reason)` đã thêm vào `ISessionService`/`SessionService`, chặn hủy lệnh khi phiên `ATO`/`ATC` — `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/SessionService.cs` (dòng 157-177), khớp FR-002/FR-005/BR-001.

- [x] T008 (phụ thuộc T006 để không crash khi chạy thật) `ExchangeService.CancelOrder` đã resolve `market` từ order tìm thấy rồi gọi `IsAllowingCancel` trước khi cancel — `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (dòng 104-122), đúng thiết kế TQ-002/DEC-002.

**Checkpoint**: T002, T003, T006 phải xong trước khi User Story 1/2 được coi là hoàn chỉnh (dù có thể code song song).

---

## Phase 2: User Story 1 - Chặn hủy lệnh và sai loại lệnh trong ATO/ATC (Priority: P1)

**Goal**: Hủy lệnh bị từ chối rõ ràng trong `ATO`/`ATC`; đặt lệnh sai loại (`LO` thường khi cần `ATO`/`ATC`, hoặc ngược lại) bị từ chối; FE không khóa sai chức năng đặt/hủy lệnh theo `state` mới.

**Independent Test**:

1. `POST /api/session/start?market=HOSE`, chờ đến phase `ato`.
2. `POST /api/orders` với `orderType: "LO"` → `accepted = true` (BR-001 cho LO trong ATO). `POST /api/orders` với `orderType: "ATC"` → từ chối, `reason: OrderTypeNotAllowedInCurrentSession` (AC-005).
3. `DELETE /api/orders/{orderId}` với order vừa đặt → từ chối, `reason: CancelNotAllowedInCurrentSession`, **không phải lỗi 500** (AC-001).
4. Sau khi phase chuyển sang `continuous`: `DELETE /api/orders/{orderId}` → `cancelled = true` (AC-002).

### Tests for User Story 1

> Viết test TRƯỚC, đảm bảo fail trước khi sửa (do bug T006/T013/T014 đang tồn tại).

- [x] T009 [US1] Viết integration test `CancelOrder_ReturnsCancelNotAllowed_WhenSessionInAtoOrAtc` gọi thật `DELETE /api/orders/{orderId}` qua `WebApplicationFactory<Program>` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/OrdersApiTests.cs` (test hiện có `CancelOrderReturnsErrorWhenSessionInAtoOrAtc`, dòng ~136-149, chỉ gọi thẳng `ISessionService.IsAllowingCancel`, KHÔNG đi qua `ExchangeService`/`ToContract` nên không phát hiện được bug T006 — cần test end-to-end mới, không sửa test cũ). Fail trước T006 (exception 500), pass sau khi sửa.

- [x] T015 [US1] Viết integration test `PlaceOrder_RejectsAtcOrder_DuringAto` và `PlaceOrder_AcceptsLoOrder_DuringAto` gọi thật `POST /api/orders` với field `orderType` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/OrdersApiTests.cs`, xác nhận `reason: OrderTypeNotAllowedInCurrentSession` khi sai loại và `accepted: true` khi đúng loại. (phụ thuộc T012, T013, T014)

- [x] T017 [P] [US1] Mở rộng `flex-microfrontend/src/app/exchange/market-board.component.spec.ts` với case cho `canStartSession`/`canPlaceOrder`/`canCancelOrder` theo từng giá trị `state` (`preopen`, `ato`, `continuous`, `intermission`, `atc`, `plo`, `close`). (đi cùng đợt sửa T016, viết trước hoặc song song)

### Implementation for User Story 1

- [x] T010 [US1] Sửa `SessionService.IsAcceptingOrders` trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/SessionService.cs` (dòng 131-155): đổi `TradingSessionPhase.PLO => null` thành `TradingSessionPhase.PLO => nameof(RejectReason.SessionClosed)` (BR-006 — PLO phải từ chối toàn bộ lệnh vì cơ chế khớp PLO chưa triển khai), và đổi `TradingSessionPhase.Intermission => nameof(RejectReason.SessionNotOpen)` thành `TradingSessionPhase.Intermission => null` (spec mục 6 — Intermission phải nhận lệnh chờ, không từ chối). Hiện code đang làm **ngược lại hoàn toàn** với 2 quy tắc này.

- [x] T011 [US1] (phụ thuộc T010) Trong `IsOrderTypeAllowed` (`SessionService.cs`, dòng 179-210): thêm case `(TradingSessionPhase.Intermission, OrderType.LO) => true`; xóa case `(TradingSessionPhase.PLO, OrderType.LO) => true` (dòng 196 — PLO giờ đã bị `IsAcceptingOrders` chặn từ T010, case này thành dead code gây hiểu nhầm).

- [x] T012 [US1] Thêm field `OrderType OrderType = OrderType.LO` vào `PlaceOrderCommand` trong `flex-exchange-service/src/Flex.Exchange.Application/Contracts/ExchangeContracts.cs` (dòng 24-30) — hiện record này không có field `OrderType`.

- [x] T013 [US1] (phụ thuộc T012) Trong `ExchangeService.PlaceOrder` (`flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs`, dòng 72-102): sau bước gọi `IsAcceptingOrders` (dòng 80-84), gọi thêm `session.IsOrderTypeAllowed(market, command.OrderType, out var typeReason)`; nếu không hợp lệ, trả `PlaceOrderResult` thất bại với reason tương ứng. Hiện method này **hoàn toàn không gọi** `IsOrderTypeAllowed` dù `SessionService.IsOrderTypeAllowed` đã tồn tại (dead code, chưa từng được gọi).

- [x] T014 [US1] (phụ thuộc T012) Trong `OrdersController.Place` (`flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrdersController.cs`, dòng 14-30): truyền `request.OrderType` vào `PlaceOrderCommand` khi khởi tạo. Hiện field `PlaceOrderRequest.OrderType` (đã có sẵn ở `Models/PlaceOrderRequest.cs`) **không được đọc** — dead parameter, client gửi lên bị bỏ qua hoàn toàn.

- [x] T016 [US1] Sửa `flex-microfrontend/src/app/exchange/market-board.component.ts`: thay getter `isTradingActive` (dòng 214-217, hiện hardcode `state === 'open' || state === 'continuous'` — `'open'` không còn được BE trả về sau T001) bằng 3 getter: `canStartSession` (true khi chưa có phiên hoặc `state === 'preopen'`), `canPlaceOrder` (true khi `state` ∈ `{ato, continuous, atc, intermission}` — theo `IsAcceptingOrders` sau T010, loại trừ `preopen`/`plo`/`close`), `canCancelOrder` (true khi `state === 'continuous'` — theo BR-001 chỉ `Continuous` cho hủy lệnh). Cập nhật `market-board.component.html` (dòng 13, 24, 71-72, 74, 80, 82-84, 94) dùng đúng getter cho từng vị trí thay vì `isTradingActive` chung. (phụ thuộc T002, T010 để `state` phản ánh đúng lifecycle)

**Definition of Done**: T002, T003, T006, T009-T017 hoàn tất; Independent Test US1 chạy pass qua HTTP thật (không chỉ unit gọi thẳng service); FE không còn khóa sai chức năng đặt/hủy lệnh.

**Checkpoint**: User Story 1 hoàn chỉnh, test/validate độc lập được.

---

## Phase 3: User Story 2 - Chuyển đổi trạng thái phiên theo đúng lịch trình từng sàn (Priority: P1)

**Goal**: Phiên tự động chuyển đúng thứ tự 7-phase cho từng market, bỏ qua `ATO` khi `HasAto=false` và bỏ qua `PLO` khi `HasPlo=false`.

**Independent Test**:

1. `POST /api/session/start?market=HNX-Derivatives` (có ATO) → `GET /api/session` ngay sau đó trả `state: "preopen"`; chờ hết `PreOpenDurationSeconds` → `state: "ato"` (AC-003).
2. `POST /api/session/start?market=UPCoM` (không ATO) → chờ hết `PreOpenDurationSeconds` → `state: "continuous"` ngay, không qua `"ato"` (AC-004).
3. Với market `HOSE` (có ATO, không PLO): để phiên chạy tự nhiên qua hết `Continuous` sáng → `Intermission` → `Continuous` chiều → **phải tự đến `ATC`** rồi `Close` (không cần can thiệp thủ công) — đây là điều T002 phải sửa để test này pass.

### Tests for User Story 2

- [x] T018 [P] [US2] Viết lại test `AdvancesFull7PhaseLifecycleForHose` trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/TradingSessionStateTests.cs` (dòng 8-27) để xác nhận `TryAdvance` tự nhiên đi hết `Continuous(sáng) → Intermission → Continuous(chiều) → ATC → Close` **không gọi `AdvanceDirectlyTo`** (test hiện tại ở dòng 23 dùng `AdvanceDirectlyTo(ATC, ...)` để né bug T002 thay vì để `TryAdvance` tự chuyển — phải sửa để test thực sự exercise đường chạy thật). Fail trước T002, pass sau khi sửa.

- [x] T019 [P] [US2] Mở rộng `AdvancesLifecycleWithoutAtoForHnx` (`TradingSessionStateTests.cs`, dòng 29-38) hoặc thêm test mới, xác nhận thêm case `HasPlo=false` (`HOSE`, `UPCoM`, `HNX-Derivatives`): khi `ATC` xong phải vào thẳng `Close`, không qua `PLO`.

### Implementation for User Story 2

- [x] T020 [US2] Thêm block `TradingSession:MarketSchedules` vào `flex-exchange-service/src/Flex.Exchange.Api/appsettings.json` (hiện chỉ có `TradingSession:Markets`/`OpenDurationSeconds`/`ContinuousDurationSeconds` phẳng ở dòng 17-23; lịch theo từng market hiện chỉ tồn tại dưới dạng default hard-code trong `TradingSessionOptions.cs` dòng 22-28, không cấu hình được qua `appsettings.json` như `plan.md`/`data-model.md` § 6 mô tả) — phản ánh đúng BR-002 (`UPCoM`: không ATO/PLO)/BR-003 (`HNX`: không ATO, có PLO) cho cả 4 market. (phụ thuộc T002 để field `Continuous2DurationSeconds` có tác dụng thật)

**Definition of Done**: T002, T018-T020 hoàn tất; Independent Test US2 chạy pass cho cả 4 market.

**Checkpoint**: User Story 1 và 2 đều hoạt động độc lập, phiên chuyển đúng lifecycle thật (không cần `AdvanceDirectlyTo` thủ công).

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T021 [P] Chạy `dotnet test` cho toàn bộ `flex-exchange-service` (`Flex.Exchange.Domain.Tests`, `Flex.Exchange.Api.Tests`) sau khi hoàn tất T002-T020, xác nhận không có regression cho luồng `Continuous`/khớp lệnh cơ bản (MVP 000013 — `MatchingEngineTests.cs`, `MvpAcceptanceTests.cs`).

- [ ] T022 [P] Chạy thủ công 6 kịch bản trong `specs/000020-session-lifecycle/quickstart.md` qua `Flex.Exchange.http` và UI `flex-microfrontend`, xác nhận đúng hành vi thật (không phải hành vi lý thuyết). **Chưa chạy được trong phiên này** — `ng test`/`ng serve` của `flex-microfrontend` hiện fail toàn dự án với lỗi `TS1479` (CommonJS/ESM) trên hàng chục file không liên quan đến feature này (`polyfills.ts`, `src/test.ts`, và nhiều component `pages/ui/*`), đây là lỗi tooling có sẵn từ trước, không phải do T016/T017 gây ra. Cần xử lý riêng (ngoài phạm vi feature 000020) trước khi chạy được `ng test`/`ng serve` thật.

- [x] T023 Kiểm tra `LogCritical` trong `SessionService.TryAdvance` (sau khi sửa T003) chỉ log `sessionId`, `market`, `state`, `attempt` — không log token/secret/dữ liệu nhạy cảm, theo NFR-002/Observability plan.md.

---

## Validation Commands

- Build backend: `dotnet build flex-exchange-service/Flex.Exchange.sln` (hoặc solution file tương ứng trong `flex-exchange-service/`)
- Run tests: `dotnet test flex-exchange-service/tests/Flex.Exchange.Domain.Tests` và `dotnet test flex-exchange-service/tests/Flex.Exchange.Api.Tests`
- Run frontend checks: `cd flex-microfrontend && npm test -- --include='**/market-board.component.spec.ts'`
- Run migration/smoke check: Không áp dụng — không có migration (xem plan.md § Dữ liệu & Migration)

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| FR-001 (7-phase state machine) | T001, T002, T018, T019 |
| FR-002 (chặn hủy lệnh ATO/ATC) | T006, T007, T008, T009 |
| FR-003 (kiểm soát loại lệnh) | T010, T011, T012, T013, T014, T015 |
| FR-004 (lịch phiên theo market) | T020 |
| FR-005 (`IsAllowingCancel`) | T007 |
| FR-006 (`IsOrderTypeAllowed`) | T011, T013 |
| BR-001 (LO+định kỳ trong ATO/ATC, cấm hủy) | T007, T009, T010, T011 |
| BR-002/BR-003 (lịch riêng UPCoM/HNX) | T019, T020 |
| BR-004 (hủy lệnh khi Close) | Đã có sẵn (`CloseAndReset`, không đổi) |
| BR-005 (từ chối lệnh PreOpen) | Đã đúng sẵn trong `IsAcceptingOrders` (không cần sửa) |
| BR-006 (từ chối lệnh PLO) | T010 |
| BR-007/NFR-002 (ghi CSDL trước transition + log) | T003, T023 |
| US1/AC-001 | T006, T009 |
| US1/AC-002 | T007, T008 |
| US1/AC-005 | T012, T013, T014, T015 |
| US2/AC-003, AC-004 | T002, T018, T019 |
| Hệ quả FE (market-board.component.ts) | T016, T017 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: T002, T003, T006 chặn Definition of Done của cả US1 và US2 (dù T009-T020 có thể bắt đầu code song song, không thể coi story "xong" nếu Foundational chưa xong).
- **User Story 1 (Phase 2)** và **User Story 2 (Phase 3)**: độc lập với nhau về file, có thể làm song song.
- **Polish (Final Phase)**: phụ thuộc toàn bộ Phase 1-3.

### Trong từng phase

- T002 → T003 (SessionService phụ thuộc TradingSessionState đã sửa) → T018/T019/T020.
- T006 → T008, T009 (tránh crash khi test thật).
- T010 → T011, T016.
- T012 → T013, T014, T015.

### Parallel Opportunities

- T004, T005, T007, T008 đã `[x]` — không cần làm lại.
- T009, T015, T017 (khác file) có thể chạy song song sau khi dependency tương ứng xong.
- T018, T019 (cùng file `TradingSessionStateTests.cs` nhưng khác method) có thể làm gần như song song, review chung.
- T021, T022, T023 độc lập, chạy song song ở Polish.

---

## Implementation Strategy

### Thứ tự khuyến nghị

1. Hoàn tất Foundational (T002, T003, T006) — đây là 3 bug nghiêm trọng nhất, chặn cả 2 story.
2. Song song: User Story 1 (T009-T017) và User Story 2 (T018-T020).
3. Polish (T021-T023).
4. Chạy `/speckit-converge` lại sau khi implement để xác nhận không còn gap.

### Ghi chú

- Đây KHÔNG phải lần đầu implement — phần lớn hạ tầng đã tồn tại (8/23 task đã `[x]`), nhưng có **2 bug CRITICAL** (T003 vi phạm BR-007, T006 gây crash 500) và **nhiều chỗ chưa wiring xong** (T012-T014 order type hoàn toàn dead code, T016 FE chưa sửa) cần xử lý trước khi tính năng dùng được đúng như spec.

---

## Phase 4: Convergence

> Sinh bởi `/speckit-converge` sau khi T001-T023 đã implement. Không sửa/xóa task cũ ở trên — chỉ bổ sung phần còn thiếu phát hiện được khi đối chiếu code thật với spec/plan.

- [x] T024 Sửa `SessionWorker.RunMarketLoopAsync` trong `flex-exchange-service/src/Flex.Exchange.Api/HostedServices/SessionWorker.cs` (case `"atc"`, dòng 59-62) để gọi `bot.CancelAll()` + `sessions.CloseAndReset(market)` mỗi khi phiên vào `Close` — không chỉ trong case `"plo"` (dòng 64-69). Hiện tại với market `HasPlo=false` (`HOSE`, `UPCoM`, `HNX-Derivatives`), `TryAdvance` đưa phase thẳng `ATC` → `Close` nhưng không có nơi nào gọi `CancelAll`, khiến lệnh còn chờ khớp không bao giờ bị hủy khi đóng phiên. per BR-004 (missing)

- [x] T025 Sửa `SessionService.CloseAndReset` trong `flex-exchange-service/src/Flex.Exchange.Application/TradingSession/SessionService.cs`: áp dụng cùng pattern đã dùng ở `TryAdvance` (T003) — tính preview trạng thái `Close` trước, ghi CSDL trước (retry 3 lần + `LogCritical` khi thất bại, giống dòng 108-124 hiện có trong `TryAdvance`), chỉ `AdvanceDirectlyTo`/mutate in-memory + `Publish` sau khi ghi CSDL thành công. Hiện method này vẫn mutate in-memory trước, chỉ `try/catch` 1 lần với `LogError` (không retry). per BR-007/NFR-002 (partial)

- [x] T026 [P] Xác nhận với người yêu cầu (hoặc xóa nếu không cần) alias `Open = PreOpen` trong enum `TradingSessionPhase` (`flex-exchange-service/src/Flex.Exchange.Domain/TradingSession/TradingSessionState.cs`, dòng 13) — không có trong 7 giá trị canonical mà `data-model.md` § 1 quy định, không được spec/plan yêu cầu. per data-model.md § 1 (unrequested) — **Đã xóa**: xác nhận không có nơi nào trong code thật sự gọi `TryAdvance`/`PreviewAdvance` với `TradingSessionPhase.Open`, và `SessionWorker`'s `case "open":` cũng không bao giờ chạy tới (enum trùng giá trị luôn `ToString()` ra tên khai báo đầu tiên `"PreOpen"`) — xóa alias, đơn giản hóa điều kiện `TryAdvance`/`PreviewAdvance`, xóa `case "open":` khỏi `SessionWorker`.

---

## Phase 5: Convergence

> Sinh bởi `/speckit-converge` sau khi T001-T026 đã implement. Không sửa/xóa task cũ ở trên — chỉ bổ sung phần còn thiếu phát hiện được khi đối chiếu code thật với spec/plan.

- [x] T027 Sửa `SessionWorker.RunMarketLoopAsync` trong `flex-exchange-service/src/Flex.Exchange.Api/HostedServices/SessionWorker.cs` để dùng `schedule.Continuous2DurationSeconds` cho lượt `Continuous` thứ hai (sau khi đã qua `Intermission`), thay vì dùng chung `schedule.ContinuousDurationSeconds` cho cả 2 lượt sáng/chiều như hiện tại (case `"continuous"`, dòng 43-51). Field `Continuous2DurationSeconds` đã được khai báo (`TradingSessionOptions.cs` dòng 11) và cấu hình đầy đủ cho cả 4 market trong `appsettings.json` (T020) nhưng chưa từng được đọc ở bất kỳ đâu — cần một cách để `SessionWorker` biết đang ở lượt `Continuous` thứ mấy (ví dụ dựa vào việc `ContinuousStartedAt`/trạng thái đã đi qua `Intermission` chưa, tương tự cờ `intermissionPassed` đã thêm ở `TradingSessionState`). per FR-004/MVP-003 (partial)
