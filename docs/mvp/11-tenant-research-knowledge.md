# MVP 11 — Kho tri thức research theo tenant

## Mục tiêu

Mỗi CTCK có kho tài liệu nghiên cứu riêng và truy vấn được câu trả lời có nguồn.

## Phạm vi

- Nạp BCTC/tin tức công khai hoặc tài liệu mô phỏng đã được phép dùng.
- Metadata tối thiểu: tenant, mã CK, nguồn, ngày, loại tài liệu và quyền truy cập.
- Tìm kiếm theo mã/câu hỏi, trả về đoạn liên quan cùng nguồn.

## Quy tắc

- Truy vấn Alpha chỉ tìm trong corpus Alpha được cấp quyền.
- Câu trả lời phải nêu nguồn; nếu không đủ nguồn phải nói rõ là thiếu dữ liệu.
- Dữ liệu research không tự tạo lệnh giao dịch.

## Kịch bản demo

Nạp tài liệu khác nhau cho Alpha và Beta. Cùng một câu hỏi về FXS cho hai tenant trả về bộ nguồn tương ứng, không rò rỉ tài liệu chéo tenant.

## Điều kiện hoàn thành

- Chưa lấy dữ liệu trả phí, chưa khuyến nghị đầu tư cá nhân hóa và chưa cần nhiều agent.
