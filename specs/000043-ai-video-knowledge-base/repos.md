# Phạm vi repo: AI Video Knowledge Base (000043)

Nguồn: `flex-repo-scope` (đối chiếu `scope` trong `workstation.json` và cấu trúc thực tế của từng repo đã clone ngày 2026-11-27).

| Repo | Nhóm | Lý do | Khu vực chạm |
| --- | --- | --- | --- |
| `flex-agent-service` | Edit | Backend .NET 9 của tính năng (người dùng chọn đặt trong repo này): API, use case, tích hợp Drive/Gemini, job nền | `src/Flex.Agent.Domain/Videos`, `src/Flex.Agent.Application/Videos`, `src/Flex.Agent.Infrastructures/Videos`, `src/Flex.Agent.Api`, `tests/` |
| `flex-database` | Edit | Chủ sở hữu migration của database riêng `videodb` (theo tiền lệ `agentdb`) | `videodb/`, `scripts/migrate-videodb.sh`, `MIGRATE_VIDEODB.cmd`, `README.md` |
| `flex-microfrontend` | Edit | Màn hình dashboard Angular: kết nối Drive, danh sách video, chi tiết tóm tắt | `src/app/features/video-knowledge`, `src/app/pages/pages-routing.module.ts`, menu sidebar |
| `flex-auth-service` | Skip | Chỉ dùng JWT hiện có, không đổi hợp đồng đăng nhập ở MVP |
| `flex-api-gateway` | Skip | Frontend gọi `flex-agent-service` trực tiếp qua `agentApiBaseUrl` (`environment.ts`), không qua gateway |
| `flex-environment` | Skip | Hạ tầng dev (PostgreSQL, Redis) đã có sẵn; tạo database `videodb` do script migration đảm nhiệm |
| `flex-exchange-service` | Skip | Không liên quan |
| `flex-k8s` | Skip | Chưa triển khai workload, không thuộc MVP |

## Giả định

- Người dùng đã chọn tường minh ba repo `Edit` ở bước lập plan nên không chờ xác nhận thêm.
- Quyền ghi (`push`) sẽ được cấp lại ở bước `/speckit-implement`; bước plan chỉ cần quyền đọc.
- Nếu về sau phát hiện cần route qua gateway hoặc đổi cấu hình hạ tầng thì chạy lại `flex-repo-scope` và cập nhật file này.
