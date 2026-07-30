---
description: "Danh sách task triển khai: Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture"
---

# Tasks: Tái cấu trúc Flex Agent Service theo mô hình Clean Architecture

**Đầu vào**: Design documents từ `specs/000025-agent-service-restructure/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/existing-api-contracts.md`, `quickstart.md`

**Tests**: Test Gate bắt buộc. Rủi ro build/reference (plan.md §Phân tích tác động) được phủ bằng command validation task (build từng project, build toàn solution, chạy test suite di chuyển, smoke test endpoint) vì đây là tái cấu trúc thuần cấu trúc mã nguồn — không có logic nghiệp vụ mới cần unit test mới, chỉ cần xác nhận test/behavior hiện có không đổi.

**Tổ chức**: Toàn bộ path bên dưới tính từ root của repo con `flex-agent-service/` (không phải root `flex-workstation/`).

## Format: `[ID] [P?] [Story?] Description with path`

---

## Phase 1: Setup

**Mục đích**: Khởi tạo solution file rỗng làm khung cho các project sẽ thêm ở Phase 2.

- [ ] T001 Tạo file solution rỗng `Flex.Agent.sln` tại root `flex-agent-service/` bằng `dotnet new sln -n Flex.Agent`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Tạo khung 3 project theo layer với đúng `ProjectReference` (BR-001, BR-003) — điều kiện bắt buộc để cả US1 và US2 di chuyển code vào.

**CRITICAL**: Không bắt đầu di chuyển code (Phase 3/4) tới khi phase này hoàn tất.

