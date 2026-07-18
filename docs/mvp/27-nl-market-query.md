# MVP 27 — Natural language market query

## Mục tiêu

Cho phép người dùng hỏi câu hỏi bằng tiếng Việt tự nhiên về dữ liệu thị trường và nhận câu trả lời có dẫn nguồn, không cần biết SQL hay cấu trúc API.

## Phạm vi

- Parse câu hỏi tiếng Việt thành query có cấu trúc (filter, aggregation, time range, symbol, account).
- Nguồn dữ liệu: event stream Exchange, danh mục CTCK, ledger, alert surveillance, kho research MVP 11.
- Trả lời dạng text có dẫn số liệu cụ thể và link tới record nguồn.
- Phân quyền: kết quả lọc theo role người hỏi (CTCK chỉ thấy dữ liệu tenant mình, giám sát thấy toàn thị trường).

## Ví dụ câu hỏi

- "Hôm nay tài khoản nào giao dịch nhiều nhất theo khối lượng?"
- "FXS biến động mạnh nhất vào khung giờ nào trong tuần qua?"
- "Cặp tài khoản nào có giao dịch đối ứng nhau nhiều lần trong một ngày?"
- "So sánh room ngoại FXS và FXA hiện tại."

## Quy tắc

- Câu trả lời phải nêu câu query đã dịch để người dùng kiểm tra logic.
- Nếu câu hỏi không đủ dữ liệu, nói rõ thiếu gì thay vì đoán.
- Không tự đặt lệnh hay thực hiện hành động — chỉ đọc và tổng hợp.

## Kịch bản demo

Điều tra viên hỏi "tuần này tài khoản nào có tỷ lệ huỷ lệnh cao bất thường?"; hệ thống dịch thành query, trả về top 5 tài khoản kèm tỷ lệ và link event; điều tra viên click vào và xem chi tiết.

## Điều kiện hoàn thành

- Câu hỏi cơ bản về top N, filter theo ngày/mã/tài khoản cho kết quả đúng.
- Kết quả phân quyền đúng theo role; tenant A không thấy dữ liệu tenant B.
- Chưa có multi-turn conversation, memory ngữ cảnh hay tự sinh biểu đồ.
