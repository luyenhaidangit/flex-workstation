# MVP 12 — Nhóm agent và báo cáo research

## Mục tiêu

Hoàn thiện research desk bằng quy trình phân tích có kiểm soát, minh bạch nguồn và có người duyệt.

## Phạm vi

- Agent thu thập bằng chứng từ kho MVP 11.
- Agent phân tích tạo luận điểm, rủi ro và câu hỏi còn mở.
- Agent kiểm tra đối chiếu luận điểm với nguồn; người dùng phê duyệt trước khi công bố nội bộ.

## Luồng chính

1. Người dùng chọn tenant, mã CK và mẫu báo cáo.
2. Agent thu thập trả về nguồn; agent phân tích viết nháp.
3. Agent kiểm tra đánh dấu nhận định thiếu nguồn hoặc mâu thuẫn.
4. Người dùng sửa/phê duyệt; hệ thống lưu phiên bản báo cáo theo tenant.

## Kịch bản demo

Tạo báo cáo cho một mã trong watchlist, bao gồm luận điểm, rủi ro, nguồn dẫn và cảnh báo thiếu dữ liệu; người dùng phê duyệt để phát hành nội bộ.

## Điều kiện hoàn thành

- Không tự giao dịch, không đưa khuyến nghị cá nhân hóa và không thay thế kiểm soát tuân thủ.
- Đây là điểm kết thúc roadmap; các mở rộng sau phải được specify như feature mới.
