# Đặc tả tính năng: ai-agent Base

**Branch**: `[000003-ai-agent-base]`

**Ngày tạo**: 2026-07-07

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Mong muốn xây dựng một nền tảng nhân sự AI, đề xuất xây dựng base bước đầu"

---

## 0. Tổng quan

ai-agent Base là nền tảng bước đầu để tổ chức tự tạo, huấn luyện, chạy thử và phát hành AI Agent phục vụ tư vấn, hỏi đáp và hỗ trợ vận hành đa kênh. Mục tiêu là giúp chủ doanh nghiệp, hộ kinh doanh hoặc bộ phận vận hành thiết lập một nhân sự AI có tri thức riêng mà không cần kỹ năng lập trình. Phạm vi bước đầu tập trung vào vòng đời cơ bản của một agent: tạo hồ sơ, nạp tri thức, kiểm thử hội thoại, phát hành và theo dõi hiệu quả.

## Clarifications

### Session 2026-07-07

- Q: Nhóm khách hàng mục tiêu đầu tiên là ai? -> A: Hộ kinh doanh/doanh nghiệp nhỏ
- Q: Kênh phát hành đầu tiên là gì? -> A: Website chat
- Q: Bộ tri thức mẫu/use case đầu tiên là gì? -> A: Bán hàng
- Q: MVP lưu trữ hội thoại khách hàng ở mức nào? -> A: Lưu đầy đủ hội thoại
- Q: Thời gian lưu hội thoại đầy đủ là bao lâu? -> A: 90 ngày

---

## 1. Mục tiêu

- **MĐ-01**: Người quản trị có thể tạo một AI Agent tư vấn cơ bản trong vòng 10 phút với thông tin nhận diện, vai trò và phạm vi trả lời rõ ràng.
- **MĐ-02**: Tổ chức có thể nạp tri thức bán hàng ban đầu cho agent để trả lời tối thiểu 80% câu hỏi thường gặp trong phạm vi đã cấu hình.
- **MĐ-03**: Người vận hành có thể kiểm thử, chỉnh sửa và phát hành agent lên website chat mà không cần phụ thuộc đội kỹ thuật.
- **MĐ-04**: Người quản trị có thể xem được mức độ sử dụng, tỷ lệ trả lời được và các câu hỏi chưa xử lý tốt để tiếp tục cải thiện tri thức.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**: Chủ hộ kinh doanh, chủ doanh nghiệp nhỏ, trưởng bộ phận bán hàng hoặc chăm sóc khách hàng trong doanh nghiệp nhỏ.

**Bối cảnh sử dụng**: Người dùng muốn giảm tải tư vấn bán hàng và chăm sóc khách hàng lặp lại, không bỏ sót tin nhắn ngoài giờ và chuẩn hóa cách trả lời về sản phẩm, dịch vụ, chính sách thanh toán, vận chuyển hoặc bảo hành.

**Trình độ kỹ thuật**: Người dùng phổ thông đến trung bình, quen sử dụng phần mềm quản trị hoặc công cụ chat, nhưng không có kỹ năng lập trình hay huấn luyện mô hình AI chuyên sâu.

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Tạo AI Agent tư vấn đầu tiên (Ưu tiên: P1)

Người quản trị khai báo tên agent, vai trò, giọng điệu, thông tin tổ chức và phạm vi nhiệm vụ để tạo một nhân sự AI có danh tính rõ ràng trước khi đưa vào huấn luyện.

**Lý do ưu tiên**: Đây là điểm bắt đầu của toàn bộ sản phẩm; không có agent thì không thể nạp tri thức, chạy thử hoặc phát hành.

**Test độc lập**: Tạo mới một agent từ trạng thái chưa có dữ liệu và kiểm tra agent xuất hiện trong danh sách với đầy đủ thông tin nhận diện, trạng thái bản nháp và phạm vi hoạt động.

**Acceptance Scenarios**:

1. **Cho trước** người quản trị chưa có agent nào, **Khi** nhập đủ thông tin bắt buộc và xác nhận tạo, **Thì** hệ thống tạo agent ở trạng thái bản nháp.
2. **Cho trước** người quản trị nhập thiếu vai trò hoặc phạm vi trả lời, **Khi** xác nhận tạo, **Thì** hệ thống yêu cầu bổ sung thông tin còn thiếu trước khi lưu.

