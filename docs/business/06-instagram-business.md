# Nghiệp vụ MVP 000022 — Phát hành AI Agent trên Instagram Business

## Mục đích và phạm vi

Tài liệu này mô tả nghiệp vụ của tính năng bổ sung kênh **Instagram Business** vào Customer Studio, cho phép người bán hàng phát hành AI Agent để tự động trả lời tin nhắn trực tiếp (DM) từ khách hàng trên Instagram — tương tự kênh Facebook/Messenger đang có. MVP này tập trung vào luồng kết nối tài khoản và xử lý DM; việc trả lời bình luận bài viết và nhắn tin chủ động không nằm trong phạm vi. Đây là bước mở rộng kênh bán hàng tự động hóa của nền tảng Agentwork sang hệ sinh thái Instagram.

Tham chiếu đặc tả: `specs/000022-instagram-business/spec.md`

---

## Bối cảnh nghiệp vụ

Người bán hàng nhỏ (chủ tiệm nail, cửa hàng thời trang, dịch vụ đặt lịch...) thường vận hành đồng thời cả Facebook Page lẫn Instagram Business. Khách hàng ngày càng nhắn DM qua Instagram để hỏi giá, đặt lịch, xem mẫu — nhưng người bán không thể trực canh điện thoại suốt ngày. Với kênh Facebook đã có nhân viên AI trả lời tự động, nay người bán muốn nhân rộng khả năng này sang Instagram mà không cần nhân lực bổ sung.

**Vấn đề cốt lõi**: Tin nhắn Instagram đến ngoài giờ làm việc bị bỏ sót → khách chờ lâu → tỷ lệ chuyển đổi giảm.

**Giải pháp**: AI Agent được phát hành lên tài khoản Instagram Business của người bán, tự động nhận và trả lời DM theo nguyên tắc đã cấu hình, trong khung giờ hoạt động đã thiết lập.

**Điều kiện bắt buộc từ phía Meta** (không thể bỏ qua):
- Tài khoản Instagram phải là loại **Business hoặc Creator** (không phải cá nhân).
- Tài khoản đó phải đã **liên kết với ít nhất 1 Fanpage Facebook**.
- Kết nối thực hiện qua **hệ thống xác thực Meta** (cùng cơ chế với Facebook/Messenger).

---

## Vai trò trong luồng bán hàng thực tế

```text
[Người bán] ── quản lý ──> [Instagram Business] ── nhận DM từ ──> [Khách hàng]
                                    │
                            [AI Agent phát hành]  ← PHẠM VI MVP NÀY
                                    │
                            tự động trả lời DM
                            trong cửa sổ 24 giờ
```

| Vai trò | Trách nhiệm thực tế | Trong MVP này |
|---------|---------------------|---------------|
| Người quản lý fanpage (chủ shop) | Đăng ảnh/video sản phẩm, chốt đơn, tư vấn khách | Thực hiện kết nối kênh Instagram, cấu hình giờ hoạt động |
| AI Agent | Trả lời tự động theo nguyên tắc đã huấn luyện | Nhận DM → xử lý → trả lời trong 24 giờ kể từ tin cuối của khách |
| Khách hàng | Nhắn DM hỏi mẫu, đặt lịch, xem giá | Nhận phản hồi tự động từ AI Agent |
| Nền tảng Meta (Instagram) | Vận chuyển tin nhắn, kiểm soát quyền truy cập | Cổng kết nối; áp dụng giới hạn cửa sổ 24 giờ |

---

## Luồng nghiệp vụ đầu-cuối

### Phần A — Kết nối kênh (người bán thực hiện 1 lần)

1. Người bán vào Customer Studio → chọn agent → tab **Phát hành**.
2. Chọn kênh **Instagram Business** → đọc 3 bước hướng dẫn → bấm **"Kết nối ngay"**.
3. Đăng nhập tài khoản Facebook (chủ sở hữu Instagram Business) → cấp quyền cho AI quản lý tin nhắn.
4. Hệ thống kiểm tra từng trang Facebook được liên kết:
   - **Hợp lệ**: trang có Instagram Business/Creator liên kết và chưa được agent khác sử dụng → có thể chọn.
   - **Không hợp lệ**: trang đã được agent khác của hệ thống kết nối → hiển thị tên agent đang giữ, không cho phép chọn.
5. Người bán chọn trang muốn kích hoạt → bấm **"Xác nhận"**.
6. Kênh Instagram xuất hiện trong danh sách kết nối với trạng thái **"Đã phát hành"**.
7. *(Tùy chọn)* Người bán thiết lập giờ AI hoạt động (mặc định: cả ngày 24/7).

### Phần B — AI Agent xử lý DM (tự động, sau khi kết nối)

8. Khách hàng gửi DM đến trang Instagram của người bán.
9. Nền tảng Meta chuyển tin nhắn đến hệ thống Agentwork trong vòng vài giây.
10. Hệ thống kiểm tra:
    - Tin nhắn có trong **cửa sổ 24 giờ** kể từ DM cuối của khách không?
    - Có đang trong **giờ AI hoạt động** không?
11. Nếu đủ điều kiện → AI Agent xử lý và gửi phản hồi → khách nhận được trong vòng 60 giây.
12. Nếu ngoài cửa sổ 24 giờ → bỏ qua, không gửi tin, không thông báo khách.

