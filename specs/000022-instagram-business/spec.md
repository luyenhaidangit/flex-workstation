# Đặc tả tính năng: Phát hành AI Agent trên Instagram Business

**Branch**: `000022-instagram-business`  
**Ngày tạo**: 2026-07-29  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Bổ sung kênh "Instagram Business" vào Customer Studio để AI Agent có thể tự động trả lời DM, bình luận và mention trên Instagram — tương tự luồng Fanpage Facebook đang có.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Hiện tại Agentwork hỗ trợ phát hành AI Agent lên Fanpage Facebook và Messenger, nhưng chưa có kênh Instagram. Người bán hàng thường quản lý cả Facebook lẫn Instagram đồng thời — khách hàng tương tác qua DM và bình luận Instagram ngày càng nhiều. Việc phải tự trả lời thủ công gây tốn thời gian và bỏ sót tin nhắn ngoài giờ làm việc. Kết quả: khách hàng chờ lâu, tỷ lệ chuyển đổi thấp hơn so với kênh Facebook đã có agent.

**Tổng quan tính năng**:

Bổ sung kênh phát hành "Instagram Business" trong Customer Studio, cho phép AI Agent kết nối với tài khoản Instagram Business/Creator đã liên kết Facebook Page và tự động phản hồi DM, bình luận bài viết và mention. Tính năng này mở rộng khả năng tự động hóa của Agentwork sang kênh Instagram mà không thay đổi cơ chế vận hành agent hiện có.

---

## 2. Mục tiêu

- **MT-001**: Người dùng có thể phát hành AI Agent lên Instagram Business thông qua giao diện Customer Studio (không cần tích hợp thủ công).
- **MT-002**: AI Agent tự động trả lời DM, bình luận và mention trên Instagram theo cấu hình của người dùng.
- **MT-003**: Nhóm kỹ thuật hiểu rõ luồng tích hợp Instagram (OAuth, webhook, permission) qua việc xây dựng tính năng tối thiểu này.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Kênh "Instagram Business" xuất hiện trong danh sách kênh phát hành của Customer Studio; người dùng kết nối tài khoản Instagram qua luồng 3 bước.
- **MVP-002**: AI Agent nhận và trả lời DM trên Instagram sau khi phát hành thành công.
- **MVP-003**: Người dùng có thể xem trạng thái kết nối, ngắt kết nối và cấu hình giờ hoạt động cho kênh Instagram.
- **MVP-004**: Phạm vi chỉ áp dụng cho tài khoản Instagram Business hoặc Creator đã liên kết với ít nhất 1 Fanpage Facebook — tài khoản cá nhân không được hỗ trợ.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người quản lý fanpage bán hàng — cá nhân hoặc doanh nghiệp nhỏ có tài khoản Instagram Business/Creator (ví dụ: chủ tiệm nail, cửa hàng thời trang, dịch vụ đặt lịch).

**Bối cảnh sử dụng**: Người dùng đã có AI Agent hoạt động trên Facebook/Messenger, muốn mở rộng sang Instagram để tự động hóa phản hồi mà không cần ngồi canh điện thoại. Thao tác thực hiện trên giao diện web Customer Studio.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ — không có kiến thức kỹ thuật, quen với luồng kết nối mạng xã hội qua nút "Đăng nhập".

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Kết nối Instagram Business và phát hành agent (Ưu tiên: P1)

Chị Nhi (chủ tiệm nail) vào Customer Studio, chọn agent đã tạo, bấm "Thêm kênh phát hành", chọn "Instagram Business", thực hiện 3 bước: đăng nhập Instagram → cấp quyền cho AI quản lý tin nhắn → bấm "Phát hành". Hệ thống hiển thị popup xác nhận thành công, kênh Instagram xuất hiện trong danh sách kênh đang hoạt động.

**Lý do ưu tiên**: Đây là luồng chính tạo giá trị — không có bước này thì agent không hoạt động trên Instagram.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Có thể test với tài khoản Instagram Business thật mà không cần agent Facebook đang chạy.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng đang ở màn hình chọn kênh phát hành của agent, **Khi** chọn "Instagram Business", **Thì** hệ thống hiển thị luồng 3 bước kết nối với hướng dẫn text tùy chỉnh được.
2. **AC-002**: **Cho trước** người dùng hoàn thành bước đăng nhập Instagram và cấp quyền, **Khi** bấm "Phát hành", **Thì** hệ thống xác thực tài khoản và hiện popup kết quả (hợp lệ hoặc không hợp lệ).
3. **AC-003**: **Cho trước** kết nối hợp lệ (tài khoản Business/Creator + liên kết Facebook Page), **Khi** popup hiện ra, **Thì** trạng thái kênh chuyển sang "Đang hoạt động" và agent bắt đầu nhận DM.
4. **AC-004**: **Cho trước** tài khoản Instagram là tài khoản cá nhân (không phải Business/Creator), **Khi** hoàn thành luồng kết nối, **Thì** popup hiện thông báo không hợp lệ kèm hướng dẫn điều kiện tài khoản — agent không được phát hành.

