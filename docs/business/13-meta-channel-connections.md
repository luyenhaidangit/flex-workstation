# Nghiệp vụ MVP 13 — Kết nối kênh Instagram và Facebook qua Meta

## Mục đích và phạm vi

Tài liệu này mô tả nghiệp vụ kết nối tài khoản Instagram và trang Facebook mà người dùng đang quản lý với một AI Agent. MVP 13 chuẩn hóa phần xác thực, khám phá tài khoản/trang, lựa chọn, hoàn tất và ngắt kết nối; đây là nền tảng để agent có thể vận hành trên các kênh xã hội. MVP không bao gồm gửi tin nhắn, webhook, đăng bài hay kết nối các nhà cung cấp khác. Tham chiếu đặc tả: `specs/000041-meta-channel-connections/spec.md`.

## Bối cảnh nghiệp vụ

Một người bán hoặc doanh nghiệp nhỏ thường quản lý nhiều tài nguyên trên hệ sinh thái Meta: trang Facebook và tài khoản Instagram Business/Creator liên kết với trang đó. Khi muốn giao cho AI Agent hỗ trợ một kênh, người quản lý phải xác nhận đúng tài khoản, đúng quyền và đúng tài nguyên; nếu không, agent có thể bị gắn nhầm hoặc nhiều agent cùng xử lý một kênh.

Trong MVP này, Meta xác thực người quản lý và cung cấp danh sách tài nguyên mà họ có quyền quản lý. FlexSim ghi nhận lựa chọn đó thành một kết nối thuộc agent, đồng thời cho phép người quản lý thu hồi kết nối khi không còn nhu cầu.

```text
[Người quản lý agent]
        │ xác thực và cấp quyền
        ▼
[Nền tảng Meta]
        │ cung cấp tài khoản Instagram / trang Facebook hợp lệ
        ▼
[FlexSim] ── liên kết ──> [AI Agent]
```

## Vai trò trong thị trường thực tế

