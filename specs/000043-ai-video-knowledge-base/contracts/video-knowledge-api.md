# Hợp đồng API: Video Knowledge (MVP)

**Service**: `flex-agent-service` | **Base**: `{agentApiBaseUrl}/api/video-knowledge` | **Xác thực**: JWT của `flex-auth-service`, trừ `callback` | **Quyền MVP**: chỉ quản trị viên (`ApplicationAuthorization.CanManage`) → sai quyền trả `403`
**Phản hồi**: dùng kiểu `Result` hiện có của service; lỗi nghiệp vụ trả `code` + `message` tiếng Việt, không lộ chi tiết nội bộ hay token. Toàn bộ nhóm endpoint chỉ tồn tại khi `VideoKnowledge:Enabled = true`.

## Kết nối Google Drive (FR-001, SEC-001..004)

| Method | Đường dẫn | Mô tả | Phản hồi |
| --- | --- | --- | --- |
| POST | `/connections/drive/connect` | Bắt đầu OAuth, lưu `state` một lần dùng ở kho `IDriveOAuthStateStore` (Redis) | `200 { authorizationUrl }` |
| GET | `/connections/drive/callback` | Google gọi lại (`AllowAnonymous`); đổi mã lấy token, mã hóa và lưu; chuyển hướng về frontend `/video-knowledge?connection=success\|error` | `302` |
| GET | `/connections/drive` | Trạng thái kết nối hiện tại | `200 { connected, accountEmail, status }` (không trả token) |
| DELETE | `/connections/drive` | Ngắt kết nối (thu hồi và xóa token) | `204` |

## Thư mục nguồn (FR-002)

| Method | Đường dẫn | Mô tả | Phản hồi |
| --- | --- | --- | --- |
| GET | `/drive/folders?parentId=` | Duyệt thư mục con của tài khoản đã kết nối | `200 [{ id, name }]` |
| POST | `/sources` | Chọn thư mục `{ driveFolderId }` | `201 { id, folderName, status }` |
| GET | `/sources` | Danh sách thư mục nguồn | `200 [...]` |
| DELETE | `/sources/{id}` | Gỡ thư mục khỏi đồng bộ (không xóa kết quả đã có) | `204` |
| POST | `/sources/{id}/sync` | Quét thư mục, thêm video mới ở `pending`, cập nhật metadata và `content_key` | `200 { discovered, updated, unchanged }` |

## Video và kết quả (FR-003..FR-011, FR-026, FR-028)

| Method | Đường dẫn | Mô tả | Phản hồi |
| --- | --- | --- | --- |
| GET | `/videos?keyword=&status=&page=&pageSize=` | Danh sách phân trang; `keyword` khớp tên, `summary`, `tags` (FR-019, kéo sớm vào MVP); `status` + `pageSize=1` dùng để đếm theo trạng thái (FR-009) | `200 { items, page, pageSize, total }` |
| GET | `/videos/{id}` | Chi tiết: metadata, trạng thái, `failureCode`, phân tích mới nhất (tóm tắt, `keyPoints`, `tags`, `topicGroup`, `difficulty`, `chapters[{ orderNo, startSeconds, endSeconds, title, summary, visualNotes }]`), cờ `contentChanged` | `200` / `404` |
| POST | `/videos/process` | Đưa vào hàng đợi `{ videoIds: [] }` (tối đa theo cấu hình `VideoKnowledge:MaxBatchSize`); video đang chạy bị bỏ qua | `202 { queued, skipped }` |
| POST | `/videos/{id}/reprocess` | Xử lý lại thủ công cho `failed`/`completed`/`access_denied` | `202` / `409` nếu đang chạy |

## Mã lỗi nghiệp vụ

`not_connected`, `connection_revoked`, `folder_not_found`, `video_not_found`, `video_in_progress`, `batch_too_large`, `access_denied`, `download_not_allowed`, `file_too_large`, `unsupported_language`, `provider_error`. Hai mã sau cùng và `unsupported_language` chỉ xuất hiện ở `failureCode` của video, không phải mã HTTP.

## Tương thích

Toàn bộ là contract mới; không đổi endpoint hiện hữu. Sự kiện realtime (SignalR) chưa thuộc MVP; giao diện dùng thăm dò (polling) khi có video đang xử lý.
