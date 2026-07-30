# Quickstart: Xác thực tái cấu trúc Flex Agent Service

**Input**: [plan.md](plan.md) · [data-model.md](data-model.md) · [contracts/existing-api-contracts.md](contracts/existing-api-contracts.md)

Mục tiêu: xác nhận sau khi tách `flex-agent-service` thành `Flex.Agent.Domain` / `Flex.Agent.Infrastructures` / `Flex.Agent`, hệ thống build sạch, migration còn nguyên vẹn, test pass, và API hoạt động như trước (US-001, US-002).

## Prerequisites

- .NET 9 SDK
- PostgreSQL local (hoặc connection string trong `appsettings.Development.json` trỏ tới DB dev hiện có)
- `dotnet-ef` tool (`dotnet tool restore` hoặc cài global nếu chưa có)

## 1. Build toàn bộ solution

```powershell
dotnet restore Flex.Agent.sln
dotnet build Flex.Agent.sln
```

**Kỳ vọng**: build thành công cho cả 3 project (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent`) và project test mới (`Flex.Agent.Tests`), không có lỗi/warning mới liên quan tới namespace bị thiếu.

## 2. Xác nhận migration không đổi (TQ-001)

```powershell
dotnet ef migrations list --project src/Flex.Agent.Infrastructures --startup-project src/Flex.Agent
```

**Kỳ vọng**: danh sách migration trả về giống hệt danh sách trước khi tái cấu trúc (cùng tên, cùng thứ tự). Không có migration mới nào được tự sinh.

## 3. Chạy test hiện có (AC-003, FR-005)

```powershell
dotnet test Flex.Agent.sln
```

**Kỳ vọng**: toàn bộ test trong `Flex.Agent.Tests` (di chuyển từ `tests/Channels/*`) pass — bao gồm `InstagramOAuthServiceTests`, `InstagramPageServiceTests`, `InstagramPageServiceDisconnectTests`, `InstagramPermissionTests`, `InstagramSecurityTests`, `InstagramWebhookContractTests`, `InstagramWebhookHandlerTests`, `ChannelTokenEncryptionServiceTests`, `MessengerRegressionTests`.

## 4. Chạy service và kiểm tra endpoint (AC-004)

```powershell
dotnet run --project src/Flex.Agent
```

Gọi lại từng endpoint trong [contracts/existing-api-contracts.md](contracts/existing-api-contracts.md) (ví dụ `GET api/channels/instagram/connections`) và xác nhận route, status code, response shape giống baseline trước khi tái cấu trúc.

## 5. Dev tìm đúng vị trí đặt code mới (US-001)

Xác nhận thủ công (hoặc qua review với 1 kỹ sư khác — SC-003): với một thay đổi giả định (ví dụ "thêm entity `FacebookPageConnection`"), vị trí đặt code (project `Flex.Agent.Domain`) là rõ ràng, không cần hỏi lại.
