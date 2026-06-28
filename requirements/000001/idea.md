# Idea: 000001

## Source

- Input: `flex-workstation/requirements/000001/intent.md`
- Output: `flex-workstation/requirements/000001/idea.md`

## Captured Intent

- **Outcome**: Xây dựng tính năng thông báo realtime trong app — mỗi khi có phiên đăng nhập mới trên tài khoản, user đang mở web app sẽ nhận được thông báo ngay lập tức trong giao diện.
- **User**: Chính chủ tài khoản, đang tích cực sử dụng web app.
- **Why now**: Cải thiện bảo mật và UX cho auth service; hiện chưa có tính năng thông báo đăng nhập realtime.
- **Success**: User thấy thông báo in-app tức thì mỗi khi bất kỳ phiên đăng nhập mới nào được tạo trên tài khoản của họ (trigger: mọi lần đăng nhập, không chỉ thiết bị lạ).
- **Constraint**: Backend .NET. Chỉ cần hoạt động khi user đang mở app (không cần background/offline push). Kênh realtime chưa chốt — SSE được khuyến nghị cho .NET vì thông báo một chiều và triển khai đơn giản hơn WebSocket.
- **Out of scope**: Push notification khi app đóng/background, admin dashboard giám sát toàn hệ thống, event streaming sang service khác (message broker), phân biệt thiết bị lạ/IP mới.

## Notes

- SSE (Server-Sent Events) phù hợp hơn WebSocket cho trường hợp này vì luồng thông báo chỉ một chiều (server → client); ASP.NET Core hỗ trợ SSE native.
- Nếu sau này cần mở rộng sang background notification hoặc mobile, cần thêm FCM/APNs hoặc SignalR.
- Cần xác định thêm: thông báo hiển thị dưới dạng gì (toast, banner, badge) và có lưu lịch sử thông báo không.