- [ ] T002 Tạo project `Flex.Agent.Domain` (SDK `Microsoft.NET.Sdk`, `TargetFramework=net9.0`, `Nullable`/`ImplicitUsings=enable`, KHÔNG có `ProjectReference` nào) tại `src/Flex.Agent.Domain/Flex.Agent.Domain.csproj`
- [ ] T003 Tạo project `Flex.Agent.Infrastructures` (SDK `Microsoft.NET.Sdk`, `net9.0`) với `ProjectReference` tới `Flex.Agent.Domain` và `PackageReference`: `Microsoft.EntityFrameworkCore` 9.0.11, `Npgsql.EntityFrameworkCore.PostgreSQL` 9.0.3, `Microsoft.EntityFrameworkCore.Design` 9.0.11 tại `src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj` (phụ thuộc T002)
- [ ] T004 Tạo project API host `Flex.Agent` (SDK `Microsoft.NET.Sdk.Web`, `net9.0`, `AssemblyName=Flex.Agent`, `RootNamespace=Flex.Agent`) với `ProjectReference` tới `Flex.Agent.Infrastructures` và `PackageReference` `Microsoft.Extensions.Caching.Memory` 9.0.11 tại `src/Flex.Agent/Flex.Agent.csproj` (phụ thuộc T003)
- [ ] T005 Thêm 3 project (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent`) vào `Flex.Agent.sln` bằng `dotnet sln Flex.Agent.sln add src/Flex.Agent.Domain/Flex.Agent.Domain.csproj src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj src/Flex.Agent/Flex.Agent.csproj` (phụ thuộc T001, T002, T003, T004)

**Checkpoint**: Khung 3 project + solution đã sẵn sàng, có thể bắt đầu di chuyển code cho US1.

---

## Phase 3: User Story 1 - Dev tìm đúng vị trí đặt code mới (Priority: P1) MVP

**Goal**: Toàn bộ entity/enum nghiệp vụ nằm trong `Flex.Agent.Domain` (không phụ thuộc project khác), toàn bộ persistence/hạ tầng nằm trong `Flex.Agent.Infrastructures` — dev mở solution thấy ngay ranh giới layer.

**Independent Test**:

1. Chạy `dotnet build src/Flex.Agent.Domain/Flex.Agent.Domain.csproj` — build thành công, 0 lỗi.
2. Chạy `dotnet build src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj` — build thành công, 0 lỗi.
3. Mở `src/Flex.Agent.Domain/Flex.Agent.Domain.csproj`, xác nhận không có phần tử `<ProjectReference>` nào (BR-001).

### Implementation for User Story 1

- [ ] T006 [P] [US1] Di chuyển enum `ChannelType` từ `Channels/ChannelType.cs` sang `src/Flex.Agent.Domain/ChannelType.cs`, đổi namespace thành `Flex.Agent.Domain`
- [ ] T007 [P] [US1] Di chuyển entity `MetaAccountConnection` từ `Channels/Instagram/MetaAccountConnection.cs` sang `src/Flex.Agent.Domain/Channels/Instagram/MetaAccountConnection.cs`, đổi namespace thành `Flex.Agent.Domain.Channels.Instagram`
- [ ] T008 [P] [US1] Di chuyển entity `InstagramPageConnection` từ `Channels/Instagram/InstagramPageConnection.cs` sang `src/Flex.Agent.Domain/Channels/Instagram/InstagramPageConnection.cs`, đổi namespace thành `Flex.Agent.Domain.Channels.Instagram`
- [ ] T009 [US1] Di chuyển `AppDbContext` từ `Data/AppDbContext.cs` sang `src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs`, đổi namespace thành `Flex.Agent.Infrastructures.Persistence`, cập nhật `using` trỏ tới `Flex.Agent.Domain` và `Flex.Agent.Domain.Channels.Instagram` (phụ thuộc T006, T007, T008)
- [ ] T010 [US1] Di chuyển nguyên văn file SQL thủ công `Data/Migrations/AddInstagramTables.sql` sang `src/Flex.Agent.Infrastructures/Persistence/Migrations/AddInstagramTables.sql`; xác nhận `git diff --no-index Data/Migrations/AddInstagramTables.sql src/Flex.Agent.Infrastructures/Persistence/Migrations/AddInstagramTables.sql` trả về rỗng (FR-007, research.md TQ-001)
- [ ] T011 [P] [US1] Di chuyển `ChannelTokenEncryptionService` từ `Shared/ChannelTokenEncryptionService.cs` sang `src/Flex.Agent.Infrastructures/Security/ChannelTokenEncryptionService.cs`, đổi namespace thành `Flex.Agent.Infrastructures.Security`
- [ ] T012 [US1] Validation: chạy `dotnet build src/Flex.Agent.Domain/Flex.Agent.Domain.csproj`, xác nhận build thành công 0 lỗi (phụ thuộc T006, T007, T008)
- [ ] T013 [US1] Validation: chạy `dotnet build src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj`, xác nhận build thành công 0 lỗi (phụ thuộc T009, T010, T011)
- [ ] T014 [US1] Validation (BR-001): mở `src/Flex.Agent.Domain/Flex.Agent.Domain.csproj`, xác nhận không có phần tử `<ProjectReference>` nào (phụ thuộc T002)

**Definition of Done**:

- T006–T014 hoàn tất.
- Independent Test (build Domain, build Infrastructures, review `.csproj`) pass.
- Không có `ProjectReference` ngược từ `Flex.Agent.Domain`.

**Checkpoint**: User Story 1 hoàn chỉnh, có thể build/test độc lập trước khi bắt đầu US2.

---

## Phase 4: User Story 2 - Nghiệp vụ hiện có không bị gián đoạn (Priority: P1)

**Goal**: Toàn bộ API/OAuth/webhook Instagram Business hiện có hoạt động đúng như trước sau khi tái cấu trúc; toàn bộ test hiện có build và pass được (hiện tại chưa có project test khả thi — xem research.md).

**Independent Test**:

1. Chạy `dotnet build Flex.Agent.sln` — toàn bộ 4 project (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent`, `Flex.Agent.Tests`) build thành công.
2. Chạy `dotnet test Flex.Agent.sln` — toàn bộ 9 file test di chuyển từ `tests/Channels/*` pass.
3. Chạy `dotnet run --project src/Flex.Agent`, gọi lại từng endpoint trong `contracts/existing-api-contracts.md` (`api/channels/instagram/*`, `api/webhooks/instagram`), xác nhận route/status/response giống baseline trước khi tái cấu trúc.

### Implementation for User Story 2

