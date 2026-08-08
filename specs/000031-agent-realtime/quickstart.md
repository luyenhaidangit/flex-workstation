# Quickstart: Demo realtime Agent Service

## Prerequisites

- .NET 9 SDK.
- Node.js/npm phù hợp với `flex-microfrontend`.
- Có thể chạy `flex-agent-service` và `flex-microfrontend` đồng thời.
- Có token/auth local hợp lệ nếu môi trường bật authorization.

## 1. Chạy Agent Service

Từ `flex-agent-service`:

```powershell
dotnet run --project src/Flex.Agent.Api
```

Ghi lại HTTP/HTTPS URL được in trong console. Cấu hình URL đó vào environment Angular theo implementation task; không commit secret hoặc connection string.

## 2. Chạy frontend

Từ `flex-microfrontend`:

```powershell
npm start
```

Mở route `/agents/create` sau khi đăng nhập theo môi trường local. Khung chat realtime nằm ở panel “Xem trước và kiểm tra” bên phải của màn tạo Agent.

## 3. Kiểm chứng FE → BE

1. Xác nhận giao diện hiển thị trạng thái `Connected`.
2. Gửi marker message, ví dụ `realtime-smoke-20260808`.
3. Xác nhận FE nhận event `messageReceived` và hiển thị message trong chat.
4. Xem console/log của Agent Service, xác nhận event nhận message và thời điểm nhận.

## 4. Kiểm chứng BE → FE

Gọi endpoint test bằng Postman hoặc curl với authorization của môi trường:

```powershell
curl -X POST "http://localhost:7001/api/v1/realtime-demo/notify" `
  -H "Authorization: Bearer <token>" `
  -H "Content-Type: application/json" `
  -d '{"message":"Thông báo test từ BE"}'
```

Kỳ vọng: response `200`, `connectedClients` lớn hơn `0`, và browser hiển thị `alert` đúng nội dung.

## 5. Kiểm chứng không có client

1. Đóng hoặc disconnect FE.
2. Gọi lại endpoint.
3. Kỳ vọng: response thành công với `connectedClients: 0`; Agent Service không lỗi.

## 6. Kiểm tra chất lượng

Backend:

```powershell
dotnet test tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj
```

Frontend:

```powershell
npm test -- --watch=false --browsers=ChromeHeadless
```

Smoke test được xem là đạt khi cả hai chiều và các trạng thái không có client đều đúng.
