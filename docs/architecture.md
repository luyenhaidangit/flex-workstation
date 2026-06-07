# Kiến trúc workspace

Tài liệu này mô tả cách tổ chức các project, tài liệu và skill trong `flex-workstation`.

## Tổng quan

`flex-workstation` được tổ chức như một workspace chung, không giả định sẵn một công nghệ duy nhất. Mỗi project con có thể dùng stack riêng, nhưng vẫn cần tuân thủ quy ước tài liệu và cách ghi nhận task chung.

## Thành phần chính

| Thành phần | Vai trò |
| --- | --- |
| `README.md` | Tài liệu định hướng chính của workspace. |
| `docs/` | Nơi lưu tài liệu triển khai, task, kiến trúc và quyết định kỹ thuật. |
| `skills/` | Nơi lưu skill dùng chung cho Codex hoặc quy trình làm việc lặp lại. |
| Project con | Mỗi project nghiệp vụ hoặc kỹ thuật nên nằm trong một thư mục riêng ở cấp workspace. |

## Kiến trúc project con

Khi thêm project mới, nên dùng cấu trúc tối thiểu:

```text
project-name/
|-- README.md
|-- src/
|-- tests/
+-- docs/
```

Trong đó:

- `README.md`: mục đích project, cách chạy, cách kiểm thử, các lệnh thường dùng.
- `src/`: mã nguồn chính.
- `tests/`: kiểm thử tự động nếu project có code.
- `docs/`: tài liệu riêng của project, ví dụ kiến trúc chi tiết, API, nghiệp vụ hoặc ghi chú triển khai.

## Quy ước kiến trúc

- Tách rõ tài liệu workspace và tài liệu của từng project con.
- Không đặt logic dùng riêng của một project vào thư mục dùng chung nếu chưa có nhu cầu tái sử dụng thật sự.
- Khi một quy trình được dùng lặp lại nhiều lần, cân nhắc chuyển thành skill trong `skills/`.
- Mỗi quyết định kiến trúc quan trọng nên được ghi lại trong `docs/` hoặc tài liệu riêng của project liên quan.

## Danh sách project

Hiện chưa có project con được định nghĩa. Khi thêm project, cập nhật bảng sau:

| Project | Mục đích | Công nghệ | Trạng thái | Ghi chú |
| --- | --- | --- | --- | --- |
| Chưa có | Chưa xác định | Chưa xác định | Khởi tạo | Bổ sung khi có project cụ thể. |

## Hướng phát triển tiếp theo

- Xác định các project con cần quản lý trong workspace.
- Bổ sung sơ đồ luồng triển khai nếu có nhiều project phụ thuộc nhau.
- Chuẩn hóa quy ước branch, commit, test và release nếu workspace bắt đầu có sản phẩm chạy được.
