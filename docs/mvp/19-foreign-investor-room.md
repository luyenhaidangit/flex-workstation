# MVP 19 — Nhà đầu tư nước ngoài và room ngoại

## Mục tiêu

Mô phỏng cơ chế kiểm soát tỷ lệ sở hữu nước ngoài trên từng mã chứng khoán theo quy định thị trường chứng khoán Việt Nam.

## Phạm vi

- Mỗi mã có giới hạn room ngoại cấu hình được (mặc định 49% tổng cổ phần niêm yết).
- Exchange theo dõi tổng cổ phần nước ngoài đang nắm giữ per symbol theo thời gian thực.
- Lệnh mua của foreign bị reject nếu room còn lại không đủ khối lượng yêu cầu.
- API công khai hiển thị room ngoại còn lại theo từng mã.
- Khi foreign bán, room được giải phóng tương ứng.

## Quy tắc

- Tài khoản được đánh dấu domestic hoặc foreign tại thời điểm đăng ký; không thay đổi trong phiên.
- Kiểm tra room diễn ra tại Exchange trước khi khớp, không phải tại Broker.
- Room ngoại còn lại cập nhật ngay sau mỗi giao dịch khớp thành công.

## Kịch bản demo

Cấu hình room ngoại FXS = 49%; nhà đầu tư nước ngoài mua dần đến cận room; một lệnh mua cuối vượt room còn lại bị reject với lý do ForeignRoomExceeded; sau khi foreign bán, room mở lại và lệnh tiếp theo được chấp nhận.

## Điều kiện hoàn thành

- Tổng sở hữu foreign không bao giờ vượt giới hạn đã cấu hình.
- Room được cập nhật atomic cùng với khớp lệnh; không có race condition.
- Chưa có room theo nhóm ngành, room riêng cho tổ chức hay quy trình xin nới room.
