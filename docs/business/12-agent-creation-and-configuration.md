# Nghiệp vụ MVP 12 — Tạo và cấu hình AI Agent

## Mục đích và phạm vi

MVP này làm rõ giai đoạn khởi tạo một AI Agent trước khi người dùng bổ sung tri thức, kỹ năng, kiểm thử và phát hành. Người dùng phải chủ động xác nhận việc tạo Agent từ thông tin chung; sau đó hệ thống mới cho phép tiếp tục cấu hình. Luồng này giúp phân biệt một Agent chưa tồn tại với một Agent đã được tạo nhưng còn ở trạng thái bản nháp. Tham chiếu đặc tả: [specs/000040-agent-creation-gating/spec.md](../../specs/000040-agent-creation-gating/spec.md).

Phạm vi MVP chỉ điều chỉnh cách thể hiện và điều phối luồng hiện có. Cơ chế lưu nháp riêng, versioning và các màn hình cấu hình tri thức, kỹ năng, đào tạo hoặc phát hành chi tiết chưa thuộc phạm vi này.

## Bối cảnh nghiệp vụ

Người quản lý Agent thường bắt đầu từ việc đặt tên, mô tả vai trò và cung cấp chỉ dẫn chung cho một nhân viên AI. Những thông tin này cần được xác nhận để hệ thống tạo ra một Agent cụ thể trước khi người dùng có thể gắn tri thức, thiết lập kỹ năng hoặc kiểm tra cách Agent phản hồi.

Nếu các bước sau được hiển thị như đã sẵn sàng ngay từ đầu, người dùng có thể tưởng rằng Agent đã tồn tại hoặc có thể kiểm thử một cấu hình chưa được khởi tạo. Vì vậy, hệ thống cần thể hiện rõ hai giai đoạn: tạo Agent và cấu hình Agent.

## Vai trò trong luồng thực tế

```text
[Người quản lý Agent]
        │ nhập thông tin chung và xác nhận tạo
        ▼
[Agent được khởi tạo ở trạng thái bản nháp]
        │ bổ sung tri thức, kỹ năng và kiểm thử
        ▼
[Agent sẵn sàng cho quy trình phát hành]
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Người quản lý Agent | Định danh Agent, mô tả vai trò và chuẩn bị cấu hình | Nhập thông tin chung, chủ động tạo Agent và tiếp tục cấu hình |
| AI Agent | Hoạt động theo vai trò, tri thức và chỉ dẫn được giao | Chưa được kiểm thử khi chưa được khởi tạo; được kiểm thử sau khi có Agent |
| Hệ thống quản lý Agent | Ghi nhận Agent và kiểm soát điều kiện chuyển giai đoạn | Hiển thị trạng thái, khóa bước chưa đủ điều kiện và mở khóa sau khi tạo thành công |

## Luồng nghiệp vụ đầu-cuối

1. Người quản lý mở màn hình **Tạo Agent mới**. **Trong phạm vi MVP.**
2. Người quản lý nhập thông tin chung và kiểm tra các trường bắt buộc. **Trong phạm vi MVP.**
3. Trước khi tạo, các bước Tri thức, Kỹ năng, Đào tạo và Phát hành được hiển thị là chưa khả dụng; khu vực Hội thoại, Báo cáo hoạt động và khung Chat cũng chưa thể sử dụng. **Trong phạm vi MVP.**
4. Người quản lý bấm **Tạo Agent và tiếp tục** để xác nhận việc khởi tạo. **Trong phạm vi MVP.**
5. Hệ thống tạo Agent, trả về mã định danh và hiển thị trạng thái **Bản nháp**. **Trong phạm vi MVP.**
6. Các bước cấu hình được mở khóa; người quản lý có thể chọn bước tiếp theo và dùng **Lưu và tiếp tục** khi cần bảo toàn thay đổi. **Trong phạm vi MVP.**
7. Người quản lý bổ sung tri thức, kỹ năng, đào tạo, kiểm thử và phát hành theo các MVP tương ứng. **Ngoài phạm vi chi tiết của MVP này.**

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Thông tin chung | Dữ liệu tối thiểu để định danh và mô tả vai trò của Agent |
| Agent | Nhân viên AI đã được hệ thống khởi tạo để tiếp tục cấu hình |
| Mã định danh Agent | Dấu hiệu cho biết Agent đã tồn tại và đủ điều kiện mở các bước tiếp theo |
| Bản nháp | Agent đã được tạo nhưng chưa hoàn tất quy trình phát hành |
| Stepper cấu hình | Cách thể hiện các giai đoạn và điều kiện truy cập của Agent |

## Quy tắc nghiệp vụ

- **BR-001**: Người quản lý chỉ được thao tác thông tin chung trước khi Agent được khởi tạo. Điều này tránh cấu hình vào một đối tượng chưa tồn tại.
- **BR-002**: Nhấp vào một bước chưa khả dụng không được tự động tạo Agent. Việc tạo phải là hành động xác nhận rõ ràng của người quản lý.
- **BR-003**: Sau khi Agent được khởi tạo, các bước cấu hình được mở khóa và Agent được nhận biết là bản nháp cho đến khi được phát hành.
- **BR-004**: Chỉ được kiểm thử Agent sau khi Agent tồn tại và đã đạt điều kiện sẵn sàng tương ứng.
- **BR-005**: Việc giữ lại nhãn “Lưu nháp” trong giao diện không đồng nghĩa MVP này đã cung cấp cơ chế lưu phiên bản nháp riêng.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Người quản lý mở màn hình tạo mới | Chỉ thông tin chung được thao tác; các bước còn lại có biểu tượng khóa |
| Người quản lý nhấp vào bước khóa | Hệ thống giải thích cần tạo Agent trước và không tạo Agent ngầm |
| Thông tin chung chưa hợp lệ | Người quản lý được chỉ ra lỗi và vẫn ở bước hiện tại |
| Tạo Agent thành công | Hệ thống hiển thị bản nháp và mở khóa bước cấu hình |
| Người quản lý mở khung Chat trước khi Agent tồn tại | Hệ thống hiển thị hướng dẫn, không cho gửi câu hỏi kiểm thử |
| Người quản lý lưu và tiếp tục sau khi Agent đã tạo | Thay đổi hợp lệ được bảo toàn trước khi chuyển sang cấu hình tiếp theo |

## Ngoài phạm vi

- Cơ chế lưu phiên bản nháp riêng hoặc versioning cho Agent đã phát hành.
- Thiết kế chi tiết kho tri thức, kỹ năng, đào tạo, kiểm thử và phát hành.
- Hội thoại khách hàng thực tế và báo cáo hoạt động sau phát hành.
- Thay đổi quy tắc phân quyền hiện có.

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000040-agent-creation-gating/spec.md): user stories, quy tắc nghiệp vụ và phạm vi MVP.
- [Nghiệp vụ tích hợp chat AI](11-ai-chat-integration.md): điều kiện Agent sẵn sàng trước khi kiểm thử trong khung xem trước.
- [Kiến trúc nền tảng AI Agent](../architecture/agent-platform-architecture.md): định hướng Agent Studio, Simulation/Test Lab và Publishing & Channel.

