# Hợp đồng kết nối: PostgreSQL trên K8s (000044)

Hợp đồng giữa PostgreSQL và các service Flex sẽ kết nối tới. Không chứa giá trị mật khẩu.

## Điểm kết nối

| Mục | Giá trị |
|-----|---------|
| Tên dịch vụ trong cụm | `postgres` (cùng namespace mặc định; từ namespace khác dùng `postgres.<namespace>.svc.cluster.local`) |
| Cổng | `5432` |
| Loại Service | `ClusterIP` — không có NodePort, không có đường vào từ Internet |
| Điều kiện cho pod client | Gắn nhãn `postgres-access: "true"`; pod không có nhãn bị chặn bởi NetworkPolicy |
| Truy cập của người vận hành | `kubectl port-forward` tới Service `postgres`; không mở cổng ra ngoài |

## Database và tài khoản

| Database | Tài khoản sở hữu | Key mật khẩu trong Secret `postgres-secret` | Service dự kiến dùng |
|----------|------------------|---------------------------------------------|----------------------|
| `flex_exchange_hnx` | `hnx` | `HNX_DB_PASSWORD` | Dịch vụ sàn HNX |
| `aspnetidentity` | `aspnetidentity` | `AUTH_DB_PASSWORD` | `flex-auth-service` |
| `agentdb` | `agentdb` | `AGENT_DB_PASSWORD` | `flex-agent-service` |
| `postgres` (hệ thống) | `postgres` | `POSTGRES_PASSWORD` | Chỉ người vận hành |

## Quy tắc

- Mỗi tài khoản service chỉ kết nối được database của mình; kết nối database khác bị từ chối.
- Database bàn giao ở trạng thái trống; service hoặc feature khác chịu trách nhiệm đưa schema vào.
- Nguồn gốc mật khẩu là OpenBao secret `postgres`; cụm chỉ giữ bản sao trong Secret `postgres-secret`, tạo bằng `set-secret.sh`.
- Thêm service mới: thêm database, role và key Secret mới vào script bootstrap và hợp đồng này, không dùng chung tài khoản.

## Tương thích

Hợp đồng mới hoàn toàn, chưa có consumer trong cụm; không phá hợp đồng nào đang chạy. Đổi tên database, role hay key Secret sau này là thay đổi phá vỡ với service đã kết nối và phải cập nhật hợp đồng này trước.
