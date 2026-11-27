# Nghiệp vụ MVP 43 — AI Video Knowledge Base

## Mục đích và phạm vi

Tài liệu này mô tả nghiệp vụ biến kho video trên Google Drive thành kho tri thức có thể đọc, tìm kiếm và hỏi đáp mà không cần xem lại từng video. MVP đầu tiên chỉ bao gồm kết nối Drive, lấy danh sách video, tự động tạo bản tóm tắt có cấu trúc (từ cả lời nói lẫn hình ảnh), theo dõi tiến độ và xử lý lỗi. Đồng bộ tăng dần, theo dõi chi phí, tìm kiếm, hỏi đáp và phân loại tự động thuộc các giai đoạn sau. Phiên bản đầu chỉ hỗ trợ video có lời nói tiếng Việt và hướng tới kho dưới 500 video. Tham chiếu đặc tả: `specs/000043-ai-video-knowledge-base/spec.md`.

## Bối cảnh nghiệp vụ

Nhiều tổ chức lưu khóa học, buổi họp, video hướng dẫn và demo sản phẩm trên Google Drive. Kiến thức nằm trong video nên rất khó dùng lại: muốn biết một video nói gì phải xem từ đầu; muốn tìm một nội dung trong hàng trăm video thì chỉ còn cách đoán qua tên file. Có những khoản kiến thức chỉ hiện trên màn hình (cấu hình, slide, thao tác phần mềm) mà người nói không đọc thành lời, nên chỉ nghe lời nói là chưa đủ.

Trong MVP này, hệ thống đóng vai người "xem hộ": lấy video mà tổ chức cho phép, đọc cả lời nói lẫn nội dung trên hình, rồi ghi lại thành bản tóm tắt có mục lục theo mốc thời gian để người dùng đọc nhanh và quay lại đúng đoạn cần xem. Mỗi phiên bản video chỉ được "xem" một lần; kết quả được lưu để tra cứu nhiều lần, tránh tốn chi phí xử lý lặp.

```text
[Người lưu video] → [Google Drive] → [Hệ thống phân tích AI] → [Kho tri thức] → [Người đọc]
                                     └────── phạm vi MVP: kết nối, phân tích, tóm tắt, hiển thị ──────┘
```

## Vai trò trong thị trường thực tế

```text
[Người tạo/lưu video] → [Google Drive] → [Quản trị viên kết nối nguồn] → [Hệ thống tạo tri thức] → [Người dùng tra cứu]
```

| Vai trò | Trách nhiệm thực tế | Trong MVP này |
|---|---|---|
| Người tạo/lưu video | Quay và đặt video vào các thư mục trên Drive, quyết định ai được xem hoặc tải | Quyền của họ trên Drive là căn cứ duy nhất cho việc ai được xem tri thức |
| Quản trị viên | Chọn thư mục nào được phân tích, theo dõi tiến độ và xử lý lỗi | Kết nối Drive, chọn nguồn, xem tiến độ, yêu cầu xử lý lại |
| Người dùng tra cứu | Cần nắm nhanh nội dung video và tìm lại kiến thức | Đọc bản tóm tắt, mục lục, kiến thức chính của video mình có quyền xem |
| Hệ thống phân tích AI | Xem lời nói và hình ảnh, tổng hợp thành tri thức có cấu trúc | Tạo bản tóm tắt cho mỗi phiên bản video, một lần duy nhất |

## Luồng nghiệp vụ đầu-cuối

