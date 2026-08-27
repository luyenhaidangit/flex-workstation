# Quickstart kiểm chứng: Meta channel connections

Tài liệu này dành cho implementation/reviewer sau khi `$speckit-tasks` và `$speckit-implement` hoàn tất. Không áp dụng migration hoặc gọi Meta production trong bước plan.

## 1. Chuẩn bị

1. Bootstrap workspace và bảo đảm các repo độc lập có branch feature tương ứng.
2. Cấu hình secret bằng environment/secret manager theo `appsettings.Example.json`; không ghi App Secret, encryption key thật hoặc token vào file/git.
3. Dùng Meta test app/test user và HTTPS callback ở staging. Xác nhận App ID, redirect URI, API version và permissions đã được Meta cho phép.
4. Cấu hình frontend `environment.agentApiBaseUrl` trỏ tới `flex-agent-service`.

## 2. Kiểm tra database trước khi deploy

Từ `flex-database/agentdb`:

```text
liquibase --changelog-file=changelog/db.changelog-master.xml validate
liquibase --changelog-file=changelog/db.changelog-master.xml update-sql
```

Review generated SQL:

- chỉ có changeset release mới;
- không sửa changeset đã chạy;
- không có `DROP TABLE`, broad delete hoặc SQL copy ngoài ownership;
- preflight/schema check cho `meta_account_connections` và `instagram_page_connections` rõ ràng;
- `facebook_page_connections` và indexes/unique invariant được tạo đúng.

Chỉ chạy `liquibase update` khi target database đã được xác nhận và có authorization vận hành rõ ràng. Sau đó kiểm tra `liquibase status --verbose`/history và `information_schema`.

## 3. Build và test backend

Từ `flex-agent-service`:

```text
dotnet build Flex.Agent.sln
dotnet test Flex.Agent.sln
dotnet run --project src/Flex.Agent.Api/Flex.Agent.Api.csproj
```

Phải xác nhận regression tests Instagram/Facebook hiện hữu vẫn pass, đặc biệt OAuth/page/security/webhook contract tests; feature này không thêm messaging behavior.

## 4. Build và test frontend

Từ `flex-microfrontend`:

```text
npm install
ng test --watch=false
ng build
```

Xác nhận `AgentEditorWizardComponent` test không còn giả định chỉ có Instagram; test mới phải bao phủ Facebook card, callback query, discovery selection, complete, connected state và disconnect.

## 5. Smoke flow Instagram

1. Mở `/agents/{agentId}/edit`, tới bước publish và chọn Instagram.
2. Gọi connect; xác nhận user không có configure scope bị chặn.
3. Hoàn tất Meta OAuth bằng test user có Page liên kết Instagram Professional account.
4. Callback quay lại editor; result chỉ hiển thị metadata candidate, không có token/state raw.
5. Chọn một candidate và complete; refresh trang, xác nhận status `active` và đúng agent.
6. Lặp complete/callback hoặc chọn resource đã bị agent khác claim; xác nhận không duplicate và nhận `CONNECTION_CONFLICT` rõ ràng.
7. Disconnect; refresh xác nhận không dùng connection nữa; disconnect lần hai không tạo lỗi nghiệp vụ mới.

## 6. Smoke flow Facebook

1. Chọn Facebook trong publish step.
2. Hoàn tất Meta OAuth bằng test user quản lý ít nhất một Page.
3. Callback/result hiển thị managed Pages hợp lệ/không hợp lệ.
4. Chọn một Page, complete, refresh và xác nhận `facebook_page_connections` có đúng `agent_id`/resource/status.
5. Thử callback state hết hạn, thiếu permission, cross-agent session và duplicate Page; tất cả phải bị từ chối không tạo active connection.
6. Disconnect và lặp disconnect; xác nhận status/credential cleanup idempotent.

## 7. Kiểm tra observability/security

- Log có `traceId`, `agentId`, channel, outcome/failureCode, duration; không có code/state/token/secret.
- Metric callback/complete error và p95 latency nằm trong ngưỡng đã thống nhất.
- Audit có actor, action, resource/connection id, result/reason; không có credential.
- Kiểm tra các connection hoàn tất trước đó không bị thay đổi sau failed callback/complete.

## 8. Giới hạn MVP cần ghi nhận

- `IMemoryCache` chỉ phù hợp khi topology hiện tại bảo đảm callback/result đi qua cùng instance hoặc có cơ chế affinity. Trước khi scale nhiều replica phải thay `IIntegrationSessionStore` bằng distributed implementation và kiểm thử lại.
- Meta permissions/API version/app review là điều kiện bên ngoài code; staging smoke test là bắt buộc trước production.