- [ ] T015 [P] [US2] Di chuyển `InstagramChannelController` từ `Channels/Instagram/InstagramChannelController.cs` sang `src/Flex.Agent/Channels/Instagram/InstagramChannelController.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram`, cập nhật `using` trỏ tới `Flex.Agent.Domain.Channels.Instagram`/`Flex.Agent.Infrastructures.Persistence` (phụ thuộc T007, T008, T009)
- [ ] T016 [P] [US2] Di chuyển `InstagramWebhookController` từ `Channels/Instagram/InstagramWebhookController.cs` sang `src/Flex.Agent/Channels/Instagram/InstagramWebhookController.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram` (phụ thuộc T009)
- [ ] T017 [P] [US2] Di chuyển `InstagramOAuthService` từ `Channels/Instagram/InstagramOAuthService.cs` sang `src/Flex.Agent/Channels/Instagram/InstagramOAuthService.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram`, cập nhật `using` trỏ tới `Flex.Agent.Infrastructures.Security` (phụ thuộc T011)
- [ ] T018 [P] [US2] Di chuyển `InstagramPageService` từ `Channels/Instagram/InstagramPageService.cs` sang `src/Flex.Agent/Channels/Instagram/InstagramPageService.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram`, cập nhật `using` trỏ tới `Flex.Agent.Infrastructures.Persistence`/`Flex.Agent.Infrastructures.Security` (phụ thuộc T009, T011)
- [ ] T019 [P] [US2] Di chuyển `InstagramWebhookHandler` từ `Channels/Instagram/InstagramWebhookHandler.cs` sang `src/Flex.Agent/Channels/Instagram/InstagramWebhookHandler.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram`, cập nhật `using` trỏ tới `Flex.Agent.Infrastructures.Persistence` (phụ thuộc T009)
- [ ] T020 [P] [US2] Di chuyển `Dtos/ConnectDtos.cs` từ `Channels/Instagram/Dtos/ConnectDtos.cs` sang `src/Flex.Agent/Channels/Instagram/Dtos/ConnectDtos.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram.Dtos`
- [ ] T021 [US2] Di chuyển `DependencyInjection.cs` (`AddInstagramChannel`) từ `Channels/Instagram/DependencyInjection.cs` sang `src/Flex.Agent/Channels/Instagram/DependencyInjection.cs`, đổi namespace thành `Flex.Agent.Channels.Instagram`, cập nhật `using` trỏ tới `Flex.Agent.Infrastructures.Security.ChannelTokenEncryptionService` (phụ thuộc T011, T015–T020)
- [ ] T022 [US2] Di chuyển `Program.cs` từ root sang `src/Flex.Agent/Program.cs`, cập nhật `using` trỏ tới `Flex.Agent.Infrastructures.Persistence` (cho `AppDbContext`) và `Flex.Agent.Channels.Instagram` (cho `AddInstagramChannel`) (phụ thuộc T009, T021)
- [ ] T023 [P] [US2] Di chuyển `appsettings.Example.json` từ root sang `src/Flex.Agent/appsettings.Example.json`, nội dung giữ nguyên
- [ ] T024 [US2] Tạo project test `Flex.Agent.Tests` (SDK `Microsoft.NET.Sdk`, `net9.0`) với `ProjectReference` tới `Flex.Agent` và `PackageReference`: `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio` tại `tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj` (phụ thuộc T022)
- [ ] T025 [US2] Thêm `Flex.Agent.Tests` vào `Flex.Agent.sln` bằng `dotnet sln Flex.Agent.sln add tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj` (phụ thuộc T024)
- [ ] T026 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramOAuthServiceTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramOAuthServiceTests.cs`, cập nhật `using FlexAgentService.Channels.Instagram` → `using Flex.Agent.Channels.Instagram` (phụ thuộc T017, T025)
- [ ] T027 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramPageServiceTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramPageServiceTests.cs`, cập nhật `using` sang `Flex.Agent.Channels.Instagram`, `Flex.Agent.Channels.Instagram.Dtos`, và sửa `using FlexAgentService.Channels.Shared` (namespace sai lệch — xem research.md) thành `using Flex.Agent.Infrastructures.Security`, cùng `using Flex.Agent.Infrastructures.Persistence` (phụ thuộc T018, T025)
- [ ] T028 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramPageServiceDisconnectTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramPageServiceDisconnectTests.cs`, cập nhật `using` sang `Flex.Agent.Channels.Instagram`, `Flex.Agent.Infrastructures.Persistence` (phụ thuộc T018, T025)
- [ ] T029 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramPermissionTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramPermissionTests.cs` (phụ thuộc T025)
- [ ] T030 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramSecurityTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramSecurityTests.cs`, cập nhật `using FlexAgentService.Channels.Instagram.Dtos` → `using Flex.Agent.Channels.Instagram.Dtos` (phụ thuộc T020, T025)
- [ ] T031 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramWebhookContractTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramWebhookContractTests.cs` (phụ thuộc T025)
- [ ] T032 [P] [US2] Di chuyển `tests/Channels/Instagram/InstagramWebhookHandlerTests.cs` sang `tests/Flex.Agent.Tests/Channels/Instagram/InstagramWebhookHandlerTests.cs`, cập nhật `using` sang `Flex.Agent.Channels.Instagram`, `Flex.Agent.Infrastructures.Persistence` (phụ thuộc T019, T025)
- [ ] T033 [P] [US2] Di chuyển `tests/Channels/Shared/ChannelTokenEncryptionServiceTests.cs` sang `tests/Flex.Agent.Tests/Security/ChannelTokenEncryptionServiceTests.cs`, sửa `using FlexAgentService.Channels.Shared` (namespace sai lệch — xem research.md) thành `using Flex.Agent.Infrastructures.Security` (phụ thuộc T011, T025)
- [ ] T034 [P] [US2] Di chuyển `tests/Channels/Facebook/MessengerRegressionTests.cs` sang `tests/Flex.Agent.Tests/Channels/Facebook/MessengerRegressionTests.cs`, cập nhật `using FlexAgentService.Channels` → `using Flex.Agent.Domain` (phụ thuộc T006, T025)
- [ ] T035 [US2] Validation: chạy `dotnet build Flex.Agent.sln`, xác nhận cả 4 project build thành công 0 lỗi (phụ thuộc T015–T034)
- [ ] T036 [US2] Validation (FR-005, AC-003): chạy `dotnet test Flex.Agent.sln`, xác nhận toàn bộ test trong `Flex.Agent.Tests` pass (phụ thuộc T035)
- [ ] T037 [US2] Validation (FR-004, AC-004): chạy `dotnet run --project src/Flex.Agent`, gọi thủ công 8 endpoint trong `contracts/existing-api-contracts.md`, xác nhận route/status/response khớp baseline trước khi tái cấu trúc (phụ thuộc T035)
- [ ] T038 [US2] Xoá cấu trúc phẳng cũ: `FlexAgentService.csproj`, `Program.cs` (root), `Channels/`, `Data/`, `Shared/`, `tests/Channels/` sau khi T036 và T037 pass (phụ thuộc T036, T037)

