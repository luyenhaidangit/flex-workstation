# Skill dùng chung

Thư mục `skills/` dùng để lưu các skill hoặc hướng dẫn thao tác có thể tái sử dụng trong nhiều project thuộc workspace `flex-workstation`.

## Mục đích

- Lưu các quy trình lặp lại để Claude Code (hoặc AI assistant khác) thực hiện nhất quán.
- Chuẩn hóa cách phân tích, triển khai, kiểm thử, viết tài liệu và review.
- Giữ skill ở cùng repository để dễ chia sẻ bối cảnh giữa các project con.

## Cấu trúc đề xuất

Mỗi skill nên nằm trong một thư mục riêng:

```text
skills/
+-- skill-name/
    |-- SKILL.md
    |-- references/
    +-- scripts/
```

Trong đó:

- `SKILL.md`: mô tả khi nào dùng skill, quy trình thực hiện và tiêu chuẩn hoàn tất.
- `references/`: tài liệu tham chiếu, checklist hoặc ví dụ.
- `scripts/`: script hỗ trợ nếu skill cần tự động hóa.

## Mẫu `SKILL.md`

```markdown
---
name: skill-name
description: Mô tả ngắn gọn khi nào cần dùng skill này.
---

# Skill Name

## Khi nào dùng

Mô tả tình huống kích hoạt skill.

## Quy trình

1. Thu thập bối cảnh cần thiết.
2. Thực hiện các bước chính.
3. Kiểm tra kết quả.

## Tiêu chuẩn hoàn tất

- Kết quả đáp ứng mục tiêu.
- Có ghi chú hoặc tài liệu nếu thay đổi quan trọng.
- Có kiểm thử hoặc bước xác minh phù hợp.
```

## Quy ước

- Tên skill nên ngắn, viết bằng chữ thường và dùng dấu gạch ngang, ví dụ `api-review`.
- Không đưa thông tin nhạy cảm, token, khóa API hoặc credential vào skill.
- Skill chỉ nên chứa quy trình có khả năng tái sử dụng, không chứa ghi chú tạm thời của một task đơn lẻ.
- Description phải cụ thể: kê rõ "skill làm gì" + "khi nào trigger" (file/keyword/tình huống). Description chung chung dẫn đến undertrigger, skill ít được dùng.