```text
[Người quản lý doanh nghiệp] → [Meta] → [Trang Facebook / Instagram Business] → [AI Agent]
                  └────────────── phạm vi MVP 13: xác thực và quản lý kết nối ──────────────┘
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Người quản lý agent | Chọn agent, xác thực tài khoản và quyết định tài nguyên nào được sử dụng | Bắt đầu, hoàn tất hoặc ngắt kết nối |
| Tài khoản Meta | Xác nhận danh tính và quyền quản lý của người dùng | Cung cấp quyền và danh sách tài nguyên có thể lựa chọn |
| Trang Facebook | Đại diện cho hoạt động kinh doanh trên Facebook; có thể liên kết với Instagram Business/Creator | Một tài nguyên có thể được chọn để kết nối với agent |
| Tài khoản Instagram Business/Creator | Đại diện cho hoạt động kinh doanh trên Instagram | Một tài khoản có thể được chọn để kết nối với agent khi đủ điều kiện |
| AI Agent | Thực hiện hoạt động tự động trên kênh đã được cấp quyền | Nhận kết nối đã hoàn tất để các MVP vận hành kênh sử dụng |

## Luồng nghiệp vụ đầu-cuối

1. **Trong phạm vi MVP** — Người quản lý chọn agent và kênh Instagram hoặc Facebook cần kết nối.
2. **Trong phạm vi MVP** — Hệ thống mở một phiên kết nối gắn với agent, kênh và phương thức đã chọn.
3. **Trong phạm vi MVP** — Người quản lý xác thực với Meta và cấp các quyền cần thiết.
4. **Trong phạm vi MVP** — Hệ thống nhận kết quả xác thực và hiển thị các tài khoản Instagram hoặc trang Facebook mà người quản lý có quyền quản lý.
5. **Trong phạm vi MVP** — Người quản lý chọn một tài khoản/trang hợp lệ; hệ thống kiểm tra tài nguyên chưa bị liên kết trùng với agent khác theo quy tắc của kênh.
6. **Trong phạm vi MVP** — Hệ thống hoàn tất kết nối và hiển thị thông tin nhận diện cùng trạng thái kết nối cho agent.
7. **Ngoài phạm vi MVP 13** — Các MVP vận hành kênh có thể dùng kết nối để nhận/gửi tin nhắn hoặc đồng bộ sự kiện.
8. **Trong phạm vi MVP** — Người quản lý có thể ngắt kết nối; sau đó agent không được sử dụng liên kết này cho hoạt động mới.
9. **Ngoài phạm vi MVP 13** — Gia hạn quyền, xử lý hội thoại, đăng bài và phân tích kênh được xác định trong các MVP riêng khi có nhu cầu.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Agent | Đối tượng nhận và sử dụng kết nối kênh |
| Phiên kết nối | Dấu vết của một lần xác thực và lựa chọn tài nguyên |
| Tài khoản Meta | Danh tính dùng để xác thực quyền quản lý |
| Tài khoản Instagram | Tài khoản Instagram Business/Creator được phát hiện và lựa chọn |
| Trang Facebook | Trang Facebook được người dùng quản lý và lựa chọn |
| Kết nối kênh | Liên kết hoàn tất giữa agent và tài khoản/trang bên ngoài, có trạng thái vòng đời |

## Quy tắc nghiệp vụ

- **BR-001**: Chỉ người có quyền cấu hình agent được phép tạo hoặc ngắt kết nối cho agent đó. Quy tắc này bảo đảm người ngoài không thể thay đổi kênh vận hành của doanh nghiệp.
- **BR-002**: Phiên xác thực phải thuộc đúng agent, kênh và phương thức đã khởi tạo. Kết quả không xác định được nguồn yêu cầu phải bị từ chối để tránh gắn nhầm tài nguyên.
- **BR-003**: Chỉ tài khoản/trang mà Meta xác nhận người dùng có quyền quản lý mới được lựa chọn.
- **BR-004**: Một agent không được có kết nối hoạt động trùng tới cùng tài khoản/trang trên cùng kênh. Điều này tránh việc nhiều agent cùng tác động lên một kênh.
- **BR-005**: Khi người dùng ngắt kết nối, liên kết phải không còn được dùng cho hoạt động mới và thông tin ủy quyền không còn cần thiết phải được thu hồi theo chính sách của hệ thống.
- **BR-006**: Nếu người dùng lặp lại thao tác tạo hoặc ngắt kết nối, kết quả phải nhất quán và không tạo thêm kết nối hoạt động trùng.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Xác thực Meta thành công và có tài nguyên hợp lệ | Hiển thị danh sách tài khoản/trang để người dùng chọn |
| Không có tài khoản/trang hợp lệ | Không tạo kết nối; hướng dẫn kiểm tra quyền hoặc dùng tài khoản khác |
| Người dùng không có quyền trên agent | Từ chối thao tác và không tiết lộ dữ liệu kết nối của agent |
| Callback hoặc phiên không hợp lệ | Không hoàn tất kết nối; phiên được ghi nhận là thất bại và có thể thử lại |
| Tài khoản/trang đã được liên kết hoạt động | Hiển thị kết nối hiện có; không tạo bản ghi trùng |
| Quyền quản lý bị thu hồi trước khi hoàn tất | Không hoàn tất kết nối; yêu cầu xác thực lại |
| Người dùng ngắt kết nối thành công | Kết nối chuyển sang đã ngắt và không được dùng cho thao tác mới |
| Người dùng ngắt kết nối lặp lại | Giữ nguyên trạng thái đã ngắt, không phát sinh lỗi nghiệp vụ mới |

## Ngoài phạm vi

- Gửi và nhận tin nhắn, xử lý hội thoại và trả lời tự động; thuộc MVP vận hành messaging tương ứng.
- Webhook, đồng bộ sự kiện thời gian thực và trạng thái hội thoại.
- Đăng bài, quảng cáo, phân tích số liệu và quản trị nội dung.
- Kết nối Zalo, TikTok, Telegram hoặc nhà cung cấp khác.
- Hỗ trợ tài khoản Instagram cá nhân không đáp ứng điều kiện của Meta.
- Chi tiết triển khai phần mềm, lưu trữ dữ liệu và bảo vệ thông tin ủy quyền.

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000041-meta-channel-connections/spec.md): user stories, yêu cầu chức năng, quy tắc quyền và phạm vi MVP.
- [Nghiệp vụ MVP 000022 — Phát hành AI Agent trên Instagram Business](06-instagram-business.md): bối cảnh vận hành Instagram Business và các điều kiện từ Meta.
- [Nghiệp vụ MVP 07 — Tái cấu trúc Flex Agent Service](07-agent-service-restructure.md): bối cảnh service điều phối kết nối kênh; không thay thế nghiệp vụ trong tài liệu này.