---

### US-002 — AI Agent tự động trả lời DM Instagram (Ưu tiên: P1)

Sau khi phát hành, khách hàng nhắn DM cho trang Instagram của chị Nhi. AI Agent nhận tin nhắn và trả lời tự động theo cấu hình đã thiết lập, trong giờ hoạt động đã cài đặt.

**Lý do ưu tiên**: Đây là giá trị cốt lõi — tự động hóa phản hồi DM.

**Liên quan yêu cầu**: FR-005, FR-006

**Test độc lập**: Có thể test bằng cách gửi DM từ tài khoản khác đến trang Instagram đã kết nối.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** agent đã phát hành và đang trong giờ hoạt động, **Khi** có DM mới từ khách, **Thì** agent trả lời trong vòng 60 giây.
2. **AC-006**: **Cho trước** agent đang ngoài giờ hoạt động, **Khi** có DM mới, **Thì** agent không tự động trả lời (hoặc gửi tin nhắn ngoài giờ nếu được cấu hình).

---

### US-003 — Quản lý trạng thái kênh Instagram (Ưu tiên: P2)

Người dùng vào màn hình quản lý kênh, xem trạng thái kênh Instagram, ngắt kết nối khi cần (ví dụ: đổi tài khoản), hoặc thêm tài khoản/trang IG khác.

**Lý do ưu tiên**: Cần thiết để vận hành, nhưng không chặn luồng P1.

**Liên quan yêu cầu**: FR-007, FR-008

**Test độc lập**: Có thể test sau khi có ít nhất 1 kênh Instagram đã kết nối.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** kênh Instagram đang hoạt động, **Khi** người dùng bấm "Ngắt kết nối", **Thì** agent dừng nhận/trả lời DM Instagram và trạng thái kênh về "Chưa kết nối".
2. **AC-008**: **Cho trước** đã có 1 kênh Instagram kết nối, **Khi** người dùng bấm "Thêm tài khoản/trang khác", **Thì** hệ thống mở lại luồng 3 bước để thêm tài khoản/trang IG mới.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Kênh Instagram chưa có kết nối nào — hiển thị trạng thái "Chưa kết nối" và nút "Kết nối Instagram".
- **Dữ liệu không hợp lệ**: Tài khoản Instagram không phải Business/Creator hoặc chưa liên kết Facebook Page — popup thông báo lỗi cụ thể kèm hướng dẫn điều kiện.
- **Không có quyền**: Người dùng không cấp đủ quyền (permission) cho ứng dụng trong bước 2 — hệ thống yêu cầu thực hiện lại bước cấp quyền.
- **Lỗi hệ thống**: Kết nối Meta API thất bại trong quá trình xác thực — hiện thông báo lỗi chung, cho phép thử lại.
- **Timeout**: Người dùng không hoàn thành luồng đăng nhập Instagram trong thời gian cho phép — phiên kết nối hết hạn, cần bắt đầu lại.
- **Dữ liệu bị thay đổi bởi người khác**: Tài khoản Instagram bị hủy liên kết Facebook Page sau khi đã kết nối — agent ngừng hoạt động, trạng thái kênh chuyển sang "Lỗi kết nối", thông báo người dùng.
- **Người dùng thao tác lặp lại**: Người dùng bấm "Phát hành" nhiều lần — hệ thống chỉ tạo 1 kết nối, bỏ qua các lần bấm trùng.
- **Ngoài cửa sổ 24 giờ Instagram**: Khách hàng đã nhắn DM nhưng đã hơn 24 giờ trôi qua kể từ tin cuối — agent bỏ qua, không gửi trả lời tự động, không thông báo lỗi đến khách.
- **Trường hợp biên khác**: Một hoặc nhiều Facebook Page trong danh sách OAuth trả về đã được kết nối với agent khác — popup "Kết quả kết nối" phân thành 2 tab: (1) tab "Hợp lệ" hiển thị các page có thể kết nối với trạng thái "Đang kết nối" / "Chưa kết nối"; (2) tab "Không hợp lệ" liệt kê các page đã bị agent khác chiếm, hiển thị tên agent đang giữ kết nối và không cho phép chọn.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI hiển thị kênh "Instagram Business" trong danh sách kênh phát hành với tên cố định "Instagram Business", mô tả tùy chỉnh được và cảnh báo điều kiện tài khoản.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI cung cấp luồng kết nối 3 bước (đăng nhập Instagram → cấp quyền → phát hành) với text hướng dẫn từng bước có thể tùy chỉnh.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Sau khi người dùng hoàn thành luồng kết nối, hệ thống PHẢI xác thực tài khoản Instagram (kiểm tra loại tài khoản Business/Creator và liên kết Facebook Page) và hiển thị popup kết quả hợp lệ/không hợp lệ.  
  **Liên quan**: US-001, AC-002, AC-003, AC-004
