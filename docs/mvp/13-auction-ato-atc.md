# MVP 13 — Đấu giá mở/đóng phiên (ATO/ATC)

## Mục tiêu

Mô phỏng đúng cơ chế xác định giá tham chiếu đầu và cuối ngày qua đấu giá tập trung thay vì khớp liên tục ngay từ đầu phiên.

## Phạm vi

- Giai đoạn pre-open: nhận lệnh vào sổ nhưng chưa khớp.
- ATO: sau pre-open, tìm giá tối đa hoá khối lượng khớp rồi thực hiện khớp tập trung; lệnh dư chuyển sang continuous.
- ATC: đóng continuous, gom lệnh còn lại vào đấu giá cuối, xác nhận giá đóng cửa.
- Giá tham chiếu ngày hôm sau lấy từ giá đóng cửa ATC.

## Quy tắc đấu giá

- Tìm giá khớp sao cho khối lượng khớp được tối đa; nếu có nhiều mức giá đồng điều, ưu tiên gần giá tham chiếu nhất.
- Lệnh market vào ATO/ATC được ưu tiên khớp trước lệnh limit.
- Lệnh chưa khớp sau ATO tự động vào continuous; lệnh chưa khớp sau ATC bị huỷ theo cấu hình phiên.

## Kịch bản demo

Đặt nhiều lệnh mua/bán với các mức giá khác nhau trong pre-open; quan sát giá ATO được tính và khối lượng khớp tối đa; xác nhận lệnh dư chuyển đúng vào continuous.

## Điều kiện hoàn thành

- Giá ATO xác định đúng theo thuật toán; không khớp nào diễn ra trong pre-open.
- Giá đóng cửa ATC được lưu và dùng làm tham chiếu ngày sau.
- Chưa có ATO/ATC riêng cho lô lẻ, lệnh điều kiện hay phiên thoả thuận.
