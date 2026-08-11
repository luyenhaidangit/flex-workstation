# Nghiệp vụ MVP 000033 — Tích hợp chat AI tại màn Agent

## Mục đích và phạm vi

MVP này giúp người cấu hình AI Agent kiểm tra trực tiếp cách Agent trả lời câu hỏi ngay tại màn cấu hình. Trước đây, khung xem trước chỉ mô phỏng hai người trao đổi với nhau nên không thể hiện được năng lực thực tế của Agent. Sau thay đổi, một người dùng thử nghiệm gửi câu hỏi và nhận phản hồi của chính AI Agent đang được cấu hình.

Phạm vi chỉ là phiên kiểm tra tức thời trước khi phát hành Agent. MVP không phải là kênh chăm sóc khách hàng thực tế, không lưu trữ lịch sử dài hạn và không thay thế các quy trình tiếp nhận, phân công hoặc xử lý hội thoại đang có. Nguồn yêu cầu chi tiết: [spec.md](../../specs/000033-ai-chat-integration/spec.md).

## Bối cảnh nghiệp vụ

Trong vận hành chăm sóc khách hàng, AI Agent cần trả lời nhất quán theo vai trò, thông tin và chỉ dẫn mà doanh nghiệp đã thiết lập. Trước khi đưa Agent vào sử dụng, nhân viên nghiệp vụ cần thử các câu hỏi đại diện — chẳng hạn câu hỏi về chính sách, hướng dẫn thao tác hoặc tình trạng hỗ trợ — để nhận biết Agent có trả lời đúng định hướng hay chưa.

Việc kiểm tra phải phản ánh đúng tình huống người dùng đặt câu hỏi cho Agent. Một cuộc chat mô phỏng giữa hai người không cho thấy chất lượng phản hồi của Agent và khiến người cấu hình phải phối hợp thủ công để xác nhận kết quả. MVP tạo một điểm kiểm tra rõ ràng ngay trong lúc cấu hình, giúp phát hiện Agent chưa sẵn sàng hoặc phản hồi chưa nhận được trước khi phát hành.

## Vai trò trong thị trường thực tế

