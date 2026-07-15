# Research: Lõi khớp lệnh và order book (FlexSim MVP 01)

**Ngày**: 2026-07-14
**Nguồn khảo sát**: `flex-auth-service` (pattern chuẩn), `docs/mvp/01-matching-rules.md`, `docs/mvp/flexsim-roadmap.md`, spec 000010.

Trả lời các câu hỏi kỹ thuật TQ-001..TQ-006 trong `plan.md`. Không còn `CẦN LÀM RÕ` tồn đọng.

---

## TQ-001 — Migration/backfill

**Decision**: Không có migration/backfill.

**Rationale**: FR-010 cấm database; trạng thái hoàn toàn in-memory và mất khi tắt tiến trình (spec §14 loại trừ lưu trữ bền vững).

**Alternatives considered**: Không áp dụng — không có phương án nào khác phù hợp scope.

---

## TQ-002 — Layout solution theo pattern auth service (DEC-001, DEC-002)

**Khảo sát `flex-auth-service`**:
- .NET 9 (`net9.0`), solution `Flex.Auth.sln` với 3 project: `src/Flex.Auth` (ASP.NET Core host), `src/Flex.Domain` (entities/events/constants/abstractions), `src/Flex.Infrastructures` (EF Core/Oracle, RabbitMQ, Serilog, JWT, middleware...).
- Naming: entity singular không suffix (`User`, `OutboxMessage`); service `{Name}Service`; options `{Feature}Options`; domain event tên nghiệp vụ thì quá khứ.
- Không có test project trong repo auth.

**Decision**:
- Solution `Flex.Exchange.sln` gồm `src/Flex.Exchange` (ASP.NET Core Web API host), `src/Flex.Domain` (toàn bộ engine) và `src/Flex.Infrastructures` (cross-cutting dùng ngay).
- Engine khớp lệnh (entities, events, commands, `MatchingEngine`, `OrderValidator`) đặt trong `Flex.Domain`.

**Rationale**:
- Giữ được khung `src/` + naming + phân lớp của auth; spec yêu cầu service có API ngay trong MVP 01 (MVP-004, FR-011).
- `Flex.Infrastructures` chỉ mang các thành phần được host dùng ngay: Logging/Serilog, Exceptions, Observability, OpenAPI, Json và Responses; không tạo lớp persistence hay messaging suy đoán.
- Engine là pure logic không phụ thuộc hạ tầng → đúng định nghĩa project Domain; đặt ở host (như `Services/` của auth) sẽ buộc MVP 02 refactor khi thay host console bằng API.
- Kiểm chứng thủ công qua `Flex.Exchange.http` và Swagger đáp ứng quyết định stakeholder không có test tự động (MVP-005, EX-001 trong plan).

**Alternatives considered**:
- Console demo không API — loại: không đáp ứng MVP-004 và FR-011.
- Engine trong `src/Flex.Exchange/Services` — loại: trộn business logic thuần vào host, khó tái dùng ở MVP 02.

---

## TQ-003 — Backward compatibility của contract (DEC-005)

**Decision**: Chưa cần backward compatibility — chưa có consumer nào tồn tại. Contract gồm REST API cho demo cục bộ và contract in-process (commands/events/snapshot), được thiết kế theo đúng danh sách "Đầu ra cho MVP 02" để MVP 02 tái dùng nguyên vẹn (SC-004).

**Rationale**: Repo mới; consumer đầu tiên là `Flex.Exchange.http` và Swagger. Ràng buộc thật là *forward* compatibility: sự kiện phải đủ trường đối chiếu (FR-007) để API/WebSocket của MVP 02 chỉ serialize lại, không phải thêm dữ liệu vào engine.

**Alternatives considered**: Event bus nội bộ hoặc WebSocket ngay MVP 01 — loại: vượt scope FR-010; MVP 02 mới thêm cơ chế publish realtime.

---

## TQ-004 — Biểu diễn giá/khối lượng và tính xác định (DEC-003, DEC-004)