- **FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC kích hoạt agent trên Instagram nếu tài khoản không đáp ứng điều kiện (Business/Creator + liên kết Facebook Page).  
  **Liên quan**: US-001, AC-004
- **FR-005** `[P1]`: Khi agent được phát hành thành công, hệ thống PHẢI nhận DM gửi đến tài khoản Instagram đã kết nối và chuyển cho AI Agent xử lý.  
  **Liên quan**: US-002, AC-005
- **FR-006** `[P1]`: Hệ thống PHẢI tôn trọng cấu hình giờ hoạt động — chỉ agent tự động trả lời trong khung giờ đã thiết lập.  
  **Liên quan**: US-002, AC-006
- **FR-007** `[P2]`: Người dùng PHẢI có thể ngắt kết nối kênh Instagram bất kỳ lúc nào; sau khi ngắt, agent dừng nhận/gửi tin nhắn qua kênh này.  
  **Liên quan**: US-003, AC-007
- **FR-008a** `[P2]`: Người dùng PHẢI có thể **thêm trang** ("+Thêm trang") trong cùng tài khoản Meta đã kết nối — mở lại popup "Kết quả kết nối" để chọn page khác trong account hiện tại.  
  **Liên quan**: US-003, AC-008
- **FR-008b** `[P2]`: Người dùng PHẢI có thể **thêm tài khoản** ("+Thêm tài khoản") — khởi động lại luồng OAuth với tài khoản Meta khác, trả về danh sách pages mới.  
  **Liên quan**: US-003, AC-008
- **FR-009** `[P3]`: Hệ thống PHẢI phát hiện và thông báo người dùng khi kết nối Instagram bị gián đoạn (tài khoản hủy liên kết Facebook Page, thu hồi quyền...) và cập nhật trạng thái kênh tương ứng.  
  **Liên quan**: §6 Dữ liệu bị thay đổi bởi người khác
- **FR-010** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép 1 Facebook Page kết nối đồng thời với nhiều agent — nếu page đó đã được agent khác sử dụng, popup "Kết quả kết nối" phải hiển thị page đó trong tab "Không hợp lệ" kèm tên agent đang giữ kết nối.  
  **Liên quan**: §6 Trường hợp biên khác, BR-005

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Tài khoản Instagram phải là loại **Business hoặc Creator** — tài khoản cá nhân không được kết nối.
- **BR-002**: Tài khoản Instagram phải đã **liên kết với ít nhất 1 Fanpage Facebook** trước khi kết nối agent.
- **BR-003**: Kết nối Instagram sử dụng cùng hệ sinh thái OAuth Meta như Fanpage Facebook — người dùng đăng nhập qua Facebook Business Suite hoặc Meta Developer flow.
- **BR-004**: Tên kênh "Instagram Business" là cố định, không cho phép người dùng đổi tên.
- **BR-005**: Một **Facebook Page** (liên kết Instagram) chỉ được kết nối với **1 agent tại 1 thời điểm** — nhiều tài khoản Meta khác nhau (mỗi người quản lý nhiều page riêng) đều có thể kết nối vào cùng 1 agent; ràng buộc là ở cấp page, không phải cấp tài khoản Meta.
- **BR-006**: Agent chỉ được phép gửi tin nhắn trả lời trong **cửa sổ 24 giờ** kể từ tin nhắn cuối cùng của khách hàng (Instagram Messaging Window). Ngoài cửa sổ này, agent KHÔNG ĐƯỢC tự động gửi tin — không báo lỗi với khách, không gửi tin chào hỏi chủ động.

