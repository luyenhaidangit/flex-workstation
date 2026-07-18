# Quickstart — Bảng điện thị trường demo

## Điều kiện trước

- .NET 9 SDK và Node.js >= 20.
- Hai repository `flex-exchange-service` và `flex-microfrontend` đã có dependency.
- Cổng `5266` và cổng Angular dev `4200` chưa bị tiến trình khác sử dụng.

## Chạy Exchange

Từ `flex-exchange-service/`:

```powershell
dotnet run --project src/Flex.Exchange.Api/Flex.Exchange.Api.csproj --launch-profile http
```

Kiểm tra `http://localhost:5266/health` trả về thành công.

## Chạy frontend

Từ `flex-microfrontend/`:

```powershell
npm ci
npm start
```

Mở `http://localhost:4200/exchange`. Environment development phải trỏ `exchangeApiBaseUrl` tới `http://localhost:5266`.

## Smoke flow

1. Mở bảng điện và xác nhận mã `FXS`, trạng thái loading và các vùng bid/ask/trade tape.
2. Chọn broker demo A, `Buy`, giá `20000`, khối lượng `100`, gửi lệnh.
3. Xác nhận kết quả accepted/rejected hiển thị theo response; nếu accepted, order id xuất hiện trong vùng lệnh hiện tại.
4. Chọn broker demo B, `Sell`, cùng giá và khối lượng; gửi lệnh.
5. Trong tối đa 5 giây, xác nhận latest price, trade tape và order book phản ánh trade.
6. Đặt một lệnh chỉ có thanh khoản chờ, chọn đúng broker và hủy; xác nhận trạng thái cancelled và nút hủy bị vô hiệu hóa.
7. Tải lại trang; xác nhận dữ liệu được đọc lại từ Exchange, không tạo thêm lệnh và không mất trade đã xác nhận.
8. Tạm dừng Exchange hoặc chặn mạng; xác nhận bảng điện đánh dấu stale/hiển thị lỗi nhưng giữ snapshot cuối, sau đó tự phục hồi khi Exchange hoạt động lại.

## Kiểm thử tự động dự kiến

Từ `flex-microfrontend/`:

```powershell
npm test -- --watch=false --browsers=ChromeHeadless
npm run build -- --configuration development
```

Từ `flex-exchange-service/`:

```powershell
dotnet build Flex.Exchange.sln --configuration Release --no-restore
dotnet test Flex.Exchange.sln --configuration Release --no-restore
```

Các contract/API test MVP 02 phải tiếp tục pass; MVP 3 bổ sung test cho consumer mapping nếu contract bị chạm.

## Rollback demo

Dừng frontend hoặc quay về build frontend trước MVP 3. Không cần rollback database hoặc Exchange state; nếu có order demo đang chờ, hủy qua API trước khi dừng môi trường.