---

### Kịch bản 2 — Huấn luyện agent bằng tri thức tổ chức (Ưu tiên: P1)

Người vận hành nạp bộ câu hỏi thường gặp, mô tả sản phẩm/dịch vụ, giá, khuyến mại, chính sách giao hàng, thanh toán và bảo hành để agent có nguồn tri thức bán hàng trả lời khách hàng theo đúng thông tin của tổ chức.

**Lý do ưu tiên**: Giá trị cốt lõi của nền tảng nằm ở khả năng trả lời đúng theo tri thức riêng, không chỉ trả lời chung chung.

**Test độc lập**: Nạp một bộ tri thức bán hàng mẫu, đặt câu hỏi liên quan trực tiếp đến sản phẩm/dịch vụ, giá, khuyến mại, giao hàng, thanh toán và bảo hành, sau đó kiểm tra agent trả lời đúng nội dung, đồng thời từ chối hoặc chuyển hướng các câu ngoài phạm vi.

**Acceptance Scenarios**:

1. **Cho trước** agent ở trạng thái bản nháp, **Khi** người vận hành nạp tri thức hợp lệ, **Thì** hệ thống ghi nhận nguồn tri thức và đánh dấu agent đã sẵn sàng chạy thử.
2. **Cho trước** câu hỏi nằm ngoài phạm vi tri thức đã nạp, **Khi** chạy thử hội thoại, **Thì** agent không bịa thông tin và đề xuất chuyển cho người phụ trách.

---

### Kịch bản 3 — Chạy thử và phát hành agent (Ưu tiên: P2)

Người vận hành trò chuyện thử với agent, xem câu trả lời, chỉnh sửa tri thức hoặc hướng dẫn trả lời, sau đó phát hành agent lên website chat.

**Lý do ưu tiên**: Chạy thử giúp giảm rủi ro trả lời sai trước khi agent tiếp xúc với khách hàng thật; phát hành là bước đưa giá trị vào vận hành.

**Test độc lập**: Với một agent đã có tri thức, chạy thử ít nhất 10 câu hỏi mẫu, chỉnh sửa một câu trả lời chưa đạt, sau đó phát hành lên website chat và xác nhận trạng thái hoạt động.

**Acceptance Scenarios**:

1. **Cho trước** agent đã có tri thức, **Khi** người vận hành chạy thử bộ câu hỏi mẫu, **Thì** hệ thống hiển thị câu trả lời, nguồn tri thức liên quan và trạng thái đạt/chưa đạt do người dùng đánh dấu.
2. **Cho trước** agent đã vượt qua kiểm thử tối thiểu, **Khi** người vận hành phát hành, **Thì** agent chuyển sang trạng thái đang hoạt động trên kênh đã chọn.

---

### Kịch bản 4 — Theo dõi hiệu quả và cải thiện tri thức (Ưu tiên: P3)

Người quản trị xem thống kê hội thoại, tỷ lệ câu hỏi agent trả lời được, danh sách câu hỏi chưa có tri thức phù hợp và phản hồi của người dùng cuối để ưu tiên bổ sung tri thức.

**Lý do ưu tiên**: Sau khi phát hành, tổ chức cần biết agent có tạo giá trị thực tế hay không và cần cải thiện ở đâu.

**Test độc lập**: Tạo dữ liệu hội thoại mẫu gồm câu trả lời thành công và chưa trả lời được, sau đó kiểm tra báo cáo hiển thị đúng các chỉ số và danh sách cần cải thiện.

**Acceptance Scenarios**:

1. **Cho trước** agent đã có hội thoại phát sinh, **Khi** người quản trị mở báo cáo, **Thì** hệ thống hiển thị số hội thoại, tỷ lệ trả lời được và danh sách câu hỏi chưa xử lý tốt.
2. **Cho trước** người quản trị có quyền xem chi tiết, **Khi** mở một hội thoại vận hành, **Thì** hệ thống hiển thị đầy đủ nội dung trao đổi giữa người dùng cuối và agent để phục vụ phân tích chất lượng.

---

