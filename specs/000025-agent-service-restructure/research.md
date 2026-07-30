# Research: Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture

**Input**: [spec.md](spec.md) · **Ngày**: 2026-07-30

## TQ-001: Có cần migration/backfill dữ liệu không?

- **Decision**: Không. Schema PostgreSQL hiện có (`meta_account_connections`, `instagram_page_connections`) giữ nguyên tên bảng/cột/index.
- **Phát hiện quan trọng (điều chỉnh giả định ban đầu)**: `Data/Migrations` **không phải** EF Core code-first migration (không có file `*.Designer.cs` hay `ModelSnapshot.cs`) — nó chỉ chứa một file SQL thủ công `AddInstagramTables.sql` áp dụng schema trực tiếp bằng tay. `AppDbContext` không dùng `dotnet ef migrations` trong dự án hiện tại (dù package `Microsoft.EntityFrameworkCore.Design` có được reference, nó chưa được dùng để tạo migration thật nào). Vì vậy việc di chuyển sang `Flex.Agent.Infrastructures` chỉ là di chuyển file SQL nguyên trạng, không có rủi ro `MigrationsAssembly`/`ModelSnapshot`.
- **Rationale**: FR-007 (KHÔNG ĐƯỢC thay đổi schema) — chỉ cần đảm bảo file SQL được copy nguyên văn và `AppDbContext.OnModelCreating` (fluent mapping) tiếp tục khớp đúng schema đã tạo bằng SQL đó.
- **Alternatives considered**: Chuyển sang EF Core code-first migration thật (`dotnet ef migrations add`) trong lúc tái cấu trúc — bị loại vì ngoài phạm vi (spec không yêu cầu đổi cách quản lý migration, chỉ tái cấu trúc project).
- **Rủi ro còn lại**: Không đáng kể — xác minh bằng cách so khớp nội dung `AddInstagramTables.sql` trước/sau di chuyển (diff phải rỗng) và chạy `dotnet build` + start service để `AppDbContext` map đúng lên schema đã có (xem quickstart.md).

## TQ-002: Dùng flow/module hiện có hay tạo extension point mới?

- **Decision**: Dùng lại đúng flow DI hiện có (`AddInstagramChannel()` trong `DependencyInjection.cs`), chỉ đổi namespace/project chứa nó sang `Flex.Agent` (API host) hoặc `Flex.Agent.Infrastructures` tuỳ thành phần. Không tạo extension point/abstraction mới ngoài việc tách theo layer.
- **Rationale**: MVP-005 giới hạn phạm vi chỉ tái cấu trúc mã nguồn hiện có, không thêm tính năng hay abstraction mới (nguyên tắc "Thay đổi phẫu thuật" trong constitution §5.V).
- **Alternatives considered**: Tạo interface/abstraction mới cho từng channel để chuẩn bị multi-channel — bị loại vì Clarifications Session 2026-07-30 đã chốt "chỉ tách theo layer", không tách theo channel trong phạm vi này.

## TQ-003: Contract hiện tại có cần giữ backward compatibility không?

- **Decision**: Có — bắt buộc. Toàn bộ route, request/response contract của `InstagramChannelController` và `InstagramWebhookController` PHẢI giữ nguyên (FR-004).
- **Rationale**: Đây là service đang chạy production với Meta/Instagram webhook đã đăng ký; đổi route hoặc payload sẽ phá vỡ tích hợp bên ngoài (Meta Platform) mà team không kiểm soát được lịch trình cập nhật.
- **Alternatives considered**: Không có — đây là ràng buộc cứng từ spec (Ngoài phạm vi §15: "Thay đổi API contract, request/response, hoặc business rule hiện có").

## Phát hiện bổ sung (không phải NEEDS CLARIFICATION nhưng ảnh hưởng plan)

- **Chưa có test project khả thi**: Thư mục `tests/Channels/{Facebook,Instagram,Shared}` chứa các file `.cs` test nhưng **không có `.csproj`** nào trong toàn bộ repo ngoài `FlexAgentService.csproj` (project Web SDK, không phải test SDK). Nghĩa là bộ test hiện tại không chạy được (`dotnet test` sẽ không tìm thấy project nào). Framework dùng trong các file là **xUnit** (`using Xunit;`). Để FR-005 ("test hiện có PHẢI pass") có ý nghĩa thực thi được, plan PHẢI tạo một test project mới (`Flex.Agent.Tests`) tham chiếu `Flex.Agent`, di chuyển các file test hiện có vào đó, và xác nhận chúng build + chạy được — đây là điều kiện tiên quyết để verify AC-003, không phải mở rộng scope ngoài spec (spec MVP-004 giả định trước có test project hoạt động).
- **Namespace test đã sai lệch với source hiện tại**: `tests/Channels/Shared/ChannelTokenEncryptionServiceTests.cs` và `tests/Channels/Instagram/InstagramPageServiceTests.cs` import `FlexAgentService.Channels.Shared`, nhưng file nguồn thật khai báo `namespace FlexAgentService.Shared` (`Shared/ChannelTokenEncryptionService.cs`) — hai namespace không khớp. Đây là bằng chứng thêm rằng bộ test chưa từng build được. Khi di chuyển sang `Flex.Agent.Infrastructures.Security` (namespace mới), PHẢI sửa `using` trong các file test này cho khớp, không chỉ đổi tiền tố `FlexAgentService` → `Flex.Agent`.
- **Naming convention project**: theo Clarifications, dùng `Flex.Agent` (API host, giữ `Program.cs`/`AssemblyName=Flex.Agent`), `Flex.Agent.Domain`, `Flex.Agent.Infrastructures` — đúng mẫu `Flex.Auth` / `Flex.Domain` / `Flex.Infrastructures` của auth-service.
- **Project reference graph tham chiếu từ auth-service**: `Flex.Agent.Infrastructures` → `Flex.Agent.Domain`; `Flex.Agent` (API) → `Flex.Agent.Infrastructures` (transitively kéo theo Domain). Không có tham chiếu ngược.
- **Phân loại thư mục hiện có theo layer**:
  - `Channels/ChannelType.cs` (enum nghiệp vụ) → `Flex.Agent.Domain`.
  - `Channels/Instagram/{InstagramPageConnection.cs, MetaAccountConnection.cs}` (entity persist) → `Flex.Agent.Domain`.
  - `Data/AppDbContext.cs`, `Data/Migrations/AddInstagramTables.sql` (file SQL thủ công, không phải EF Core code-first migration) → `Flex.Agent.Infrastructures`.
  - `Shared/ChannelTokenEncryptionService.cs` (dịch vụ hạ tầng mã hoá) → `Flex.Agent.Infrastructures`.
  - `Channels/Instagram/{InstagramChannelController.cs, InstagramWebhookController.cs}` (HTTP entrypoint), `DependencyInjection.cs`, `InstagramOAuthService.cs`, `InstagramPageService.cs`, `InstagramWebhookHandler.cs`, `Dtos/*` (application/service logic + API) → `Flex.Agent` (API host), theo đúng cách `flex-auth-service` đặt `Controllers/`, `Services/` trong project `Flex.Auth` chứ không phải `Flex.Infrastructures`.
  - `Program.cs`, `appsettings.*.json` → `Flex.Agent` (API host).
