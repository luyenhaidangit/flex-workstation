# Lessons Learned

Checklist bài học kinh nghiệm từ các sự cố thật của Flex. Đọc trước khi chẩn đoán lỗi
mạng, DNS, ArgoCD hoặc k3s, và **thêm một mục mới sau mỗi sự cố đã tìm ra nguyên nhân**.

## Cách dùng

1. Khi gặp triệu chứng, đối chiếu cột "Triệu chứng" bên dưới trước khi đoán nguyên nhân.
2. Chạy lệnh trong "Cách xác minh" (chỉ đọc) để xác nhận, đừng sửa theo phỏng đoán.
3. Sau khi xử lý xong sự cố mới: thêm một mục theo mẫu ở cuối file, kèm bằng chứng.
4. Ưu tiên sửa bằng khai báo trong repo (Kustomize/YAML) thay vì lệnh `kubectl patch` chạy tay,
   để lần cài lại hoặc nâng cấp không mất cấu hình.

## Mục lục sự cố

| ID | Sự cố | Khu vực |
| --- | --- | --- |
| L1 | Pod không ra được GitHub vì search domain `bkcloud.vn` + `ndots:5` | DNS / ArgoCD |

---

## L1. Pod không tới được GitHub: search domain `bkcloud.vn` + `ndots:5`

**Ngày:** 2026-11-21. **Môi trường:** VPS BKCloud, k3s 1 node, ArgoCD v3.5.7.

**Triệu chứng**
- Application `flex` trên ArgoCD có Sync Status = **Unknown**, Health vẫn Healthy, kéo dài hàng giờ.
- `git ls-remote` trong `argocd-repo-server` treo rồi báo
  `Failed to connect to github.com port 443 after 134819 ms`.

**Nguyên nhân gốc**
- `/etc/resolv.conf` của VPS có `search bkcloud.vn`, và DNS `bkcloud.vn` có **wildcard**:
  mọi `*.bkcloud.vn` đều trả về `103.48.81.200`.
- Kubelet chép search domain vào pod; pod mặc định `ndots:5`. Tên ít hơn 5 dấu chấm như
  `github.com` bị ghép search domain trước, thành `github.com.bkcloud.vn` → IP sai, không phải GitHub.
- Hậu quả: bất kỳ pod nào gọi domain ngoài (có < 5 dấu chấm) đều có thể bị trả IP sai.

**Cách xác minh (chỉ đọc)**
```bash
# Pod thường không có nslookup/wget: dùng getent và git.
kubectl -n argocd exec deploy/argocd-repo-server -- getent hosts github.com      # IP sai: 103.48.81.200 github.com.bkcloud.vn
kubectl -n argocd exec deploy/argocd-repo-server -- getent hosts github.com.     # có dấu chấm cuối: IP GitHub thật
kubectl -n argocd exec deploy/argocd-repo-server -- cat /etc/resolv.conf         # thấy search ... bkcloud.vn và ndots:5
kubectl -n argocd get application flex -o jsonpath='{.status.conditions}'        # ComparisonError
```
Dấu hiệu chốt: hai lệnh `getent` (có và không có dấu chấm cuối) trả hai IP khác nhau.

**Cách sửa**
- Pod cần ra internet (ArgoCD repo-server): đặt `dnsConfig.options ndots=1`. Đã khai báo trong
  `flex-k8s/argocd/install/kustomization.yaml`; áp bằng `bash argocd/install-argocd.sh`.
- Gốc rễ ở host: bỏ `bkcloud.vn` khỏi search domain (netplan/cloud-init), rồi restart CoreDNS.
- Sau khi sửa: Hard Refresh trong ArgoCD. Unknown chuyển sang Synced/OutOfSync là đã thông.

**Bài học**
- Sync Unknown nghĩa là ArgoCD không so sánh được, không phải app hỏng. Xem `App Conditions` trước.
- Lỗi "không kết nối được" mà DNS vẫn có IP: kiểm tra IP có đúng không, đừng chỉ kiểm tra có resolve hay không.
- Thử tên có dấu chấm cuối (`github.com.`) để tách lỗi search domain khỏi lỗi egress.
- Đọc đúng `repoURL` trong `application.yaml` trước khi test (repo là `flex-k8s`, không phải `flex`).
- Nhà cung cấp VPS có thể cấu hình search domain/wildcard DNS: kiểm tra `resolv.conf` khi dựng server mới.

---

## Mẫu mục mới

```markdown
## L<n>. <Tiêu đề ngắn>

**Ngày / Môi trường:** ...

**Triệu chứng:** ...

**Nguyên nhân gốc:** ...

**Cách xác minh (chỉ đọc):** lệnh + dấu hiệu chốt

**Cách sửa:** (ưu tiên khai báo trong repo) ...

**Bài học:** ...
```
