# MVP 10 — Giám sát giao dịch và điều tra

## Mục tiêu

Phát hiện, giải thích và lưu vết hành vi đáng ngờ trên dữ liệu thị trường đã đủ dày.

## Phạm vi

- Dùng event lệnh, khớp, hủy, liên hệ tài khoản mô phỏng và corporate action.
- Rule-based detection cho wash trading và một pattern thao túng giá đơn giản.
- Alert dashboard, case điều tra và báo cáo nháp do agent tạo ngoài hot path.

## Quy tắc

- Alert là tín hiệu cần xem xét, không phải kết luận vi phạm.
- Lớp giám sát được nhìn dữ liệu xuyên CTCK theo vai trò được cấp quyền; CTCK thường chỉ nhìn tenant mình.
- Báo cáo phải đính event/giao dịch làm bằng chứng và nêu phần dữ liệu còn thiếu.

## Kịch bản demo

Chạy bot tạo vòng giao dịch giả lập; rule sinh alert; điều tra viên mở case và xuất báo cáo nháp có các lệnh, giao dịch, thời điểm liên quan.

## Điều kiện hoàn thành

- Không tự khóa tài khoản, không kết luận pháp lý và chưa cần ML phức tạp.
