# Research: Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture

**Input**: [spec.md](spec.md) · **Ngày**: 2026-07-30

## TQ-001: Có cần migration/backfill dữ liệu không?

- **Decision**: Không. Schema PostgreSQL hiện có (`meta_account_connections`, `instagram_page_connections`) giữ nguyên tên bảng/cột/index. Việc di chuyển `AppDbContext` sang project `Flex.Agent.Infrastructures` không phát sinh migration mới — migration hiện có trong `Data/Migrations` được copy nguyên trạng sang project mới, namespace cập nhật nhưng nội dung migration (Up/Down) không đổi.
- **Rationale**: FR-007 (KHÔNG ĐƯỢC thay đổi schema) và BR không cho phép breaking migration. EF Core migration chỉ phụ thuộc vào `ModelSnapshot` và các file migration, không phụ thuộc project chứa chúng.
- **Alternatives considered**: Tạo migration "reset" mới sau khi đổi namespace — bị loại vì rủi ro drift schema và không cần thiết khi assembly chứa migration không ảnh hưởng đến SQL sinh ra.
- **Rủi ro còn lại**: Nếu đổi `RootNamespace`/`AssemblyName` mà không cập nhật đúng `migrationsAssembly` (nếu có cấu hình `MigrationsAssembly`), EF Core có thể không tìm thấy migration. Cần verify bằng `dotnet ef migrations list` sau khi tái cấu trúc (xem quickstart.md).

## TQ-002: Dùng flow/module hiện có hay tạo extension point mới?

- **Decision**: Dùng lại đúng flow DI hiện có (`AddInstagramChannel()` trong `DependencyInjection.cs`), chỉ đổi namespace/project chứa nó sang `Flex.Agent` (API host) hoặc `Flex.Agent.Infrastructures` tuỳ thành phần. Không tạo extension point/abstraction mới ngoài việc tách theo layer.
- **Rationale**: MVP-005 giới hạn phạm vi chỉ tái cấu trúc mã nguồn hiện có, không thêm tính năng hay abstraction mới (nguyên tắc "Thay đổi phẫu thuật" trong constitution §5.V).
- **Alternatives considered**: Tạo interface/abstraction mới cho từng channel để chuẩn bị multi-channel — bị loại vì Clarifications Session 2026-07-30 đã chốt "chỉ tách theo layer", không tách theo channel trong phạm vi này.

## TQ-003: Contract hiện tại có cần giữ backward compatibility không?

- **Decision**: Có — bắt buộc. Toàn bộ route, request/response contract của `InstagramChannelController` và `InstagramWebhookController` PHẢI giữ nguyên (FR-004).
- **Rationale**: Đây là service đang chạy production với Meta/Instagram webhook đã đăng ký; đổi route hoặc payload sẽ phá vỡ tích hợp bên ngoài (Meta Platform) mà team không kiểm soát được lịch trình cập nhật.
- **Alternatives considered**: Không có — đây là ràng buộc cứng từ spec (Ngoài phạm vi §15: "Thay đổi API contract, request/response, hoặc business rule hiện có").

## Phát hiện bổ sung (không phải NEEDS CLARIFICATION nhưng ảnh hưởng plan)

- **Chưa có test project khả thi**: Thư mục `tests/Channels/{Facebook,Instagram,Shared}` chứa các file `.cs` test nhưng **không có `.csproj`** nào trong toàn bộ repo ngoài `FlexAgentService.csproj` (project Web SDK, không phải test SDK). Nghĩa là bộ test hiện tại không chạy được (`dotnet test` sẽ không tìm thấy project nào). Để FR-005 ("test hiện có PHẢI pass") có ý nghĩa thực thi được, plan PHẢI tạo một test project mới (`Flex.Agent.Tests`) tham chiếu `Flex.Agent`, di chuyển các file test hiện có vào đó, và xác nhận chúng build + chạy được — đây là điều kiện tiên quyết để verify AC-003, không phải mở rộng scope ngoài spec (spec MVP-004 giả định trước có test project hoạt động).
- **Naming convention project**: theo Clarifications, dùng `Flex.Agent` (API host, giữ `Program.cs`/`AssemblyName=Flex.Agent`), `Flex.Agent.Domain`, `Flex.Agent.Infrastructures` — đúng mẫu `Flex.Auth` / `Flex.Domain` / `Flex.Infrastructures` của auth-service.
- **Project reference graph tham chiếu từ auth-service**: `Flex.Agent.Infrastructures` → `Flex.Agent.Domain`; `Flex.Agent` (API) → `Flex.Agent.Infrastructures` (transitively kéo theo Domain). Không có tham chiếu ngược.
- **Phân loại thư mục hiện có theo layer**:
  - `Channels/ChannelType.cs` (enum nghiệp vụ) → `Flex.Agent.Domain`.
  - `Channels/Instagram/{InstagramPageConnection.cs, MetaAccountConnection.cs}` (entity persist) → `Flex.Agent.Domain`.
  - `Data/AppDbContext.cs`, `Data/Migrations/*` → `Flex.Agent.Infrastructures`.
  - `Shared/ChannelTokenEncryptionService.cs` (dịch vụ hạ tầng mã hoá) → `Flex.Agent.Infrastructures`.
  - `Channels/Instagram/{InstagramChannelController.cs, InstagramWebhookController.cs}` (HTTP entrypoint), `DependencyInjection.cs`, `InstagramOAuthService.cs`, `InstagramPageService.cs`, `InstagramWebhookHandler.cs`, `Dtos/*` (application/service logic + API) → `Flex.Agent` (API host), theo đúng cách `flex-auth-service` đặt `Controllers/`, `Services/` trong project `Flex.Auth` chứ không phải `Flex.Infrastructures`.
  - `Program.cs`, `appsettings.*.json` → `Flex.Agent` (API host).