1. **Trong phạm vi MVP** — Quản trị viên kết nối tài khoản Google Drive và chọn các thư mục chứa video, sau khi được thông báo rõ rằng nội dung các thư mục này sẽ được gửi tới dịch vụ AI bên ngoài tổ chức để phân tích. Người dùng khác đăng nhập bằng tài khoản Google của chính họ để xem kết quả.
2. **Trong phạm vi MVP** — Hệ thống liệt kê video tìm thấy (kể cả thư mục con) và đặt trạng thái chờ xử lý.
3. **Trong phạm vi MVP** — Hệ thống kiểm tra từng video có được phép tải hay không; video không được tải được đánh dấu bị từ chối truy cập kèm lý do; video có lời nói không phải tiếng Việt được ghi nhận là không hỗ trợ và không được tóm tắt.
4. **Trong phạm vi MVP** — Hệ thống lấy nội dung video, phân tích lời nói và nội dung hiển thị trên hình, rồi tổng hợp thành bản tóm tắt có cấu trúc; video dài được tóm tắt theo từng phần rồi gộp lại để không bỏ sót phần giữa và cuối.
5. **Trong phạm vi MVP** — Hệ thống lưu kết quả, đánh dấu video hoàn thành và không giữ lâu dài bản sao video gốc. Khi video bị xóa khỏi Drive hoặc tài khoản kết nối mất quyền với video, tri thức của video được ẩn ngay và xóa hẳn sau tối đa 30 ngày.
6. **Trong phạm vi MVP** — Lỗi tạm thời được tự thử lại có giới hạn; lỗi quyền hoặc dữ liệu hỏng được tách riêng để quản trị viên xử lý và yêu cầu chạy lại.
7. **Trong phạm vi MVP** — Người dùng mở video đã hoàn thành để đọc tóm tắt nhanh, tóm tắt đầy đủ, mục lục theo mốc thời gian, kiến thức chính, thẻ, nhóm chủ đề, mức độ và link về video gốc.
8. **Ngoài phạm vi MVP** — Tự động phát hiện video mới/thay đổi, theo dõi và giới hạn chi phí xử lý (giai đoạn Automation).
9. **Ngoài phạm vi MVP** — Tìm kiếm theo từ khóa và theo ý nghĩa, hỏi đáp xuyên toàn bộ kho kèm nguồn video và mốc thời gian (giai đoạn Knowledge Base).
10. **Ngoài phạm vi MVP** — Tự phân loại, tổng hợp theo chủ đề và phát hiện nội dung trùng lặp (giai đoạn Intelligence).

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Kết nối Drive | Liên kết giữa tổ chức và tài khoản Google Drive đã cấp quyền đọc |
| Nguồn video | Thư mục trên Drive được chọn để phân tích |
| Video | Một file video trên Drive, có trạng thái xử lý và thông tin quyền tải |
| Phiên bản video | Một trạng thái nội dung cụ thể của video; mỗi phiên bản có tối đa một kết quả tri thức hiện hành |
| Công việc xử lý | Một lần xử lý cho một phiên bản video, ghi nhận tiến độ, số lần thử lại và nguyên nhân lỗi |
| Bản tóm tắt | Tóm tắt nhanh, tóm tắt đầy đủ, mục lục theo mốc thời gian, kiến thức chính, mức độ, thẻ và nhóm chủ đề |
| Transcript và thông tin hình ảnh | Toàn bộ lời nói có mốc thời gian và nội dung quan trọng xuất hiện trên hình |

## Quy tắc nghiệp vụ