### Phần C — Quản lý kết nối (khi cần)

13. Người bán có thể **ngắt kết nối** trang bất kỳ lúc nào → AI dừng trả lời DM từ trang đó.
14. Người bán có thể **thêm trang khác** trong cùng tài khoản Facebook hoặc **thêm tài khoản Facebook mới** để kết nối nhiều trang Instagram Business vào cùng 1 agent.

---

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|-----------|----------------------|
| **Tài khoản Meta** | Tài khoản Facebook của người bán, dùng để xác thực và lấy danh sách trang quản lý |
| **Kết nối trang Instagram** | Mối liên hệ giữa 1 Facebook Page (có Instagram Business) và 1 AI Agent — đây là đơn vị kích hoạt chính |
| **Cấu hình giờ hoạt động** | Khung giờ AI được phép tự động trả lời DM (mặc định 24/7) |
| **Tin nhắn DM** | Tin nhắn trực tiếp từ khách → được AI xử lý và trả lời nếu đủ điều kiện |

---

## Quy tắc nghiệp vụ

| Mã | Quy tắc | Lý do / Nguồn gốc |
|----|---------|------------------|
| BR-001 | Tài khoản Instagram phải là loại **Business hoặc Creator** | Meta chỉ cho phép truy cập API tin nhắn với loại tài khoản này; tài khoản cá nhân không có quyền |
| BR-002 | Tài khoản Instagram phải đã **liên kết với 1 Fanpage Facebook** | Kỹ thuật của Meta: Instagram Messaging API chỉ hoạt động qua Facebook Page — đây là ràng buộc bắt buộc từ nền tảng |
| BR-003 | Kết nối thực hiện qua **xác thực Meta** (đăng nhập Facebook) | Cùng hệ sinh thái OAuth với Facebook/Messenger — người bán dùng tài khoản Facebook để uỷ quyền |
| BR-004 | Tên kênh "**Instagram Business**" là cố định | Tránh nhầm lẫn khi người dùng cấu hình nhiều kênh; mô tả kênh có thể tùy chỉnh |
| BR-005 | **1 Facebook Page chỉ được kết nối với 1 AI Agent** tại cùng một thời điểm | Tránh nhiều agent cùng trả lời 1 khách, gây lộn xộn và spam; page thuộc agent nào phải rõ ràng |
| BR-006 | AI Agent chỉ được trả lời DM trong **cửa sổ 24 giờ** kể từ tin nhắn cuối của khách | Quy định bắt buộc của Instagram — nền tảng Meta áp dụng để chống spam; không thể bỏ qua |

---

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|-----------|---------------------------|
| Người bán kết nối tài khoản Instagram Business hợp lệ chưa có agent | Kết nối thành công, kênh "Đã phát hành", AI bắt đầu nhận DM |
| Người bán kết nối tài khoản Instagram cá nhân | Hệ thống không cho kết nối, thông báo rõ điều kiện tài khoản |
| Trang Instagram đã được agent *khác* kết nối | Trang xuất hiện trong danh sách "Không hợp lệ" kèm tên agent đang dùng; không thể chọn |
| Khách gửi DM trong giờ AI hoạt động, trong 24 giờ | AI trả lời trong vòng 60 giây |
| Khách gửi DM ngoài giờ AI hoạt động | AI không trả lời; tin nhắn chờ khi vào giờ (hoặc nhân viên thật xử lý) |
| Khách gửi DM lần cuối đã hơn 24 giờ | AI không trả lời; DM mới từ khách sẽ mở lại cửa sổ 24 giờ |
| Người bán thu hồi quyền ứng dụng trong Facebook | Kênh chuyển sang trạng thái "Lỗi kết nối"; người bán cần kết nối lại |
| Người bán ngắt kết nối trang | AI dừng xử lý DM từ trang đó ngay lập tức |
| Người bán bấm "Kết nối" nhiều lần liên tiếp | Hệ thống chỉ tạo 1 kết nối, bỏ qua các thao tác trùng lặp |

---

## Ngoài phạm vi

Những tính năng sau **không thuộc MVP này** và sẽ được xem xét trong các sprint tiếp theo:

- **Trả lời bình luận bài viết** — khi khách bình luận dưới post, AI không tự động trả lời trong MVP này.
- **Gửi DM chủ động** — AI không tự gửi tin nhắn khi khách bình luận (proactive messaging).
- **Thống kê phiên chat theo kênh Instagram** — màn hình Hội thoại chưa có bộ lọc và báo cáo riêng cho kênh này.
- **Cập nhật template agent** hiển thị kênh Instagram — các template đã thi công chưa được cập nhật trong MVP.
- **Hỗ trợ tài khoản Instagram cá nhân** — không hỗ trợ và không có kế hoạch, do giới hạn của Meta API.
- **Quản lý nội dung bài viết** (đăng bài, lên lịch) — ngoài phạm vi hoàn toàn.

---

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000022-instagram-business/spec.md): user stories, acceptance criteria, quy tắc nghiệp vụ đầy đủ và ràng buộc kỹ thuật.
- [Kế hoạch triển khai](../../specs/000022-instagram-business/plan.md): kiến trúc kỹ thuật, data model và API contract.
- [Meta Platform Policy](https://developers.facebook.com/policy/): chính sách sử dụng Instagram Messaging API — nguồn gốc các quy tắc BR-001, BR-002, BR-006.
