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

## 3. Khả năng đọc hiểu và Debug (Explicit Variables & Early Return)

- **Tránh lạm dụng toán tử 3 ngôi (`?:`) để trả về HTTP Result**: Toán tử 3 ngôi khiến code khó đặt breakpoint khi debug và khó theo dõi dòng chảy (control flow).
- **Khuyên dùng Guard Clause & biến tường minh**: Tách biệt luồng thất bại (`if (!success) return ...`) trước, sau đó lưu kết quả thành công vào biến riêng trước khi trả về.

```csharp
var success = service.TryStart(market, out var session);
if (!success)
{
    var failureResult = Result.Failure(session, message: $"Phiên giao dịch cho thị trường '{market}' đang hoạt động hoặc không thể khởi động.", errorCode: ResponseCode.Conflict);
    return Conflict(failureResult);
}

var successResult = Result.Success(session);
return Ok(successResult);
```

---

## 4. Phản hồi thành công nhất quán (`Ok(successResult)`)

- **Ưu tiên trả về `Ok(successResult)` cho các API POST/Action**: Tránh lạm dụng các helper method sinh Header không cần thiết như `CreatedAtAction(...)` (trừ khi có yêu cầu kiến trúc đặc thù).
- **Tối ưu cho Frontend**: Trả về `200 OK` chứa đối tượng envelope `Result.Success(...)` giúp Client dễ dàng đọc trực tiếp `data` trong JSON body, giữ cho mã nguồn Controller đơn giản, nhất quán 100% với toàn bộ các API POST khác trong hệ thống.