- **BR-001**: Mỗi video ở một phiên bản nội dung chỉ được phân tích bằng AI thành công một lần; chỉ phân tích lại khi nội dung thay đổi hoặc quản trị viên yêu cầu. Quy tắc này tránh tốn chi phí lặp cho cùng một nội dung.
- **BR-002**: Chỉ video mà tài khoản kết nối có quyền tải mới được đưa vào xử lý. Trên Drive, quyền xem không đồng nghĩa với quyền tải.
- **BR-003**: Quyền xem tri thức kế thừa từ quyền truy cập video gốc trên Drive; không tạo hệ thống phân quyền riêng, để người mất quyền với video cũng không còn xem được bản tóm tắt.
- **BR-004**: Lỗi tạm thời được thử lại có giới hạn; lỗi quyền và dữ liệu không hợp lệ không tự thử lại vì thử lại cũng không thay đổi kết quả.
- **BR-005**: Khi chạm giới hạn chi phí do quản trị viên đặt, hệ thống dừng nhận video mới và thông báo; hệ thống không tự nâng giới hạn.
- **BR-006**: Mọi nhận định trong tóm tắt và câu trả lời phải truy ngược được về video và mốc thời gian nguồn để người dùng tự kiểm chứng.
- **BR-007**: Đổi tên hoặc di chuyển video không làm mất kết quả đã phân tích và không kích hoạt phân tích lại.
- **BR-008**: Nội dung video chỉ được gửi tới dịch vụ AI bên ngoài tổ chức khi video thuộc thư mục do quản trị viên chọn làm nguồn. Video ngoài các nguồn đã chọn không bao giờ được gửi đi, vì nội dung video có thể chứa thông tin nội bộ.
- **BR-009**: Tri thức của video bị xóa khỏi Drive hoặc mất quyền tải được ẩn ngay, giữ tối đa 30 ngày để khôi phục rồi xóa hẳn. Nếu quyền được phục hồi trong thời hạn đó thì tri thức hiển thị lại mà không phải phân tích lại, tránh tốn chi phí khi xóa nhầm.
- **BR-010**: Hệ thống chỉ hỗ trợ video có lời nói tiếng Việt. Bản tóm tắt và các trường tri thức hiển thị bằng tiếng Việt, thuật ngữ kỹ thuật giữ nguyên tiếng Anh, transcript giữ nguyên ngôn ngữ gốc.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Thư mục không có video nào | Hiển thị trạng thái trống kèm hướng dẫn chọn lại nguồn |
| Video chỉ cho xem, không cho tải | Đánh dấu bị từ chối truy cập kèm lý do; không xử lý |
| Quyền kết nối Drive bị thu hồi | Báo cần kết nối lại; không xử lý thêm video mới |
| Dịch vụ AI hoặc Drive lỗi tạm thời | Tự thử lại có giới hạn; hết lượt thử thì đánh dấu lỗi và cho phép xử lý lại |
| Video hỏng hoặc không đọc được | Đánh dấu lỗi kèm lý do; không ảnh hưởng các video khác |
| Video không có lời nói hoặc không có hình | Vẫn tóm tắt từ phần có sẵn |
| Video chỉ đổi tên hoặc di chuyển | Chỉ cập nhật thông tin hiển thị, không phân tích lại |
| Nội dung video bị thay bằng phiên bản khác | Phân tích lại phiên bản mới; kết quả cũ không còn là kết quả hiện hành |
| Cùng một video bị kích hoạt xử lý nhiều lần | Chỉ một lần xử lý được thực hiện |
| Người dùng mất quyền với video gốc | Không còn thấy video và nội dung của nó |
| Video bị xóa khỏi Drive hoặc tài khoản kết nối mất quyền với video | Tri thức bị ẩn ngay, xóa hẳn sau tối đa 30 ngày; phục hồi quyền trong thời hạn thì hiển thị lại |
| Video có lời nói không phải tiếng Việt | Ghi nhận là không hỗ trợ, không tạo bản tóm tắt |
| Video nằm ngoài thư mục quản trị viên đã chọn | Không được gửi tới dịch vụ AI bên ngoài và không được xử lý |

## Ngoài phạm vi

- Chỉnh sửa, cắt ghép hoặc tạo video mới.
- Phân tích video ngoài Google Drive (YouTube, ổ đĩa cục bộ, nền tảng khác).
- Phát video trong ứng dụng thay cho trình phát của Drive (MVP chỉ dẫn link và mốc thời gian).
- Nhận diện khuôn mặt, nhận diện người nói theo danh tính.
- Dịch tự động nội dung giữa các ngôn ngữ.
- Xử lý theo thời gian thực/livestream.
- Video có lời nói bằng ngôn ngữ khác tiếng Việt và hỗ trợ đa ngôn ngữ.
- Đồng bộ tự động liên tục, theo dõi chi phí, tìm kiếm, hỏi đáp và phân loại tự động (các giai đoạn sau MVP).

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000043-ai-video-knowledge-base/spec.md): user stories, acceptance criteria và ràng buộc.
- [Index tài liệu nghiệp vụ](business-docs-index.md)
