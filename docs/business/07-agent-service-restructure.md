# Nghiệp vụ MVP 07 — Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture

## Mục đích và phạm vi

Mã nguồn dịch vụ `flex-agent-service` vốn được tổ chức dạng project đơn phẳng (`FlexAgentService.csproj`), gây khó khăn cho đội ngũ kỹ sư backend khi mở rộng thêm các kênh giao tiếp mới (như Instagram Business, Facebook Messenger, Zalo...) và không đồng bộ với quy chuẩn Clean Architecture của hệ thống Flex. MVP này thực hiện tái cấu trúc mã nguồn C# thành 3 tầng dự án rõ ràng (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent.Api`), đảm bảo giữ nguyên 100% hành vi nghiệp vụ, route API, cơ chế bảo mật mã hoá token và schema dữ liệu hiện có.

Tham chiếu đặc tả kỹ thuật: [specs/000025-agent-service-restructure/spec.md](../../specs/000025-agent-service-restructure/spec.md).

## Bối cảnh nghiệp vụ

Trong hệ sinh thái FlexSim / Flex, `flex-agent-service` đóng vai trò là đầu mối điều phối giao tiếp giữa các AI Agent và các kênh nhắn tin bên ngoài (social channels). Việc chuẩn hoá cấu trúc dự án theo mô hình Clean Architecture giúp phân định ranh giới trách nhiệm:

```text
[Kênh bên ngoài: Meta/Instagram] 
         │
         ▼
[Tầng API Host (Flex.Agent.Api)] ── Controller & Route
         │
         ▼
[Tầng Hạ tầng (Flex.Agent.Infrastructures)] ── Persistence, Encrypt Token, Migration
         │
         ▼
[Tầng Domain (Flex.Agent.Domain)] ── Thống nhất Thực thể & Enum Nghiệp vụ
```

## Vai trò trong thị trường thực tế

```text
[Đội ngũ Backend Engineers] ──► [Phát triển & Bảo trì Agent Service] ──► [Hệ sinh thái AI Agent Flex]
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Kỹ sư Backend Flex | Phát triển, mở rộng kênh giao tiếp và bảo trì service | Trực tiếp sử dụng cấu trúc Clean Architecture mới để định vị đúng nơi đặt code |
| AI Agent Service | Điều phối tin nhắn, OAuth và quản lý kết nối kênh | Hoạt động ổn định, giữ nguyên toàn bộ hợp đồng API hiện tại |

## Luồng nghiệp vụ đầu-cuối

1. **Định vị mã nguồn (In-scope)**: Khi kỹ sư cần thêm thực thể hoặc quy tắc nghiệp vụ mới, tìm trực tiếp vào `Flex.Agent.Domain`.
2. **Quản lý hạ tầng & Persistence (In-scope)**: Các cấu hình cơ sở dữ liệu EF Core, script migration và mã hoá token nằm tại `Flex.Agent.Infrastructures`.
3. **Tiếp nhận & Xử lý request API (In-scope)**: Tầng `Flex.Agent.Api` đóng vai trò API host tiếp nhận request OAuth, webhook và phản hồi cho frontend.
4. **Vận hành & Kết nối kênh (In-scope)**: Các luồng OAuth Instagram, Webhook tin nhắn DM tiếp tục vận hành chính xác như baseline ban đầu.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Domain Layer (`Flex.Agent.Domain`) | Chứa enum `ChannelType`, entity `MetaAccountConnection`, `InstagramPageConnection` |
| Infrastructure Layer (`Flex.Agent.Infrastructures`) | Chứa `AppDbContext`, SQL migration `AddInstagramTables.sql`, dịch vụ mã hóa AES `ChannelTokenEncryptionService` |
| API Host Layer (`Flex.Agent.Api`) | Chứa controllers, đăng ký DI service, endpoint OAuth & webhook Instagram |

## Quy tắc nghiệp vụ

- **Tách biệt tầng Domain (BR-001)**: Tầng Domain (`Flex.Agent.Domain`) độc lập hoàn toàn, không phụ thuộc hạ tầng hay API host.
- **Bảo toàn hành vi hiện có (BR-002)**: Toàn bộ quy tắc xử lý tin nhắn, cửa sổ 24h, mã hoá token OAuth được giữ nguyên nguyên trạng.
- **Quy ước đặt tên chuẩn (BR-003)**: Sử dụng tiền tố `Flex.Agent.*` và hậu tố `.Api` cho project API Host ([Flex.Agent.Api](file:///c:/Workspace/Project/flex-workstation/flex-agent-service/src/Flex.Agent.Api/Flex.Agent.Api.csproj)).

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Kỹ sư mở solution | Thấy rõ 3 tầng `Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent.Api` và project test `Flex.Agent.Tests` |
| Gọi API Instagram OAuth/Webhook | Đạt 100% tương thích ngược, không có breaking change |
| Chạy Test Suite | 100% test case pass |

## Ngoài phạm vi

- Thêm kênh nhắn tin mới (Facebook Messenger, Zalo...).
- Thay đổi cấu trúc cơ sở dữ liệu hoặc cơ chế mã hoá.
- Thêm Dockerfile, Jenkinsfile hoặc tài liệu vận hành hạ tầng.

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](specs/000025-agent-service-restructure/spec.md): Chi tiết user stories, functional requirements và test gate.
- [Checklist Dịch vụ Mới](docs/checklists/new-service-checklist.md): Quy ước cấu trúc solution và đặt tên project C#.