**Definition of Done**:

- T015–T038 hoàn tất.
- `dotnet build Flex.Agent.sln` và `dotnet test Flex.Agent.sln` đều pass.
- Endpoint Instagram hoạt động đúng như baseline.
- Không còn file/project thuộc cấu trúc phẳng cũ.

**Checkpoint**: US1 và US2 đều hoàn chỉnh và có thể validate độc lập; solution đã hoàn toàn chuyển sang cấu trúc Clean Architecture mới.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Xác nhận không còn sót namespace cũ, và chạy toàn bộ quickstart như validation cuối trước khi coi feature hoàn tất.

- [ ] T039 [P] Grep toàn bộ `src/` và `tests/` để xác nhận không còn `FlexAgentService` sót lại — chạy `grep -rn "FlexAgentService" src/ tests/`, kết quả PHẢI rỗng
- [ ] T040 Chạy toàn bộ 5 bước trong `specs/000025-agent-service-restructure/quickstart.md` end-to-end như validation cuối cùng
- [ ] T041 Manual review (SC-003): nhờ 1 kỹ sư backend khác (ngoài người thực hiện tái cấu trúc) xác nhận có thể xác định đúng project (`Flex.Agent.Domain`/`Flex.Agent.Infrastructures`/`Flex.Agent`) cho một thay đổi giả định (ví dụ "thêm entity mới") mà không cần hỏi lại

---

## Validation Commands

