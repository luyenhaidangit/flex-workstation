# Nghiệp vụ MVP 32 — Chat AI cơ bản

## Mục đích và phạm vi

MVP 32 giúp người dùng FLEX Agent nhanh chóng nắm được nội dung chính của một cuộc hội thoại dài mà không phải tự đọc lại toàn bộ. Người dùng gửi nội dung hội thoại và nhận một bản tóm tắt văn bản hoặc một thông báo rõ ràng để biết cần làm gì tiếp theo. MVP này chỉ phục vụ tác vụ tóm tắt một lần, chưa hình thành một công cụ quản lý hội thoại hay trợ lý nhiều lượt. Nội dung chi tiết được truy vết tại [specs/000032-ai-chat-basics/spec.md](../../specs/000032-ai-chat-basics/spec.md).

## Bối cảnh nghiệp vụ

Trong công việc thực tế, nhân viên thường tiếp nhận hội thoại dài với khách hàng, đồng nghiệp hoặc các bên liên quan. Việc phải đọc toàn bộ lịch sử trước khi xử lý tiếp làm chậm thao tác và có thể bỏ sót ý chính. MVP này mô phỏng bước hỗ trợ ban đầu của một trợ lý: người dùng cung cấp đúng đoạn hội thoại cần xem, sau đó nhận lại phần tóm lược để tiếp tục công việc.

Giá trị trọng tâm là trải nghiệm ổn định cho người dùng. Người dùng chỉ cần quan tâm đến nội dung muốn tóm tắt, không cần biết hay lựa chọn dịch vụ AI đang hỗ trợ ở phía sau.

## Vai trò trong thị trường thực tế

```text
Người tạo hoặc tiếp nhận hội thoại → Nhân viên cần xử lý thông tin → Bản tóm tắt hỗ trợ quyết định tiếp theo
                                          └── Phạm vi MVP 32 ──┘
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Người dùng đã đăng nhập | Rà soát thông tin trao đổi và tiếp tục xử lý công việc | Gửi nội dung hội thoại, yêu cầu tóm tắt và đọc kết quả |
| Trợ lý tóm tắt | Chắt lọc nội dung chính từ trao đổi được cung cấp | Trả về bản tóm tắt hoặc thông báo không thể hoàn tất |
| Hệ thống FLEX Agent | Bảo đảm chỉ người hợp lệ dùng được trợ lý và có phản hồi rõ ràng | Tiếp nhận yêu cầu, bảo vệ nội dung và hiển thị kết quả phù hợp |

## Luồng nghiệp vụ đầu-cuối

1. **[IN SCOPE]** Người dùng đã đăng nhập chọn một đoạn hội thoại cần nắm nhanh.
2. **[IN SCOPE]** Người dùng gửi nội dung đó cùng yêu cầu tóm tắt.
3. **[IN SCOPE]** Hệ thống kiểm tra người gửi được phép sử dụng chức năng và nội dung có thực sự được cung cấp.
4. **[IN SCOPE]** Hệ thống tạo bản tóm tắt từ nội dung hợp lệ.
5. **[IN SCOPE]** Người dùng đọc bản tóm tắt để tiếp tục công việc; nếu không thể xử lý, họ nhận thông báo rõ ràng để bổ sung nội dung hoặc thử lại.
6. **[Ngoài phạm vi]** Người dùng lưu, tìm lại, trao đổi tiếp nhiều lượt hoặc quản trị danh mục dịch vụ AI.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Yêu cầu tóm tắt | Một đoạn hội thoại và chỉ dẫn tóm tắt do người dùng gửi trong một lần tương tác |
| Kết quả tóm tắt | Phần nội dung rút gọn phục vụ việc đọc nhanh, hoặc trạng thái cho biết yêu cầu chưa hoàn tất |

## Quy tắc nghiệp vụ

- **BR-001 — Nội dung phải có ý nghĩa**: Chỉ xử lý khi người dùng thực sự cung cấp hội thoại; một yêu cầu rỗng hoặc chỉ có khoảng trắng không thể tạo giá trị tóm tắt.
- **BR-002 — Chỉ công nhận kết quả có nội dung**: Một yêu cầu chỉ hoàn tất khi người dùng nhận được phần tóm tắt văn bản không rỗng. Điều này tránh việc người dùng hiểu nhầm một phản hồi thiếu nội dung là đã xong.
- **BR-003 — Mỗi lần yêu cầu là độc lập**: MVP không dùng lại nội dung từ lần gửi trước. Quy tắc này giữ ranh giới dữ liệu rõ ràng và phù hợp với mục tiêu kiểm chứng luồng cơ bản trước khi mở rộng.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Người dùng có quyền gửi hội thoại hợp lệ | Nhận bản tóm tắt để đọc và xử lý công việc tiếp theo |
| Người dùng không nhập nội dung hoặc chỉ nhập khoảng trắng | Nhận hướng dẫn bổ sung nội dung; không nhận kết quả tóm tắt |
| Không thể hoàn thành việc tóm tắt hoặc thời gian chờ kết thúc | Nhận thông báo rõ ràng, không nhầm lẫn với một bản tóm tắt hoàn chỉnh, và có thể gửi lại |
| Người chưa đăng nhập cố sử dụng chức năng | Không được gửi yêu cầu hoặc xem kết quả |
| Kết quả trả về không có nội dung | Được xử lý như chưa hoàn tất và nhận thông báo phù hợp |

## Ngoài phạm vi

- Lưu trữ, tìm kiếm và quản lý lịch sử hội thoại hoặc kết quả tóm tắt; sẽ chỉ xem xét sau khi luồng cơ bản được xác nhận có giá trị.
- Hội thoại nhiều lượt, phản hồi theo thời gian thực, tệp đính kèm và các tác vụ AI khác như soạn thảo hoặc phân loại.
- Quản trị dịch vụ AI, lựa chọn nhà cung cấp, đánh giá chất lượng mô hình hoặc cho người dùng tự chuyển đổi dịch vụ nền.

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000032-ai-chat-basics/spec.md): user stories, acceptance criteria và ràng buộc kỹ thuật.
