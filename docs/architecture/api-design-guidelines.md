# Quy chuẩn Thiết kế RESTful API (API Design Guidelines)

Tài liệu này định nghĩa các quy tắc thiết kế RESTful API áp dụng cho các microservice trong hệ thống Flex Workstation.

---

## 1. Tham số bắt buộc tường minh (Explicit Parameters)

- Các tham số định danh tài nguyên, phân vùng hoặc ngữ cảnh nghiệp vụ (`market`, `symbol`, `brokerId`, `accountId`...) **phải do Client truyền tường minh**.
- **Cấm tự động lấy fallback ngầm định từ file cấu hình (config) hoặc hardcode** tại Controller khi Client gửi thiếu tham số.
- Khi tham số bắt buộc bị thiếu hoặc rỗng ➔ Controller trả về ngay HTTP 400 (`BadRequest`) kèm thông báo lỗi rõ ràng:

```csharp
if (string.IsNullOrWhiteSpace(market))
{
    return BadRequest(Result.Failure("Mã thị trường (market) là bắt buộc.", errorCode: ResponseCode.BadRequest));
}
```

---

## 2. Đồng bộ chuẩn Response Envelope (`Result.Success` / `Result.Failure`)

- Đối với các service sử dụng bọc phản hồi (Response Envelope), **không sử dụng `NoContent()` (HTTP 204)** vì mã HTTP 204 loại bỏ hoàn toàn Response Body, làm vỡ giao thức bọc JSON (`Result`) phía Client.
- Khi không có dữ liệu hoặc tài nguyên chưa được khởi tạo:
  - Trả về **`200 OK`** kèm `Result.Success(null)` nếu dữ liệu rỗng là phản hồi hợp lệ.
  - Hoặc trả về **`404 Not Found`** kèm `Result.Failure(...)` nếu coi việc thiếu tài nguyên là không tìm thấy.

---

## 3. Định tuyến chuẩn cho `201 CreatedAtAction`

- Khi tạo mới tài nguyên và trả về `201 CreatedAtAction(...)`, bắt buộc truyền route values object khớp với tham số của Action đích (ví dụ `new { market }`) để Header `Location` sinh đúng URL query string:

```csharp
return service.TryStart(market, out var session)
    ? CreatedAtAction(nameof(Get), new { market }, Result.Success(session))
    : Conflict(Result.Failure(session, errorCode: ResponseCode.Conflict));
```