```text
Người cấu hình/kiểm tra Agent → AI Agent → Phản hồi kiểm tra
            └──────── Phạm vi MVP 000033 ────────┘

Khách hàng thực tế → Kênh chăm sóc khách hàng → Nhân viên/AI vận hành
                 (ngoài phạm vi MVP này)
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Quản trị viên hoặc nhân viên nghiệp vụ | Thiết lập vai trò, nội dung và chỉ dẫn cho Agent; kiểm tra trước khi dùng | Chọn người gửi thử nghiệm, đặt câu hỏi và đánh giá phản hồi hiển thị |
| AI Agent | Nhận câu hỏi và trả lời theo cấu hình được giao | Trả lời câu hỏi kiểm tra hoặc cho biết không thể trả lời |
| Người gửi thử nghiệm | Đại diện ngữ cảnh người đặt câu hỏi | Là danh tính dùng để thực hiện phiên kiểm tra, không phải người tham gia chat thứ hai |
| Khách hàng thực tế | Gửi yêu cầu hỗ trợ trong vận hành | Không tham gia MVP này |

## Luồng nghiệp vụ đầu-cuối

1. Người cấu hình hoàn tất các thông tin và chỉ dẫn cần thiết cho AI Agent.
2. Người cấu hình mở khung xem trước, chọn người gửi thử nghiệm và kiểm tra Agent có sẵn sàng nhận câu hỏi không. **Trong phạm vi MVP.**
3. Người gửi thử nghiệm nhập một câu hỏi đại diện cho tình huống chăm sóc khách hàng. **Trong phạm vi MVP.**
4. Câu hỏi được thể hiện là tin nhắn của người dùng; AI Agent xử lý câu hỏi và khung xem trước báo rõ đang chờ kết quả. **Trong phạm vi MVP.**
5. AI Agent trả lời; người cấu hình đọc phản hồi để đánh giá mức phù hợp với cấu hình. Nếu chưa phù hợp, họ điều chỉnh cấu hình trước khi phát hành. **Trong phạm vi MVP.**
6. Nếu Agent chưa sẵn sàng, phản hồi lỗi hoặc quá thời gian chờ, người cấu hình nhận thông báo rõ ràng và có thể thử lại. **Trong phạm vi MVP.**
7. Sau khi phát hành, khách hàng thực tế tương tác qua các kênh vận hành và có thể được chuyển cho nhân viên theo quy trình riêng. **Ngoài phạm vi MVP.**

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Phiên xem trước hội thoại | Một lần kiểm tra Agent trong lúc người dùng ở trên màn cấu hình |
| Câu hỏi kiểm tra | Nội dung đại diện cho điều mà khách hàng hoặc người dùng có thể hỏi Agent |
| Phản hồi của Agent | Kết quả thực tế để người cấu hình đánh giá Agent có hoạt động theo kỳ vọng hay không |
| Trạng thái sẵn sàng của Agent | Thông tin giúp người dùng biết có thể kiểm tra Agent ngay hay cần xử lý kết nối/trạng thái trước |
| Thông báo lỗi hoặc quá thời gian chờ | Kết quả minh bạch khi không thể nhận phản hồi, tránh hiểu nhầm là Agent đã trả lời |

## Quy tắc nghiệp vụ

- Mỗi câu hỏi trong khung xem trước thuộc về người gửi thử nghiệm được chọn tại thời điểm gửi. Điều này giữ đúng ngữ cảnh “người hỏi — Agent trả lời”, thay vì tạo cảm giác có hai khách hàng đang chat với nhau.
- Tại một thời điểm chỉ xử lý một câu hỏi đang chờ trong một phiên xem trước. Quy tắc này giúp người cấu hình biết chính xác phản hồi nào thuộc về câu hỏi nào và tránh gửi lặp do chưa thấy kết quả.
- Chỉ phản hồi thực tế từ AI Agent đang kiểm tra mới được hiển thị là câu trả lời của Agent. Không dùng câu trả lời có sẵn hay tin nhắn của người khác thay thế, vì việc kiểm tra cần phản ánh năng lực thật của Agent.
- Khi Agent chưa sẵn sàng, người dùng phải được báo rõ trước hoặc ngay lúc gửi câu hỏi. Mục đích là để người cấu hình phân biệt lỗi sẵn sàng với chất lượng trả lời của Agent.
- Chỉ người có quyền xem trước và kiểm tra Agent mới được xem hoặc gửi câu hỏi. Câu hỏi kiểm tra có thể chứa thông tin nghiệp vụ hoặc dữ liệu khách hàng nên không được hiển thị ngoài phạm vi quyền được cấp.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Agent sẵn sàng, câu hỏi hợp lệ | Câu hỏi xuất hiện dưới vai trò người dùng và Agent trả lời trong cùng phiên xem trước |
| Agent đang xử lý câu hỏi | Người dùng thấy trạng thái chờ và không gửi trùng câu hỏi đang xử lý |
| Agent chưa sẵn sàng/kết nối | Người dùng nhận biết rõ không thể kiểm tra tại thời điểm đó; không có phản hồi giả lập |
| Không nhận được phản hồi hoặc quá thời gian chờ | Lịch sử đã hiển thị được giữ lại, có thông báo dễ hiểu và người dùng có thể thử lại |
| Câu hỏi rỗng hoặc chỉ có khoảng trắng | Không gửi câu hỏi; người dùng được nhắc nhập nội dung hợp lệ |
| Người dùng không có quyền | Không được xem hoặc gửi nội dung trong phiên kiểm tra của Agent đó |

## Ngoài phạm vi

- Lưu trữ, tìm kiếm hoặc phân tích lịch sử hội thoại kiểm tra sau khi người dùng rời màn.
- Hội thoại khách hàng thực tế trên nhiều kênh, chuyển tiếp nhân viên, phân công hoặc quản lý ticket.
- Huấn luyện Agent, thay đổi kho kiến thức hoặc tự động phát hành Agent từ cuộc hội thoại xem trước.
- Tệp đính kèm, ghi âm và các nội dung ngoài văn bản trong phiên bản đầu tiên.

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000033-ai-chat-integration/spec.md): user stories, acceptance criteria, phân quyền và các ràng buộc chi tiết.
- Các phụ thuộc nghiệp vụ: khả năng AI Agent nhận câu hỏi kiểm tra, cơ chế xác thực/phân quyền hiện có và trạng thái sẵn sàng của Agent.