### Trường hợp biên

- Điều gì xảy ra khi người dùng nạp tri thức trùng lặp hoặc mâu thuẫn? Hệ thống phải cảnh báo nội dung có khả năng trùng/mâu thuẫn để người vận hành xác nhận.
- Hệ thống xử lý thế nào khi agent nhận câu hỏi ngoài phạm vi? Agent phải thừa nhận chưa có đủ thông tin và đề xuất chuyển cho người phụ trách thay vì tự suy đoán.
- Điều gì xảy ra khi kênh phát hành bị ngắt kết nối? Hệ thống phải giữ agent ở trạng thái cần xử lý và không báo thành công giả.
- Điều gì xảy ra khi người dùng cuối gửi thông tin nhạy cảm? Hệ thống vẫn lưu đầy đủ hội thoại trong MVP, nhưng phải hạn chế hiển thị dữ liệu nhạy cảm trong báo cáo tổng hợp, chỉ cho người có quyền xem chi tiết và ghi nhận việc truy cập chi tiết.
- Điều gì xảy ra khi tri thức chưa đủ để phát hành? Hệ thống phải chặn phát hành và chỉ rõ các điều kiện còn thiếu.

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Hệ thống PHẢI cho phép người quản trị tạo, xem, sửa, lưu nháp và vô hiệu hóa AI Agent.
- **YC-002**: Hệ thống PHẢI cho phép khai báo danh tính agent gồm tên, vai trò, mô tả tổ chức, giọng điệu, phạm vi trả lời và quy tắc không được vi phạm.
- **YC-003**: Hệ thống PHẢI cho phép người vận hành nạp, xem, cập nhật và loại bỏ tri thức bán hàng, bao gồm câu hỏi thường gặp, mô tả sản phẩm/dịch vụ, giá, khuyến mại, giao hàng, thanh toán và bảo hành.
- **YC-004**: Hệ thống PHẢI phân biệt trạng thái agent tối thiểu gồm bản nháp, đã có tri thức, đang chạy thử, đang hoạt động và đã vô hiệu hóa.
- **YC-005**: Người dùng PHẢI có thể chạy thử hội thoại với agent trước khi phát hành.
- **YC-006**: Hệ thống PHẢI ghi nhận phản hồi đạt/chưa đạt cho từng câu trả lời trong quá trình chạy thử.
- **YC-007**: Hệ thống PHẢI chặn phát hành nếu agent chưa có danh tính đầy đủ, chưa có tri thức hoặc chưa hoàn tất kiểm thử tối thiểu.
- **YC-008**: Hệ thống PHẢI cho phép phát hành agent lên website chat trong phạm vi phiên bản đầu.
- **YC-009**: Hệ thống PHẢI ghi nhận lịch sử thay đổi quan trọng của agent gồm tạo mới, cập nhật tri thức, chạy thử, phát hành và vô hiệu hóa.
- **YC-010**: Hệ thống PHẢI hiển thị báo cáo cơ bản gồm số hội thoại, số câu hỏi trả lời được, số câu hỏi cần bổ sung tri thức và phản hồi chất lượng.
- **YC-011**: Hệ thống KHÔNG ĐƯỢC để agent trả lời khẳng định khi câu hỏi nằm ngoài phạm vi tri thức hoặc quy tắc đã cấu hình.
- **YC-012**: Hệ thống PHẢI cho phép phân quyền tối thiểu giữa người quản trị agent, người vận hành tri thức và người chỉ xem báo cáo.
- **YC-013**: Hệ thống PHẢI lưu đầy đủ nội dung hội thoại giữa người dùng cuối và agent trong MVP để phục vụ phân tích chất lượng, truy vết câu trả lời và cải thiện tri thức.
- **YC-014**: Hệ thống PHẢI giới hạn quyền xem chi tiết hội thoại đầy đủ cho người dùng có quyền phù hợp và ghi nhận truy cập chi tiết hội thoại.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Người dùng phổ thông phải hoàn thành luồng tạo agent bản nháp trong tối đa 10 phút khi đã có sẵn thông tin tổ chức.
- **YCPCK-002**: Ít nhất 90% lượt thao tác trong luồng tạo, huấn luyện và chạy thử phải có phản hồi trạng thái rõ ràng trong vòng 3 giây theo cảm nhận người dùng.
- **YCPCK-003**: Hệ thống phải bảo vệ dữ liệu tri thức và hội thoại đầy đủ để chỉ người có quyền mới được xem, sửa hoặc phát hành agent.
- **YCPCK-004**: Mọi câu trả lời trong chế độ chạy thử và vận hành phải có khả năng truy vết về nguồn tri thức hoặc lý do không trả lời.
- **YCPCK-005**: Hệ thống phải lưu lịch sử thay đổi quan trọng và hội thoại đầy đủ tối thiểu 90 ngày để phục vụ kiểm tra vận hành, phân tích chất lượng và cải thiện tri thức.
- **YCPCK-006**: Giao diện chính phải sử dụng được trên trình duyệt desktop phổ biến và không yêu cầu người dùng cài đặt công cụ kỹ thuật riêng.

