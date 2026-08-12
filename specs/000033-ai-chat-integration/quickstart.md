# Hướng dẫn xác minh — Tích hợp chat AI tại màn Agent

## Mục tiêu

Xác minh người dùng đã đăng nhập gửi câu hỏi tại `/agents/create` và nhận phản hồi thực tế từ AI Agent đang cấu hình; không còn gửi tin nhắn trực tiếp đến người dùng khác.

## Điều kiện trước khi kiểm thử

1. `flex-agent-service`, API Gateway và `flex-microfrontend` chạy với cấu hình môi trường phù hợp.
2. AI provider đã được cấu hình và sẵn sàng; kiểm tra health/log vận hành theo môi trường, không đưa endpoint hoặc secret vào source.
3. Có tài khoản hợp lệ để đăng nhập FE.
4. Gateway đã có route `/api/v1/ai/**` đến Agent Service.

## Kịch bản xác minh

### 1. Luồng thành công

1. Đăng nhập và mở `/agents/create`.
2. Nhập tên, vai trò và chỉ dẫn có thể nhận biết được cho Agent.
3. Kiểm tra khung “Xem trước và kiểm tra” thể hiện người gửi là tài khoản hiện tại, không còn dropdown “Người nhận”.
4. Gửi câu hỏi văn bản hợp lệ.
5. Xác nhận câu hỏi xuất hiện ngay, có trạng thái đang chờ và không thể gửi tiếp trong lúc chờ.
6. Xác nhận câu trả lời xuất hiện với nhãn Agent trong thời gian `Ai:Ollama:TimeoutSeconds` đã cấu hình; gửi câu hỏi tiếp theo và kiểm tra thứ tự hội thoại.

### 2. Agent chưa sẵn sàng hoặc timeout

1. Làm Agent Service/provider không sẵn sàng hoặc dùng cấu hình kiểm thử gây timeout.
2. Gửi câu hỏi hợp lệ.
3. Xác nhận không có tin nhắn Agent giả lập; UI báo lỗi dễ hiểu, giữ lịch sử trước đó và cho phép thử lại.

### 3. Dữ liệu không hợp lệ và quyền

1. Thử gửi input rỗng hoặc chỉ khoảng trắng: nút gửi bị vô hiệu hóa hoặc UI nhắc nhập nội dung, không có request hợp lệ được gửi.
2. Gọi endpoint không có JWT: xác nhận `401`.
3. Dùng tài khoản không đủ quyền (khi policy được cấu hình): xác nhận `403` và UI không hiển thị nội dung phản hồi.

### 4. Regression direct chat

1. Mở wizard và gửi câu hỏi.
2. Xác nhận FE không gọi SignalR method `SendMessage` và không đọc event `message.created` cho khung preview.
3. Xác nhận các luồng direct-message khác của ứng dụng không bị thay đổi.

## Kiểm tra quan sát sau deploy

- Kiểm tra metric số request preview, tỷ lệ 2xx/4xx/5xx/timeout và latency p95.
- Kiểm tra log có `traceId`, user/tenant identifier được che/định danh phù hợp, Agent id nếu đã có; không có nội dung câu hỏi, instructions, response, token hoặc header Authorization.
- Khi tỷ lệ lỗi hoặc timeout vượt ngưỡng vận hành đã thống nhất, tắt route/feature theo kế hoạch rollout hoặc rollback deployment.