- Build toàn solution: `dotnet build Flex.Agent.sln`
- Build riêng Domain: `dotnet build src/Flex.Agent.Domain/Flex.Agent.Domain.csproj`
- Build riêng Infrastructures: `dotnet build src/Flex.Agent.Infrastructures/Flex.Agent.Infrastructures.csproj`
- Run tests: `dotnet test Flex.Agent.sln`
- Run API contract check: chạy `dotnet run --project src/Flex.Agent` rồi gọi endpoint theo `contracts/existing-api-contracts.md`
- Run migration/smoke check: `git diff --no-index Data/Migrations/AddInstagramTables.sql src/Flex.Agent.Infrastructures/Persistence/Migrations/AddInstagramTables.sql` (phải rỗng)

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US1 | T006, T007, T008, T009, T010, T011, T012, T013, T014 |
| US2 | T015, T016, T017, T018, T019, T020, T021, T022, T023, T024, T025, T026, T027, T028, T029, T030, T031, T032, T033, T034, T035, T036, T037, T038 |
| FR-001 | T006, T012 |
| FR-002 | T009, T010, T011, T013 |
| FR-003 | T004, T021, T022 |
| FR-004 | T015, T016, T037 |
| FR-005 | T024, T025, T026–T034, T036 |
| FR-006 | T001, T005, T025 |
| FR-007 | T010 |
| BR-001 | T002, T014 |
| BR-002 | T037 |
| BR-003 | T002, T003, T004 |
| AC-001 | T005, Independent Test US1 |
| AC-002 | T006, T007, T008 |
| AC-003 | T036 |
| AC-004 | T037 |
| NFR-002 | T036, T037 |
| NFR-003 | T041 |
| SC-001 | T036 |
| SC-002 | T037 |
| SC-003 | T041 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, bắt đầu ngay.
- **Foundational (Phase 2)**: Phụ thuộc Setup (T001), CHẶN mọi user story.
- **User Story 1 (Phase 3)**: Phụ thuộc Foundational (T002–T005) hoàn tất.
- **User Story 2 (Phase 4)**: Phụ thuộc Foundational (T004) và User Story 1 hoàn tất (cần `Flex.Agent.Domain`/`Flex.Agent.Infrastructures` đã có entity/DbContext/encryption service thật để API tham chiếu).
- **Polish (Final Phase)**: Phụ thuộc User Story 2 hoàn tất (T038).

### User Story Dependencies

- **User Story 1 (P1)**: Bắt đầu sau Foundational, không phụ thuộc story khác.
- **User Story 2 (P1)**: Phụ thuộc User Story 1 hoàn tất — API host cần entity (T007, T008), `AppDbContext` (T009), và `ChannelTokenEncryptionService` (T011) đã tồn tại trong `Flex.Agent.Domain`/`Flex.Agent.Infrastructures` trước khi di chuyển controller/service sang `Flex.Agent`.

### Trong từng user story

- US1: T006–T008 (entity/enum) có thể chạy song song → T009 (DbContext, phụ thuộc T006–T008) → T010 (migration SQL, độc lập nội dung nhưng đặt sau để nhất quán thứ tự) → T011 (encryption, song song với T009/T010) → T012/T013 (build validation) → T014 (manual review).
- US2: T015–T020 (controllers/services/DTO, khác file) chạy song song → T021 (DI, phụ thuộc T011 và T015–T020) → T022 (Program.cs, phụ thuộc T009, T021) → T023 (appsettings, song song) → T024 (tạo test project, phụ thuộc T022) → T025 (thêm vào sln) → T026–T034 (di chuyển từng file test, khác file, chạy song song, phụ thuộc T025 và source tương ứng) → T035 (build solution) → T036/T037 (test + smoke, song song sau T035) → T038 (dọn dẹp cấu trúc cũ).

### Parallel Opportunities

- T006, T007, T008, T011 (US1) — khác file, chạy song song.
- T015, T016, T017, T018, T019, T020, T023 (US2) — khác file, chạy song song.
- T026–T034 (di chuyển 9 file test, US2) — khác file, chạy song song.
- T039 (Polish) có thể chạy song song với việc chuẩn bị T040/T041.

---

## Parallel Example: User Story 1

```bash
# Di chuyển entity/enum song song (khác file, không phụ thuộc nhau):
Task: "Di chuyển enum ChannelType sang src/Flex.Agent.Domain/ChannelType.cs"
Task: "Di chuyển entity MetaAccountConnection sang src/Flex.Agent.Domain/Channels/Instagram/MetaAccountConnection.cs"
Task: "Di chuyển entity InstagramPageConnection sang src/Flex.Agent.Domain/Channels/Instagram/InstagramPageConnection.cs"
Task: "Di chuyển ChannelTokenEncryptionService sang src/Flex.Agent.Infrastructures/Security/ChannelTokenEncryptionService.cs"
```