---

## 6. Thực thể dữ liệu

- **AI Agent**: Nhân sự AI được tổ chức tạo ra, gồm danh tính, vai trò, giọng điệu, phạm vi trả lời, trạng thái và kênh phát hành.
- **Nguồn tri thức**: Bộ thông tin dùng để agent trả lời, gồm câu hỏi thường gặp, mô tả sản phẩm/dịch vụ, giá, khuyến mại, giao hàng, thanh toán, bảo hành và tài liệu hướng dẫn bán hàng.
- **Phiên chạy thử**: Lần người vận hành trò chuyện thử với agent, gồm câu hỏi, câu trả lời, đánh giá đạt/chưa đạt và ghi chú cải thiện.
- **Kênh phát hành**: Nơi agent được đưa vào sử dụng; trong phiên bản base là website chat do tổ chức kiểm soát.
- **Hội thoại vận hành**: Cuộc trao đổi đầy đủ giữa người dùng cuối và agent sau khi phát hành, dùng để theo dõi hiệu quả, truy vết câu trả lời và phát hiện thiếu hụt tri thức.
- **Người dùng hệ thống**: Cá nhân có quyền tạo, huấn luyện, phát hành hoặc xem báo cáo agent.
- **Nhật ký thay đổi**: Bản ghi các hành động quan trọng trên agent để phục vụ truy vết và kiểm soát.

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: 90% người dùng thử nghiệm hoàn thành tạo agent bản nháp đầu tiên trong dưới 10 phút mà không cần hỗ trợ kỹ thuật.
- **TC-002**: Agent trả lời đúng tối thiểu 80% câu hỏi bán hàng thường gặp thuộc bộ kiểm thử đã được nạp tri thức.
- **TC-003**: 95% câu hỏi ngoài phạm vi trong bộ kiểm thử được agent từ chối hoặc chuyển hướng phù hợp thay vì bịa câu trả lời.
- **TC-004**: Người vận hành có thể phát hành agent lên website chat trong dưới 5 phút sau khi agent đạt điều kiện kiểm thử.
- **TC-005**: Báo cáo cơ bản giúp người quản trị xác định tối thiểu 10 câu hỏi thiếu tri thức phổ biến nhất sau mỗi chu kỳ vận hành.
- **TC-006**: Sau 30 ngày thử nghiệm, tổ chức giảm ít nhất 30% lượng câu hỏi lặp lại cần nhân sự trả lời thủ công trong phạm vi đã huấn luyện.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Phiên bản base ưu tiên hộ kinh doanh/doanh nghiệp nhỏ với bài toán tư vấn, hỏi đáp và hỗ trợ bán hàng/chăm sóc khách hàng trước các nghiệp vụ chuyên sâu.
- Người dùng đã có sẵn tri thức bán hàng cơ bản của tổ chức như câu hỏi thường gặp, danh mục sản phẩm/dịch vụ, giá, khuyến mại, chính sách giao hàng, thanh toán và bảo hành.
- Kênh phát hành đầu tiên là website chat do tổ chức kiểm soát; mở rộng đa kênh sẽ nằm ở phase sau.
- Agent không thay thế hoàn toàn con người trong các tình huống cần quyết định nghiệp vụ, cam kết tài chính, pháp lý hoặc xử lý khiếu nại phức tạp.
- Dữ liệu mẫu và hội thoại thử nghiệm có thể được dùng để đo chất lượng trước khi phát hành.

