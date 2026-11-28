# Phạm vi repo: Triển khai database PostgreSQL (000044)

Nguồn: `flex-repo-scope` (đối chiếu `scope` trong `workstation.json` và nội dung thực tế các repo đã clone, đọc ngày 2026-11-28). Chế độ local: chỉ đọc, chưa chỉnh sửa repo con nào.

| Repo | Nhóm | Lý do | Khu vực chạm |
| --- | --- | --- | --- |
| `flex-k8s` | Edit | Nơi đặt manifest Kubernetes và script vận hành của cụm k3s một node | `manifests/postgres/`, `scripts/postgres-bootstrap.sh`, `README.md` |
| `flex-environment` | Edit | Khai báo secret `postgres` trong OpenBao theo quy trình sẵn có; ghi chú thiết lập server | `mounts/openbao/secrets.list`, `SETUP_SERVER.md` |
| `flex-database` | Read | Chỉ để ghi nhận hiện trạng: v1 không áp schema; `hnx` và `agentdb` có Liquibase PostgreSQL, `aspnetidentity` là SQL kiểu Oracle | Không sửa |
| `flex-auth-service` | Skip | Đổi chuỗi kết nối sang PostgreSQL thuộc feature khác (`000009`) |
| `flex-agent-service` | Skip | Đổi chuỗi kết nối thuộc repo service |
| `flex-api-gateway` | Skip | Không dùng database này |
| `flex-microfrontend` | Skip | Không liên quan |
| `flex-exchange-service` | Skip | Không liên quan |

## Giả định

- Người dùng đã chốt: server mới, triển khai trong Kubernetes, một bản PostgreSQL, không sao lưu, không áp dữ liệu hay schema cũ.
- `flex-environment/temp/` (cấu hình PostgreSQL cũ) chỉ đọc làm tiền lệ, không sửa và không mang mật khẩu mặc định sang.
- Workstation chỉ chứa spec/plan và `docs/architecture/system-map.md`; không chứa manifest hay script vận hành (Nguyên tắc I).
- Quyền ghi vào repo con sẽ được xác nhận ở `/speckit-implement`, kèm tên branch riêng cho từng repo.
