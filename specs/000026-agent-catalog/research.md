# Nghiên cứu kỹ thuật: Danh mục Agent (CRUD cơ bản)

**Feature**: `000026-agent-catalog` | **Ngày**: 2026-08-01

Tài liệu này tổng hợp các quyết định kỹ thuật và phương án thiết kế cho tính năng Danh mục Agent v1 (`000026-agent-catalog`).

---

## Quyết định kỹ thuật

### DEC-001: Kiến trúc Backend & Dịch vụ API

- **Quyết định**: Triển khai REST API cho Agent Catalog trong sub-repo `flex-agent-service` (dự án `Flex.Agent.Api` / `Flex.Agent.Domain` / `Flex.Agent.Infrastructures`) chạy trên .NET 9.0 Web API.
- **Lý do**: `flex-agent-service` đã được thành lập làm dịch vụ quản lý Agent trong kiến trúc hệ thống (`specs/000025-agent-service-restructure`), sử dụng C# / .NET 9.0 với Clean Architecture.
- **Phương án đã loại**: Tạo dịch vụ mới độc lập. Loại vì gây trùng lặp hạ tầng và phá vỡ cấu trúc microservices hiện có.

### DEC-002: Cơ sở dữ liệu & Quản lý lưu trữ

- **Quyết định**: Lưu trữ thực thể Agent trong cơ sở dữ liệu PostgreSQL (`flexdb`), bảng `agents`, thông qua Entity Framework Core 9 (`Npgsql.EntityFrameworkCore.PostgreSQL`).
- **Lý do**: PostgreSQL làm Control Plane DB thống nhất cho Agent metadata (phù hợp với định hướng trong `specs/000008-agent-platform-mvp/data-model.md`). Thực thể Agent v1 lưu thông tin cơ bản: `id` (UUID PK), `name` (varchar 100, UNIQUE, case-sensitive), `description` (varchar 500, nullable), `status` (varchar 20, default 'active'), `created_at` (timestamptz), `updated_at` (timestamptz).
- **Phương án đã loại**:
  - MySQL database-per-tenant cho v1: Loại vì v1 chưa hỗ trợ multi-tenant, giữ đơn giản trên PostgreSQL Control Plane trước.
  - In-memory store: Loại vì không đáp ứng yêu cầu lưu trữ bền vững.

### DEC-003: Xác thực & Phân quyền (Authentication & Authorization)

- **Quyết định**: Yêu cầu JWT Authentication header (`Authorization: Bearer <token>`) trên tất cả các endpoint CRUD Agent Catalog trong `Flex.Agent.Api`. JWT token do `flex-auth-service` phát hành và được xác thực qua JWT Middleware trong ASP.NET Core.
- **Lý do**: Đáp ứng trực tiếp Yêu cầu chức năng `FR-007` và Bảo mật `SEC-003` (quản trị viên bắt buộc đăng nhập thành công trước khi truy cập hoặc thao tác CRUD).
- **Phương án đã loại**: Session-based auth hoặc bypass auth ở v1. Loại vì vi phạm trực tiếp AC và SEC-003.

### DEC-004: So khớp trùng tên Agent (Unique Name & Case-Sensitivity)

- **Quyết định**: Kiểm tra duy nhất tên Agent bằng UNIQUE constraint trong PostgreSQL (với collation C / binary hoặc so sánh trực tiếp `=`), so sánh có phân biệt chữ hoa / chữ thường theo quy tắc BR-001 ("Agent A" và "agent a" được coi là 2 tên khác nhau).
- **Lý do**: Phù hợp chính xác với BR-001 và làm rõ trong phần Clarifications của spec.md.
- **Phương án đã loại**: Case-insensitive unique constraint (LOWER(name)). Loại vì vi phạm BR-001.

### DEC-005: Giao diện người dùng (Frontend Microfrontend)

- **Quyết định**: Triển khai module Danh mục Agent (Agent Catalog Feature Module) trong sub-repo `flex-microfrontend` (Angular framework), bao gồm:
  - `AgentListComponent`: Màn hình danh sách agent & trạng thái rỗng / xác nhận xóa modal.
  - `AgentDetailComponent` / `AgentFormModal`: Form tạo mới & sửa agent với validation client (tên required, length limits).
  - `AgentService`: Angular HTTP client service gọi REST API `flex-agent-service`.
- **Lý do**: `flex-microfrontend` là nơi quản lý giao diện quản trị hiện có.
- **Phương án đã loại**: Server-rendered HTML (MVC/Razor). Loại vì giao diện toàn bộ hệ thống Flex dùng Angular Single Page App.

---

## Đánh giá rủi ro & Tương thích tương lai

| Quyết định | Rủi ro | Giải pháp giảm thiểu |
|------------|--------|----------------------|
| Khai báo bảng `agents` trong PostgreSQL `flexdb` | Khi nâng cấp lên `specs/000008-agent-platform-mvp` (multi-tenant với MySQL), schema có thể cần mở rộng. | Khai báo `id` kiểu UUID v4 và giữ tên trường chuẩn (`id`, `name`, `description`, `status`, `created_at`, `updated_at`) để dễ dàng map hoặc migrate sang runtime control plane. |
