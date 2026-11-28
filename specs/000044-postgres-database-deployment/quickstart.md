# Quickstart kiểm chứng: PostgreSQL trên K8s (000044)

Hướng dẫn kiểm chứng sau khi implement. Mọi lệnh thay đổi cụm (`apply`, `exec` ghi dữ liệu, `delete pod`) chỉ chạy khi người vận hành cho phép và đã xác định đúng cụm của server mới. Không ghi mật khẩu vào lệnh hay log.

## Điều kiện

- Server mới có k3s chạy, `kubectl` trỏ đúng cụm; OpenBao đã mở khóa.
- Đã thêm secret `postgres` vào `flex-environment/mounts/openbao/secrets.list`, chạy job `infra/openbao-sync`, điền giá trị thật ở OpenBao.
- Đã tạo Secret `postgres-secret` bằng `bash set-secret.sh postgres-secret POSTGRES_PASSWORD HNX_DB_PASSWORD AUTH_DB_PASSWORD AGENT_DB_PASSWORD` (giá trị nhập qua prompt).

## Kiểm tra tĩnh (không đụng cụm)

```bash
kubectl apply --dry-run=client -R -f manifests/postgres/
grep -rn "latest" manifests/postgres/        # kỳ vọng: không có kết quả
bash -n scripts/postgres-bootstrap.sh
```

## Triển khai và kiểm tra

```bash
bash restart.sh postgres
kubectl rollout status deployment/postgres
kubectl get pods -l app=postgres            # kỳ vọng: đúng 1 pod Ready
bash scripts/postgres-bootstrap.sh
```

| Kịch bản | Cách kiểm tra | Kết quả mong đợi | Liên quan |
|----------|---------------|------------------|-----------|
| Có đủ database | `\l` qua `kubectl exec` | Có `flex_exchange_hnx`, `aspnetidentity`, `agentdb` | AC-001 |
| Role vào đúng database | Kết nối từng role vào database của mình (mật khẩu từ Secret) | Thành công | AC-002 |
| Role bị chặn chéo | Role `hnx` thử vào `agentdb` | Bị từ chối | AC-003 |
| Chạy lại bootstrap | Chạy `scripts/postgres-bootstrap.sh` lần hai | Không lỗi, không tạo trùng, dữ liệu không đổi | FR-010 |
| Thiếu mật khẩu | Thử bootstrap với Secret thiếu một key (môi trường thử) | Script dừng, nêu rõ key thiếu | AC-007 |
| Mật khẩu cũ | Thử đăng nhập bằng mật khẩu từng có trong cấu hình cũ | Bị từ chối | AC-005 |
| Cách ly mạng | Pod thử không nhãn kết nối `postgres:5432`; pod có nhãn kết nối | Pod không nhãn bị chặn; pod có nhãn được | FR-008 |
| Không lộ ra Internet | Quét cổng 5432 của server từ máy ngoài | Không mở | AC-006 |
| Bền vững | Tạo bảng thử trong database thử, `kubectl delete pod -l app=postgres`, chờ Ready | Pod tự lên, dữ liệu thử còn | AC-004 |
| Một bản chạy | Đếm pod `postgres` | Đúng 1 | SC-003 |
| Sức khỏe | Dừng tiến trình có chủ đích, theo dõi `kubectl get pods` | Trạng thái không khỏe trong 1 phút | AC-008, AC-009 |
| Tài nguyên | `kubectl top pod -l app=postgres`; `free -m` trên server | Dưới 1 GiB RAM; các workload khác vẫn chạy | NFR-001 |

## Rollback

```bash
kubectl rollout undo deployment/postgres     # quay về cấu hình trước
```

Không xóa PVC `postgres-data` khi chưa có xác nhận của người vận hành.
