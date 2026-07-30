# Kế hoạch triển khai: Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture

**Branch**: `000025-agent-service-restructure` | **Ngày**: 2026-07-30 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000025-agent-service-restructure/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

**Yêu cầu chính từ spec**: MVP-001–005, FR-001–007 — tách `flex-agent-service` (hiện là 1 project `FlexAgentService.csproj` phẳng) thành 3 project theo layer (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent`), theo đúng khuôn mẫu `flex-auth-service` (`Flex.Domain` / `Flex.Infrastructures` / `Flex.Auth`), không đổi API contract, schema DB, hay hành vi nghiệp vụ Instagram Business hiện có (US-001, US-002).

**Hướng tiếp cận kỹ thuật dự kiến**: Di chuyển từng file/thư mục hiện có sang project mới theo đúng vai trò layer (xem research.md), tạo `Flex.Agent.sln`, tạo project test mới `Flex.Agent.Tests` để chạy các test hiện có (hiện chưa có project test khả thi), build + test sau mỗi bước di chuyển nhỏ để giảm rủi ro.

**Kết quả sau research**: Đã hoàn thành — xem [research.md](research.md). Không có migration mới, không tạo abstraction mới ngoài việc tách layer, phải bổ sung project test vì hiện tại không có project test nào build được.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-agent-service`: tạo `Flex.Agent.sln` và 3 project chính (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent`), di chuyển toàn bộ code hiện có (`Channels/`, `Data/`, `Shared/`, `Program.cs`, `appsettings.*`) vào đúng project theo layer.
- Tạo project test `Flex.Agent.Tests`, di chuyển các file test hiện có từ `tests/Channels/*` vào đó và đảm bảo chạy được.
- Cập nhật namespace từ `FlexAgentService.*` sang `Flex.Agent.*` (Domain/Infrastructures) và `Flex.Agent` (API) tương ứng.

**Ngoài phạm vi kỹ thuật**:
- Không thêm channel mới (Facebook Messenger, Zalo...).
- Không thêm Dockerfile, Jenkinsfile, hay `docs/` vận hành mới (theo Clarifications Session 2026-07-30).
- Không tách project riêng theo từng channel.
- Không thay đổi API contract, schema DB, hay cơ chế mã hoá token.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET 9 / C# (`net9.0`), nullable + implicit usings enabled — giữ nguyên như hiện tại.

**Service/App liên quan**: `flex-agent-service` (repo con độc lập trong `flex-workstation`, khai báo trong `workstation.json`).

**Phụ thuộc chính**: `Microsoft.EntityFrameworkCore` 9.0.11, `Npgsql.EntityFrameworkCore.PostgreSQL` 9.0.3, `Microsoft.EntityFrameworkCore.Design` 9.0.11, `Microsoft.Extensions.Caching.Memory` 9.0.11 — di chuyển `PackageReference` sang đúng project theo layer (EF Core packages → `Flex.Agent.Infrastructures`; `AddControllers`/`AddEndpointsApiExplorer` là API host concern → `Flex.Agent`).

**Lưu trữ**: PostgreSQL qua EF Core — không đổi connection string, schema, hay migration.

**Kiểm thử**: Cần tạo mới `Flex.Agent.Tests` (xUnit — theo quy ước .NET phổ biến trong hệ Flex; xác nhận framework cụ thể khi implement bằng cách kiểm tra `using` trong các file test hiện có ở `tests/Channels/*` để giữ đúng test framework gốc nếu file đã tham chiếu sẵn, ví dụ `Xunit` hoặc `NUnit`).

**Nền tảng chạy**: ASP.NET Core Web API (Kestrel), không đổi (giống `flex-auth-service`).

**Đơn vị deploy**: Service `Flex.Agent` (API host) — build/deploy như một service .NET độc lập, không đổi cách deploy hiện có (ngoài phạm vi CI/CD/Dockerfile theo Clarifications).

**Loại project**: web-service (.NET Clean Architecture nhiều project, giống `flex-auth-service`).

**Mục tiêu hiệu năng**: Không đổi so với hiện tại — tái cấu trúc không nhằm cải thiện hiệu năng (NFR-001 chỉ yêu cầu build time không tăng đáng kể, đo bằng cảm nhận dev, không có benchmark chính thức).

**Ràng buộc**: Không đổi API contract (FR-004), không đổi schema DB (FR-007), `Flex.Agent.Domain` không phụ thuộc infrastructure/API (BR-001).

**Quy mô/Phạm vi**: 1 service, ~10 file nguồn hiện có (`Channels/`, `Data/`, `Shared/`) + 9 file test cần di chuyển; không có thay đổi quy mô dữ liệu.

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| I. Điều phối workspace, không triển khai sản phẩm | Pass (ngoại lệ áp dụng) | Pass | Yêu cầu người dùng nêu rõ phạm vi làm việc là repo con `flex-agent-service` (đối chiếu cấu trúc `flex-auth-service`) → khớp điều kiện ngoại lệ ở §5.I constitution: "Chỉ được sửa code trong sub-repo khi yêu cầu của người dùng nêu rõ repo con đó là phạm vi làm việc." Không tạo submodule/liên kết version giữa `flex-agent-service` và `flex-auth-service`. |
| II. Spec trước code | Pass | Pass | `spec.md` đã qua `$speckit-clarify`, checklist requirements Pass (16/16) trước khi vào `$speckit-plan`. |
| III. Tooling không phụ thuộc agent | Không áp dụng | Không áp dụng | Không thay đổi runtime config AI tooling. |
| IV. Bootstrap có thể tái lập | Không áp dụng | Không áp dụng | Không thay đổi `SYNC_WORKSPACE.cmd`/bootstrap script. |
| V. Thay đổi phẫu thuật và đơn giản | Pass | Pass | Chỉ di chuyển code hiện có vào đúng project theo layer, không thêm abstraction/tính năng mới ngoài việc tạo project test (cần thiết để FR-005 kiểm chứng được — xem Theo dõi độ phức tạp). |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Có cần migration/backfill không? → **Đã trả lời trong research.md**: Không, migration hiện có được copy nguyên trạng.
- **TQ-002**: Dùng flow/module hiện có hay tạo extension point mới? → **Đã trả lời**: Dùng lại flow DI hiện có, không tạo extension point mới.
- **TQ-003**: Contract hiện tại có cần giữ backward compatibility không? → **Đã trả lời**: Có, bắt buộc 100%.

## Thiết kế tổng quan

**Luồng chính**:
1. Tạo cấu trúc solution mới: `src/Flex.Agent.Domain/`, `src/Flex.Agent.Infrastructures/`, `src/Flex.Agent/`, và `tests/Flex.Agent.Tests/`, cùng `Flex.Agent.sln` ở root.
2. Di chuyển entity/enum (`ChannelType`, `MetaAccountConnection`, `InstagramPageConnection`) vào `Flex.Agent.Domain`.
3. Di chuyển `AppDbContext`, `Data/Migrations/*`, `ChannelTokenEncryptionService` vào `Flex.Agent.Infrastructures`; thiết lập `ProjectReference` tới `Flex.Agent.Domain`.
4. Di chuyển controllers, DI extension (`AddInstagramChannel`), services (`InstagramOAuthService`, `InstagramPageService`, `InstagramWebhookHandler`), DTOs, `Program.cs`, `appsettings.*.json` vào `Flex.Agent`; thiết lập `ProjectReference` tới `Flex.Agent.Infrastructures`.
5. Di chuyển 9 file test hiện có từ `tests/Channels/*` vào `Flex.Agent.Tests`, tạo `.csproj` test project tham chiếu `Flex.Agent`.
6. Build toàn bộ solution, sửa lỗi namespace/using phát sinh; chạy `dotnet ef migrations list` để xác nhận migration còn nguyên; chạy `dotnet test`; smoke test thủ công các endpoint theo `quickstart.md`.

**Component/module tham gia**:
- `Flex.Agent.Domain`: entity nghiệp vụ, enum — không phụ thuộc project khác.
- `Flex.Agent.Infrastructures`: EF Core persistence, migrations, mã hoá token — phụ thuộc `Flex.Agent.Domain`.
- `Flex.Agent` (API host): controllers, DI, entrypoint — phụ thuộc `Flex.Agent.Infrastructures` (transitively `Flex.Agent.Domain`).
- `Flex.Agent.Tests`: test project mới — phụ thuộc `Flex.Agent`.

**Điểm mở rộng/thay đổi chính**:
- Toàn bộ `namespace FlexAgentService.*` đổi thành `Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, hoặc `Flex.Agent` tương ứng theo research.md.
- `AssemblyName`/`RootNamespace` của project API đổi từ `FlexAgentService` → `Flex.Agent`.

**Luồng thay thế/lỗi chính**: Không áp dụng — không có luồng nghiệp vụ lỗi mới; rủi ro chính là lỗi build/reference khi di chuyển code (xem Phân tích tác động).

**Thay đổi boundary giữa service/module**: Không áp dụng — ranh giới thay đổi chỉ nội bộ trong `flex-agent-service`, không ảnh hưởng service khác.

**Idempotency/Concurrency**: Không áp dụng — đây là thay đổi cấu trúc mã nguồn tĩnh, không có runtime concurrency mới.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Tạo project `Flex.Agent.Domain` chứa entity/enum, không `ProjectReference` ra ngoài | `src/Flex.Agent.Domain/` | Không áp dụng | `ChannelType`, `MetaAccountConnection`, `InstagramPageConnection` | Build kiểm tra không có reference ngược từ Domain |
| US-001 / FR-002 | P1 | Đủ rõ | Tạo project `Flex.Agent.Infrastructures` chứa `AppDbContext`, migrations, `ChannelTokenEncryptionService` | `src/Flex.Agent.Infrastructures/` | Không áp dụng | `AppDbContext` (giữ nguyên schema) | `dotnet ef migrations list`; unit test `ChannelTokenEncryptionServiceTests` |
| US-001 / FR-003 | P1 | Đủ rõ | Tạo project API host `Flex.Agent` chứa controllers, DI, `Program.cs` | `src/Flex.Agent/` | Route hiện có giữ nguyên (xem contracts/) | Không áp dụng | Smoke test endpoint theo quickstart.md |
| US-002 / FR-004 | P1 | Đủ rõ | Di chuyển controller nguyên trạng, không đổi route/attribute | `src/Flex.Agent/Controllers/` | `api/channels/instagram/*`, `api/webhooks/instagram` (xem contracts/existing-api-contracts.md) | Không áp dụng | Manual/regression test theo AC-004 |
| US-002 / FR-005 | P1 | Đủ rõ | Tạo `Flex.Agent.Tests`, di chuyển 9 file test hiện có, đảm bảo build+run | `tests/Flex.Agent.Tests/` | Không áp dụng | Không áp dụng | `dotnet test Flex.Agent.sln` — toàn bộ pass |
| — / FR-006 | P2 | Đủ rõ | Tạo `Flex.Agent.sln` liệt kê cả 4 project (3 src + test) | `Flex.Agent.sln` | Không áp dụng | Không áp dụng | `dotnet build Flex.Agent.sln` thành công |
| — / FR-007 | P1 | Đủ rõ | Copy migration nguyên trạng, không sinh migration mới | `src/Flex.Agent.Infrastructures/Migrations/` (hoặc `Persistence/Migrations/`) | Không áp dụng | Toàn bộ bảng/cột/index hiện có | `dotnet ef migrations list` đối chiếu danh sách trước/sau |
| BR-001 | P1 | Đủ rõ | `Flex.Agent.Domain.csproj` không có `ProjectReference` nào | `src/Flex.Agent.Domain/Flex.Agent.Domain.csproj` | Không áp dụng | Không áp dụng | Review `.csproj`, build riêng project Domain |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không đổi schema; chỉ đổi assembly chứa migration | Rủi ro: EF Core không tìm thấy migration nếu quên cấu hình đúng project/namespace | `dotnet ef migrations list` phải khớp danh sách cũ (xem research.md TQ-001) |
| API/Contract | Không đổi route/payload | Không có breaking change nếu di chuyển đúng controller nguyên trạng | So khớp với `contracts/existing-api-contracts.md`, gọi thử từng endpoint |
| Permission/Security | Không đổi — không có thay đổi phân quyền người dùng cuối trong phạm vi này | Không áp dụng | Không áp dụng |
| Logging/Audit | Không áp dụng — spec §11 xác định không cần audit | Không áp dụng | Không áp dụng |
| UI/UX | Không áp dụng — không có UI trong phạm vi service này | Không áp dụng | Không áp dụng |
| Job/Worker/Integration | Webhook Instagram (Meta) là external integration hiện có, route giữ nguyên | Rủi ro nếu đổi route webhook sẽ làm Meta không gọi được | Xác nhận route `api/webhooks/instagram` không đổi trước khi coi refactor hoàn tất |

## API/Contract Detail

**Có thay đổi contract không**: Không.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `api/channels/instagram/*` (6 endpoint, xem contracts/) | API | Không đổi — chỉ di chuyển project chứa controller | Có | Frontend nội bộ gọi API kết nối kênh |
| `api/webhooks/instagram` (GET verify + POST event) | API | Không đổi | Có | Meta Platform (webhook đã đăng ký) |

## Permission Matrix

**Không áp dụng** — spec §10 xác định không có thay đổi phân quyền người dùng cuối trong phạm vi tái cấu trúc này.

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Migration**:
- Copy nguyên trạng `Data/Migrations/*` sang `Flex.Agent.Infrastructures`, không sửa nội dung Up/Down.

**Backfill/Cleanup**:
- Không áp dụng.

**Tương thích dữ liệu cũ**:
- Database hiện có không cần thay đổi; kết nối qua cùng connection string/schema.

**Rủi ro dữ liệu**:
- Rủi ro duy nhất là EF Core migration history table (`__EFMigrationsHistory`) không khớp nếu assembly name migration đổi theo cách ảnh hưởng tới `MigrationId`/`ModelSnapshot` — cần verify bằng `dotnet ef migrations list` trước khi merge (không phải rủi ro mất dữ liệu, mà là rủi ro build/tooling).

**Cách xác minh**:
- `dotnet ef migrations list --project src/Flex.Agent.Infrastructures --startup-project src/Flex.Agent` (xem quickstart.md bước 2).

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Tách đúng 3 project theo layer (`Flex.Agent.Domain`/`Flex.Agent.Infrastructures`/`Flex.Agent`) | Khớp Clarifications Session 2026-07-30 và khuôn mẫu `flex-auth-service` đã ổn định | Tách thêm project theo từng channel | Bị loại rõ ràng trong Clarifications — tăng phức tạp không cần thiết ở giai đoạn hiện tại |
| DEC-002 | Đổi namespace/project name sang `Flex.Agent.*` | Khớp Clarifications Session 2026-07-30, nhất quán toàn hệ Flex | Giữ tiền tố `FlexAgentService` | Bị loại rõ ràng trong Clarifications — ưu tiên nhất quán chuẩn đặt tên hơn giảm thiểu diff |
| DEC-003 | Tạo mới project `Flex.Agent.Tests` (chưa từng tồn tại) thay vì để test không chạy được | FR-005 yêu cầu test hiện có PHẢI pass — không thể verify nếu không có project test build được | Bỏ qua việc thiếu test project, chỉ di chuyển source | Sẽ khiến AC-003 không thể kiểm chứng, vi phạm Test Gate của constitution |
| DEC-004 | Copy migration nguyên trạng, không sinh migration mới | Tránh rủi ro breaking schema (FR-007) | Regenerate migration sau khi đổi namespace | Không cần thiết và tăng rủi ro drift schema không lý do |

## Chiến lược kiểm thử

**Unit test**:
- `ChannelTokenEncryptionServiceTests`, `InstagramOAuthServiceTests`, `InstagramPageServiceTests`, `InstagramPageServiceDisconnectTests` — di chuyển nguyên trạng vào `Flex.Agent.Tests`, xác nhận pass.

**Integration test**:
- `InstagramWebhookHandlerTests`, `InstagramWebhookContractTests` — xác nhận luồng webhook end-to-end không đổi sau khi di chuyển.

**Contract test**:
- Đối chiếu `contracts/existing-api-contracts.md` — gọi thử từng endpoint, so response/status code với baseline.

**Permission/security test**:
- `InstagramPermissionTests`, `InstagramSecurityTests` — di chuyển nguyên trạng, xác nhận pass (đảm bảo cơ chế mã hoá token và phân quyền hiện có không bị suy yếu — xem spec §10).

**E2E/manual test**:
- Chạy `dotnet run --project src/Flex.Agent` và gọi thủ công các endpoint theo quickstart.md bước 4.

**Regression test**:
- `MessengerRegressionTests` — di chuyển nguyên trạng, xác nhận enum `ChannelType.FacebookMessenger` không bị ảnh hưởng bởi việc tách project.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000025-agent-service-restructure/
├── plan.md              # File này (output của lệnh /speckit-plan)
├── research.md          # Output Phase 0
├── data-model.md         # Output Phase 1
├── quickstart.md         # Output Phase 1
├── contracts/            # Output Phase 1
│   └── existing-api-contracts.md
└── tasks.md              # Output Phase 2 (lệnh /speckit-tasks — chưa tạo)
```

### Source code (repository root của `flex-agent-service`)

```text
flex-agent-service/
├── Flex.Agent.sln
├── src/
│   ├── Flex.Agent.Domain/
│   │   ├── Flex.Agent.Domain.csproj
│   │   ├── ChannelType.cs
│   │   └── Channels/Instagram/
│   │       ├── MetaAccountConnection.cs
│   │       └── InstagramPageConnection.cs
│   ├── Flex.Agent.Infrastructures/
│   │   ├── Flex.Agent.Infrastructures.csproj
│   │   ├── Persistence/
│   │   │   ├── AppDbContext.cs
│   │   │   └── Migrations/           # di chuyển nguyên trạng từ Data/Migrations
│   │   └── Security/
│   │       └── ChannelTokenEncryptionService.cs
│   └── Flex.Agent/
│       ├── Flex.Agent.csproj
│       ├── Program.cs
│       ├── appsettings.json / appsettings.Development.json / appsettings.Example.json
│       └── Channels/Instagram/
│           ├── InstagramChannelController.cs
│           ├── InstagramWebhookController.cs
│           ├── InstagramOAuthService.cs
│           ├── InstagramPageService.cs
│           ├── InstagramWebhookHandler.cs
│           ├── DependencyInjection.cs
│           └── Dtos/
└── tests/
    └── Flex.Agent.Tests/
        ├── Flex.Agent.Tests.csproj    # MỚI — hiện chưa tồn tại project test nào build được
        └── Channels/
            ├── Facebook/MessengerRegressionTests.cs
            ├── Instagram/*.cs
            └── Shared/ChannelTokenEncryptionServiceTests.cs
```

**Quyết định cấu trúc**: Dùng layout `src/` + `tests/` giống `flex-auth-service` (`src/Flex.Auth`, `src/Flex.Domain`, `src/Flex.Infrastructures`), thêm `tests/Flex.Agent.Tests` vì auth-service hiện chưa có test project mẫu để tham chiếu trực tiếp — cấu trúc `tests/{ProjectName}.Tests` là quy ước .NET phổ biến, phù hợp `Flex.Agent.sln`.

## Rollout & Rollback

**Kế hoạch rollout**: Thực hiện trên nhánh `000025-agent-service-restructure`, merge sau khi build + test pass và smoke test thủ công theo quickstart.md hoàn tất. Không cần bật/tắt qua feature flag vì đây là thay đổi cấu trúc mã nguồn nội bộ, không có runtime behavior mới.

**Tương thích ngược**: Route/API/schema không đổi nên client hiện có (frontend, Meta webhook) không cần cập nhật gì.

**Feature flag/config**: Không áp dụng.

**Thực thi migration/backfill khi rollout**: Không áp dụng — không có migration mới.

**Rollback code/config**: Revert commit/PR tái cấu trúc trên Git — vì không có migration mới hay thay đổi dữ liệu, rollback code là đủ.

**Rollback dữ liệu/migration**: Không áp dụng — không có thay đổi dữ liệu.

**Điều kiện kích hoạt rollback**: Build/test fail sau merge, hoặc phát hiện endpoint Instagram trả lỗi/khác hành vi sau khi deploy — trong trường hợp đó, revert PR tái cấu trúc.

## Observability & Debug

**Log cần có**: Không đổi so với hiện tại — cấu trúc project không ảnh hưởng logging runtime hiện có của `Flex.Agent`.

**Dữ liệu không được log**: Token Instagram/Meta (OAuth access token), `TokenEncryption:Key` — giữ nguyên quy tắc hiện có, không log giá trị đã/chưa mã hoá.

**Metric cần theo dõi**: Không áp dụng — không có metric mới trong phạm vi tái cấu trúc.

**Trace/Correlation**: Không áp dụng — không có thay đổi observability trong phạm vi này.

**Cách kiểm tra sau release**: Build pipeline pass (nếu có), `dotnet test` pass, gọi thử endpoint theo quickstart.md.

**Tình huống debug chính**: Nếu build lỗi sau khi merge — kiểm tra `ProjectReference` giữa 3 project và namespace đã đổi đúng theo research.md chưa; nếu migration không tìm thấy — kiểm tra `--project`/`--startup-project` khi chạy `dotnet ef`.

## Theo dõi độ phức tạp

| Vi phạm | Vì sao cần | Phương án đơn giản hơn bị loại vì |
|---------|------------|-----------------------------------|
| Thêm project thứ 4 (`Flex.Agent.Tests`) ngoài 3 project chính đã thống nhất | FR-005 yêu cầu test hiện có PHẢI pass, nhưng hiện tại không tồn tại project test nào build được (research.md) | Không tạo test project sẽ khiến FR-005/AC-003 không thể kiểm chứng được, vi phạm Test Gate của constitution — đây không phải mở rộng scope mà là điều kiện tối thiểu để verify yêu cầu đã có trong spec |

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.md.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá (Không áp dụng).
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility (ở đây: xác nhận KHÔNG đổi).
- [x] Dữ liệu/migration/backfill/compatibility đã rõ (Không áp dụng, verify bằng `dotnet ef migrations list`).
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