**Luồng trạng thái kênh Instagram**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa kết nối | Hoàn thành luồng 3 bước + xác thực hợp lệ | Đang hoạt động | Tài khoản Business/Creator + liên kết Facebook Page |
| Chưa kết nối | Hoàn thành luồng + xác thực không hợp lệ | Chưa kết nối (popup lỗi) | Tài khoản không đủ điều kiện |
| Đang hoạt động | Ngắt kết nối | Chưa kết nối | Người dùng chủ động |
| Đang hoạt động | Token bị thu hồi / liên kết IG-Page bị hủy | Lỗi kết nối | Phát hiện qua webhook hoặc polling |
| Lỗi kết nối | Kết nối lại | Đang hoạt động | Sau khi xác thực lại thành công |

---

## 9. Thực thể dữ liệu

- **MetaAccountConnection**: Đại diện cho 1 tài khoản Meta (người dùng Facebook Business) đã thực hiện OAuth với agent. Ghi nhận: tên tài khoản Meta, avatar, token truy cập (mã hóa), danh sách pages được ủy quyền.
- **InstagramPageConnection**: Đại diện cho 1 Facebook Page (liên kết Instagram) thuộc 1 MetaAccountConnection, đã được kích hoạt kết nối với agent. Ghi nhận: tên page, ID page, ID Instagram Business liên kết, trạng thái kết nối, giờ hoạt động. Ràng buộc: 1 page chỉ thuộc 1 agent (BR-005).
- **ChannelMessage (Instagram)**: Tin nhắn DM nhận được từ Instagram, được route vào luồng xử lý chung của agent như các kênh khác. Không cần thực thể riêng nếu tái sử dụng model ChannelMessage hiện có.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người quản lý agent (owner/admin của workspace) được xem danh sách kênh Instagram đã kết nối.

**Ai được thao tác**:
- Người quản lý agent (owner/admin) được kết nối, ngắt kết nối và cấu hình kênh Instagram.

**Ai không được phép**:
- Thành viên chỉ xem (viewer role) không được kết nối hoặc ngắt kết nối kênh.
- Agent không được truy cập DM của tài khoản Instagram ngoài scope đã được cấp quyền.

**Dữ liệu nhạy cảm**:
- Có. Token truy cập Instagram (OAuth access token) là dữ liệu nhạy cảm — phải được lưu trữ mã hóa, không hiển thị trực tiếp ra giao diện người dùng.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền người dùng (owner/admin) trước khi cho phép kết nối hoặc ngắt kết nối kênh Instagram.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập token Instagram của workspace khác.
- **SEC-003**: Token truy cập Instagram PHẢI được lưu mã hóa — không lưu plaintext trong database hoặc log.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có

Hệ thống PHẢI ghi nhận:
- Ai thực hiện kết nối / ngắt kết nối kênh Instagram
- Thời điểm thực hiện
- Tài khoản/trang Instagram nào bị ảnh hưởng
- Trạng thái trước và sau thao tác

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Luồng kết nối 3 bước (từ khi bấm "Kết nối" đến khi hiện popup kết quả) hoàn thành trong vòng 30 giây trong điều kiện kết nối internet bình thường.
- **NFR-002**: Tính năng không làm gián đoạn các kênh phát hành đang hoạt động (Facebook, Messenger) khi được thêm vào.
- **NFR-003**: Trạng thái kênh Instagram được cập nhật trong vòng 5 phút khi có thay đổi từ phía Meta (token hết hạn, thu hồi quyền).

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Người dùng hoàn thành luồng kết nối Instagram Business (3 bước) và phát hành agent thành công trong dưới 5 phút kể từ lần đầu thử.
- **SC-002**: AI Agent trả lời DM Instagram trong vòng 60 giây sau khi khách gửi tin, ở tỷ lệ thành công ≥ 95% trong điều kiện vận hành bình thường.
- **SC-003**: Nhóm kỹ thuật có thể mô tả đầy đủ luồng OAuth Meta và webhook Instagram sau khi hoàn thành tính năng MVP này (mục tiêu học hỏi).

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Người dùng đã có tài khoản Instagram Business/Creator và đã liên kết với Facebook Page trước khi sử dụng tính năng này.
- Hệ thống Meta (Instagram Graph API, Webhooks) hoạt động ổn định và có thể tích hợp được theo cùng pattern với Fanpage Facebook hiện có.
- Luồng OAuth Instagram dùng lại cơ chế xác thực Meta đang có (không cần xây dựng từ đầu).
- Quyền `instagram_manage_messages` và `pages_messaging` đã được Meta phê duyệt cho ứng dụng hiện tại — không phát sinh thời gian chờ App Review.
- Mobile không nằm trong phạm vi MVP — chỉ hỗ trợ giao diện web Customer Studio.

