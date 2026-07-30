# Data Model: Tái cấu trúc Flex Agent Service

**Input**: [spec.md](spec.md) §9 (Không áp dụng — không có entity nghiệp vụ mới) · [research.md](research.md)

Đây là tái cấu trúc mã nguồn thuần tuý; không có entity, quan hệ, hay migration mới. Nội dung dưới đây mô tả các entity **hiện có** và project đích chúng được di chuyển tới, để phục vụ traceability khi sinh task.

## Entity hiện có (di chuyển nguyên trạng, không đổi field/kiểu/ràng buộc)

### `MetaAccountConnection`
- **Project nguồn**: `FlexAgentService.Channels.Instagram` (`Channels/Instagram/MetaAccountConnection.cs`)
- **Project đích**: `Flex.Agent.Domain`
- **Bảng**: `meta_account_connections` (không đổi tên bảng/cột/index)
- **Quan hệ**: 1-nhiều với `InstagramPageConnection` qua `PageConnections` (cascade delete) — giữ nguyên.

### `InstagramPageConnection`
- **Project nguồn**: `FlexAgentService.Channels.Instagram` (`Channels/Instagram/InstagramPageConnection.cs`)
- **Project đích**: `Flex.Agent.Domain`
- **Bảng**: `instagram_page_connections` (không đổi tên bảng/cột/index, bao gồm UNIQUE constraint `FacebookPageId` theo BR-005 gốc)

### `ChannelType` (enum)
- **Project nguồn**: `FlexAgentService.Channels` (`Channels/ChannelType.cs`)
- **Project đích**: `Flex.Agent.Domain`

## Persistence

### `AppDbContext`
- **Project nguồn**: `FlexAgentService.Data` (`Data/AppDbContext.cs`)
- **Project đích**: `Flex.Agent.Infrastructures`
- **Migrations**: `Data/Migrations/AddInstagramTables.sql` — đây là file SQL thủ công (không phải EF Core code-first migration, không có `ModelSnapshot`), di chuyển nguyên văn sang `Flex.Agent.Infrastructures/Persistence/Migrations/` (xem research.md TQ-001).

## Migration/backfill

**Không áp dụng** — không có thay đổi schema. Chỉ cần xác nhận nội dung `AddInstagramTables.sql` không đổi sau khi di chuyển (diff rỗng) và `AppDbContext.OnModelCreating` tiếp tục map đúng lên schema đã tạo bằng file SQL đó (xem [quickstart.md](quickstart.md)).