## Parallel Example: User Story 2 (di chuyển test)

```bash
Task: "Di chuyển InstagramOAuthServiceTests.cs sang tests/Flex.Agent.Tests/Channels/Instagram/"
Task: "Di chuyển InstagramPageServiceTests.cs sang tests/Flex.Agent.Tests/Channels/Instagram/, sửa namespace ChannelTokenEncryptionService"
Task: "Di chuyển InstagramPermissionTests.cs sang tests/Flex.Agent.Tests/Channels/Instagram/"
Task: "Di chuyển MessengerRegressionTests.cs sang tests/Flex.Agent.Tests/Channels/Facebook/"
```

---

## Implementation Strategy

### MVP First (chỉ User Story 1)

1. Complete Phase 1: Setup (T001).
2. Complete Phase 2: Foundational (T002–T005, CRITICAL).
3. Complete Phase 3: User Story 1 (T006–T014).
4. **STOP and VALIDATE**: build riêng `Flex.Agent.Domain` và `Flex.Agent.Infrastructures`, xác nhận không có `ProjectReference` ngược.
5. Nếu cần dừng ở đây để review, solution đã có cấu trúc layer rõ ràng dù API host chưa hoạt động được (chưa có Program.cs/controller).

### Incremental Delivery

1. Setup + Foundational → khung 3 project sẵn sàng.
2. User Story 1 → Domain + Infrastructures build độc lập, review cấu trúc.
3. User Story 2 → API host + test project hoàn chỉnh, build/test/smoke test toàn bộ pass, xoá cấu trúc cũ.
4. Polish → xác nhận sạch namespace cũ, chạy quickstart, review chéo với dev khác.

### Parallel Team Strategy

Vì US2 phụ thuộc trực tiếp vào output của US1 (entity, DbContext, encryption service phải tồn tại trước khi controller/service tham chiếu tới), không nên chia 2 dev làm song song 2 story độc lập; nên triển khai tuần tự US1 → US2. Trong nội bộ mỗi story, các task `[P]` (di chuyển file khác nhau) có thể chia cho nhiều dev làm song song.

---

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder.
- [x] Không còn `TXXX`, `Phase N` generic hoặc phase user story không tồn tại trong `spec.md`.
- [x] Toàn bộ task đánh số tuần tự từ `T001` đến `T041`.
- [x] Mỗi task có path cụ thể hoặc command cụ thể.
- [x] Task sửa file có sẵn đã nêu rõ class/file/namespace cần đổi.
- [x] Task phụ thuộc task khác đã ghi rõ dependency task ID.
- [x] Mỗi user story có Independent Test cụ thể.
- [x] Mỗi user story có Definition of Done cụ thể.
- [x] Mỗi `US`/`FR` P1 và requirement ảnh hưởng code/data/API có task tương ứng.
- [x] Traceability Matrix đã map source quan trọng sang task ID thực tế.
- [x] Migration (file SQL), contract, rollout đã có task khi `plan.md` đánh dấu liên quan (T010, T037, T038).
- [x] Task `[P]` không sửa cùng file và không phụ thuộc nhau.
- [x] Không có story song song cùng sửa file tổng hợp mà chưa có cách xử lý conflict (`DependencyInjection.cs`, `Program.cs` được xử lý tuần tự sau các di chuyển song song).

## Ghi chú

- `[P]` = khác file, không phụ thuộc nhau.
- `[US1]`/`[US2]` map tới user story trong `spec.md`.
- Không có automated unit test mới cần viết trước-fail-sau-pass (TDD) vì đây là di chuyển code hiện có, không phải logic mới — Test Gate được đáp ứng bằng việc đảm bảo test suite hiện có (9 file) tiếp tục pass sau khi di chuyển (T036) và smoke test endpoint thủ công (T037).
- Commit sau mỗi task hoặc nhóm task nhỏ (ví dụ: sau T006–T008, sau T009–T011) để dễ revert nếu build lỗi.
- Dừng ở checkpoint cuối Phase 3 để review cấu trúc Domain/Infrastructures trước khi tiếp tục Phase 4 nếu muốn.