**Ràng buộc**:
- Tính năng phải tuân thủ [Meta Platform Policy](https://developers.facebook.com/policy/) về quyền truy cập tin nhắn Instagram.
- Tài khoản Instagram phải là Business hoặc Creator — đây là ràng buộc từ Instagram Graph API, không thể bỏ qua.
- Instagram Business phải liên kết với Facebook Page — ràng buộc bắt buộc của Meta API để truy cập Instagram Messaging API.
- Agent chỉ được gửi tin trong cửa sổ 24 giờ kể từ tin nhắn cuối của khách (Instagram Messaging Window) — ràng buộc của Meta, không thể bỏ qua (BR-006).

---

## 15. Ngoài phạm vi

- Trả lời bình luận bài viết và mention (comment/mention reply) — không nằm trong MVP, chỉ tập trung DM. UI toggle "Trả lời bình luận trên bài viết" có thể hiển thị nhưng ở trạng thái disabled hoặc chưa active.
- Gửi tin nhắn chủ động proactive (khi khách bình luận → agent tự DM) — không nằm trong MVP. Modal "Thiết lập trả lời bình luận" được thiết kế sẵn nhưng chưa implement trong MVP.
- Thống kê phiên chat theo kênh Instagram trong màn hình Hội thoại — không nằm trong MVP.
- Bộ lọc kênh trong màn hình Hội thoại — không nằm trong MVP.
- Cập nhật template agent đã thi công để hiển thị kênh IG — không nằm trong MVP.
- Hỗ trợ tài khoản Instagram cá nhân.
- Quản lý nội dung bài viết Instagram (đăng bài, lên lịch).

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Meta thay đổi chính sách quyền Instagram Messaging API trong quá trình phát triển | Thấp | Cao | Theo dõi Meta Developer Changelog; thiết kế permission scope linh hoạt |
| Luồng OAuth Instagram khác biệt đáng kể so với Facebook Page (thêm bước, scope khác) | Trung | Trung | Nghiên cứu kỹ Instagram Graph API trước khi bắt đầu plan kỹ thuật |
| Token truy cập Instagram hết hạn sớm hơn dự kiến gây gián đoạn agent | Trung | Cao | Xây dựng cơ chế refresh token tự động; monitor trạng thái token |
| Tài khoản test không đủ điều kiện (Business/Creator) trong giai đoạn phát triển | Trung | Trung | Chuẩn bị tài khoản test hợp lệ ngay từ đầu sprint |

---

## 17. Phụ thuộc

- Meta/Instagram Graph API: cần quyền `instagram_manage_messages` và `pages_messaging` — đã được Meta phê duyệt cho ứng dụng hiện tại; không cần Meta App Review bổ sung.
- Hệ thống Fanpage Facebook/Messenger hiện có của Agentwork — tái sử dụng cơ chế OAuth Meta và luồng webhook.
- Quy tắc 1 tài khoản Instagram = 1 agent đã được xác nhận (BR-005); không cần quyết định thêm từ stakeholder.

---

## 18. Câu hỏi mở

- [ĐÃ LÀM RÕ → Clarifications / Session 2026-07-29]: Một tài khoản Instagram Business có được kết nối với nhiều AI Agent không? → Không, 1 tài khoản chỉ được kết nối với 1 agent tại 1 thời điểm (BR-005, FR-010).

---

## Clarifications

### Session 2026-07-29

- Q: Một tài khoản Instagram Business có được kết nối với nhiều AI Agent trong cùng hệ thống không? → A: Không — 1 tài khoản IG chỉ được kết nối với 1 agent tại 1 thời điểm; kết nối mới bị từ chối nếu tài khoản đang được agent khác sử dụng.
- Q: Quyền `instagram_manage_messages` đã được Meta phê duyệt cho ứng dụng hiện tại chưa? → A: Đã được phê duyệt — không cần Meta App Review bổ sung.
- Q: Instagram DM có ràng buộc cửa sổ 24 giờ — agent xử lý thế nào khi ngoài cửa sổ? → A: Ghi nhận là ràng buộc bắt buộc; agent bỏ qua, không gửi và không báo lỗi với khách (BR-006).
- Design review (2026-07-29): BR-005 được đính chính từ "account-level" thành "page-level" theo design — nhiều tài khoản Meta có thể kết nối cùng 1 agent, ràng buộc 1-to-1 là ở cấp Facebook Page (InstagramPageConnection). Data model bổ sung MetaAccountConnection + InstagramPageConnection. FR-008 tách thành FR-008a (thêm trang trong account cũ) và FR-008b (thêm tài khoản Meta mới). Popup "Kết quả kết nối" xác nhận cấu trúc 2 tab: Hợp lệ (checkbox chọn page) và Không hợp lệ (page đã bị agent khác giữ, hiện tên agent).

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
