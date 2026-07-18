# MVP 18 — Quỹ đầu tư mô phỏng

## Mục tiêu

Thêm participant loại quỹ đầu tư với danh mục, NAV và quy trình mua/bán chứng chỉ quỹ riêng biệt với giao dịch cổ phiếu thông thường.

## Actor và dữ liệu

- Một quỹ mô phỏng FXFund thuộc một CTCK quản lý quỹ; có danh mục gồm nhiều mã CK.
- NAV tính cuối ngày = (tổng giá trị thị trường danh mục + tiền mặt) / số chứng chỉ lưu hành.
- Nhà đầu tư mua/bán chứng chỉ quỹ theo NAV, không qua order book Exchange.
- Quỹ tự đặt/huỷ lệnh CK trên Exchange qua broker để điều chỉnh danh mục.

## Luồng NAV và giao dịch chứng chỉ

1. Cuối ngày: tính NAV từ giá đóng cửa ATC của từng mã trong danh mục.
2. Nhà đầu tư đặt lệnh mua/bán chứng chỉ quỹ với NAV ngày hôm đó.
3. Quỹ nhận tiền mua/trả tiền bán, điều chỉnh danh mục tương ứng.
4. Lịch sử NAV lưu theo ngày để xem hiệu suất.

## Kịch bản demo

Khởi động quỹ với danh mục FXS và FXA; cuối ngày tính NAV; nhà đầu tư mua chứng chỉ quỹ với NAV đó; quỹ dùng tiền mới để mua thêm CK trên Exchange theo mandate.

## Điều kiện hoàn thành

- NAV tính đúng từ giá đóng cửa thực tế của danh mục.
- Giao dịch chứng chỉ quỹ không đi qua order book Exchange.
- Chưa có ETF (giao dịch intraday theo NAV), closed-end fund hay quỹ trái phiếu.