**Decision**:
- Giá: `long` (đồng VND nguyên). Khối lượng: `long` (số cổ phiếu nguyên).
- Ưu tiên thời gian: `SequenceNumber` (long, tăng dần) do engine cấp tại thời điểm nhận command; timestamp (`ReceivedAt`) chỉ ghi nhận để hiển thị, **không** tham gia so sánh ưu tiên.
- Sự kiện đầu ra đánh số `EventSequence` tuần tự toàn cục.
- Cấm trong `Flex.Domain/Matching`: `DateTime.Now/UtcNow` trong logic quyết định, `Random`, `Guid.NewGuid()` cho ID (dùng số tuần tự), duyệt `Dictionary`/`HashSet` không có thứ tự xác định trong luồng khớp.

**Rationale**: Số học nguyên và sequence tuần tự loại bỏ toàn bộ nguồn phi xác định (FR-009, NFR-001): không sai số thập phân, không phụ thuộc độ phân giải đồng hồ, không phụ thuộc thứ tự hash. Giá chứng khoán VN không có phần lẻ dưới đồng.

**Alternatives considered**:
- `decimal` cho giá — loại: không cần độ chính xác thập phân, kiểm tra tick/lô bằng modulo số nguyên đơn giản hơn.
- `DateTime.UtcNow` làm khóa ưu tiên — loại: trùng timestamp giữa hai lệnh liên tiếp là thực tế; kết quả phụ thuộc máy chạy, phá NFR-001.

---

## TQ-005 — Chiến lược kiểm chứng khi không có test tự động (DEC-006)

**Decision**: Commit `Flex.Exchange.http` chứa các request/kỳ vọng cho sáu nhóm hành vi của SC-003, đồng thời bật Swagger UI trong Development để chạy demo cục bộ. Không tạo test project tự động.

**Rationale**: Đây là quyết định stakeholder đã được ghi thành EX-001 trong plan. File `.http` là pattern sẵn có của auth service, lặp lại được, và trả về đúng payload REST mà MVP 02 sẽ kế thừa.

**Alternatives considered**: Bộ xUnit tối thiểu cho engine — loại theo quyết định stakeholder; rủi ro được chấp nhận và theo dõi trong EX-001.

---

## TQ-006 — Giá trị mặc định cấu hình mã FXS (DEC-007)

**Decision**: `InstrumentConfig` mặc định cho FXS (theo phong cách HOSE, đã đơn giản hóa):

| Tham số | Giá trị | Ghi chú |
|---------|---------|---------|
| Symbol | `FXS` | Mã giả lập duy nhất |
| Giá tham chiếu | 20.000 | Khớp kịch bản demo |
| Bước giá (tick) | 100 | Một mức tick duy nhất, không theo bậc giá như HOSE thật — đủ cho MVP |
| Biên độ | ±7% | Trần 21.400, sàn 18.600 (làm tròn về tick hợp lệ) |
| Lô chẵn | 100 | Khối lượng phải là bội số của 100 |

**Rationale**: Quen thuộc với nghiệp vụ chứng khoán VN; mọi giá trị trong kịch bản demo (20.000, khối lượng 100/200) đều hợp lệ; là tham số của `InstrumentConfig` truyền vào engine nên đổi được mà không sửa quy tắc khớp (NFR-003). Tick đơn (không theo bậc giá 3 tầng của HOSE) là đơn giản hóa có chủ đích — kiểm tra tick vẫn hiện diện (FR-001) nhưng không thêm bảng bậc giá chưa cần.

**Alternatives considered**:
- Bảng tick 3 bậc như HOSE thật (10/50/100 theo vùng giá) — loại: thêm phức tạp không phục vụ AC nào của MVP 01; có thể nâng cấp trong `InstrumentConfig` sau.
- Không kiểm tra biên độ — loại: FR-001 yêu cầu biên độ là một ràng buộc kiểm tra bắt buộc.

---

## Rủi ro còn lại sau research

- Cấu trúc dữ liệu sổ lệnh (sorted structure cụ thể) để ngỏ cho implementation, miễn thỏa bất biến "duyệt theo giá tốt nhất rồi FIFO" và tính xác định — task implement chọn cấu trúc đơn giản nhất đạt yêu cầu (quy mô demo, không cần tối ưu).
- Trần/sàn làm tròn về tick (21.400/18.600) cần ghi rõ trong config seed để test biên độ không mơ hồ — đã đưa vào data-model.