**Ràng buộc**:
- Spec này chỉ mô tả WHAT và WHY, chưa quyết định công nghệ, mô hình AI, cách tích hợp hay nhà cung cấp hạ tầng.
- Hệ thống phải thiết kế theo hướng người dùng không kỹ thuật có thể tự vận hành các bước cơ bản.
- Mọi dữ liệu tri thức, hội thoại và phân quyền phải được xem là dữ liệu nhạy cảm của tổ chức.
- MVP lưu đầy đủ nội dung hội thoại khách hàng trong 90 ngày để phục vụ phân tích chất lượng; quyền xem chi tiết phải được kiểm soát chặt.
- Phạm vi base không bao gồm xây dựng đầy đủ mọi năng lực nâng cao ngay từ đầu; chỉ lấy vòng đời cốt lõi của agent làm nền.

---

## 9. Ngoài phạm vi

- Không bao gồm marketplace mẫu agent theo ngành trong phiên bản base.
- Không bao gồm tự động hóa nghiệp vụ chuyên sâu như kế toán, nhân sự, sản xuất, tài sản công hoặc quy trình hành chính công.
- Không bao gồm tích hợp đầy đủ mọi kênh như Zalo, Facebook, robot, sàn thương mại điện tử hoặc hệ thống tổng đài.
- Không bao gồm xây dựng mô hình AI riêng, huấn luyện mô hình nền hoặc tối ưu hạ tầng AI cấp thấp.
- Không bao gồm thanh toán, báo giá thương mại, quản lý gói dịch vụ hoặc billing.
- Không bao gồm cam kết tuân thủ tiêu chuẩn bảo mật cụ thể trước khi phase plan xác định yêu cầu tổ chức và thị trường mục tiêu.

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Người dùng kỳ vọng hệ thống có đầy đủ năng lực nâng cao ngay từ đầu | Cao | Cao | Ghi rõ phạm vi base, ưu tiên vòng đời agent cốt lõi và đưa nghiệp vụ chuyên sâu ra ngoài phạm vi |
| Tri thức nạp vào thiếu, sai hoặc mâu thuẫn làm agent trả lời không đạt | Cao | Cao | Bắt buộc chạy thử, cảnh báo mâu thuẫn, đo câu hỏi chưa trả lời được và yêu cầu duyệt trước phát hành |
| Agent bịa thông tin khi không có tri thức phù hợp | Trung | Cao | Yêu cầu agent từ chối hoặc chuyển hướng khi ngoài phạm vi, đồng thời truy vết nguồn câu trả lời |
| Người dùng không kỹ thuật gặp khó khi cấu hình agent | Trung | Trung | Thiết kế luồng từng bước, dùng ngôn ngữ nghiệp vụ và có trạng thái hoàn thành rõ ràng |
| Dữ liệu hội thoại đầy đủ chứa thông tin nhạy cảm | Trung | Cao | Phân quyền xem chi tiết hội thoại, hạn chế hiển thị thông tin nhạy cảm trong báo cáo tổng hợp và lưu nhật ký truy cập quan trọng |

---

## 11. Phụ thuộc

- Thị trường mục tiêu ban đầu là hộ kinh doanh/doanh nghiệp nhỏ, vì nhóm này có nhu cầu tư vấn lặp lại rõ, dữ liệu tri thức mẫu dễ chuẩn hóa và scope MVP gọn.
- Kênh phát hành đầu tiên đã được giới hạn là website chat để giảm phụ thuộc nền tảng bên ngoài trong MVP.
- Bộ tri thức mẫu và bộ câu hỏi kiểm thử ban đầu ưu tiên use case bán hàng cho hộ kinh doanh/doanh nghiệp nhỏ.
- Cần quyết định vai trò người dùng tối thiểu và quyền tương ứng trước khi plan.
- Cần quy định nguyên tắc xử lý dữ liệu nhạy cảm trong hội thoại trước khi triển khai thử nghiệm với khách hàng thật.

---

## 12. Câu hỏi mở

- Không còn câu hỏi mở trọng yếu trước phase plan.
