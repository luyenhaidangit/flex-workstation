# Nghiệp vụ MVP 01 — Exchange khớp lệnh

## Mục đích và phạm vi

Tài liệu này giải thích nghiệp vụ cho BA và kỹ sư trước khi đọc quy tắc hay hợp đồng kỹ thuật của MVP 01. Thị trường tham chiếu là **cổ phiếu niêm yết trên HOSE**; nguồn quy định là [Quy chế Niêm yết và giao dịch chứng khoán niêm yết của VNX, Quyết định 22/QĐ-HĐTV, hiệu lực 16/03/2026](https://vnx.vn/vi/van-ban-phap-ly/6).

FlexSim là **simulation only**. MVP 01 không kết nối HOSE, CTCK, VSDC, ngân hàng thanh toán, dữ liệu giá hay tiền thật. Tài liệu dùng quy tắc thị trường thực tế để giải thích mục tiêu mô phỏng, không thay thế quy định pháp lý hoặc quy trình vận hành của các tổ chức đó.

MVP 01 chỉ mô phỏng lõi của **Sở giao dịch** cho một mã cổ phiếu giả lập: nhận limit order, duy trì order book và xác định giao dịch trong một phiên `continuous`. Các quy tắc chi tiết mà hệ thống phải thực hiện nằm trong [Quy tắc khớp lệnh MVP 01](../mvp/01-matching-rules.md); bề mặt kỹ thuật nằm trong [đặc tả lõi khớp lệnh](../../specs/000010-matching-engine-core/spec.md).

## Vai trò trong thị trường thực tế

```text
Nhà đầu tư → CTCK → Sở giao dịch → VSDC / ngân hàng thanh toán
                         │
                         └── Phạm vi MVP 01: matching engine và order book
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim |
| --- | --- | --- |
| Nhà đầu tư | Ra quyết định mua/bán và gửi yêu cầu giao dịch. | Chưa có ở MVP 01. |
| CTCK | Nhận lệnh, kiểm tra tiền/chứng khoán, kiểm soát trước giao dịch và gửi lệnh lên Sở. | `DemoBroker` chỉ thay thế nguồn gửi lệnh; CTCK đầy đủ từ MVP 05. |
| Sở giao dịch | Nhận lệnh từ thành viên, tổ chức sổ lệnh, áp dụng quy tắc khớp và xác lập giao dịch. | Là chủ sở hữu của matching engine trong MVP 01. |
| VSDC và ngân hàng thanh toán | Nhận kết quả giao dịch, bù trừ và thanh toán tiền/chứng khoán. Với cổ phiếu, VSDC nêu chu kỳ thanh toán T+2 và nguyên tắc DVP. | Mô phỏng hậu giao dịch từ MVP 08; không thuộc MVP 01. |

Nguồn dữ liệu đầu vào của Exchange trong thực tế là lệnh đã được CTCK kiểm tra, không phải thao tác trực tiếp của nhà đầu tư. Vì vậy, MVP 01 không kiểm tra sức mua, số dư chứng khoán, margin hay danh tính khách hàng.

## Luồng nghiệp vụ đầu-cuối

1. Nhà đầu tư gửi yêu cầu mua hoặc bán tới CTCK.
2. CTCK xác thực khách hàng, kiểm tra phiên, điều kiện giao dịch, tiền mua dự kiến hoặc chứng khoán bán khả dụng; sau đó phong tỏa phần cần thiết và route lệnh hợp lệ tới Sở.
3. Sở giao dịch kiểm tra quy tắc giao dịch của mã và phiên, đưa lệnh hợp lệ vào cơ chế khớp lệnh.
4. Trong khớp lệnh liên tục, lệnh mới đối chiếu với các lệnh đối ứng đang chờ. Nếu thỏa giá thì phát sinh giao dịch; phần chưa khớp tiếp tục chờ trong order book.
5. Sở phát kết quả lệnh và giao dịch cho CTCK. CTCK cập nhật trạng thái lệnh của khách hàng và phần tiền/chứng khoán phong tỏa.
6. Sau khi giao dịch được xác lập, kết quả được chuyển sang VSDC để bù trừ và thanh toán. Đây là bước khác với khớp lệnh; với cổ phiếu, VSDC công bố thanh toán theo kết quả bù trừ đa phương ở T+2.

MVP 01 bắt đầu ở bước 3 với `DemoBroker` và kết thúc ở bước 4/đầu bước 5 bằng các sự kiện nghiệp vụ. Các bước CTCK và hậu giao dịch chỉ được nêu để xác định ranh giới trách nhiệm.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP 01 |
| --- | --- |
| `Order` | Yêu cầu mua/bán gồm mã, chiều, giá, khối lượng, thứ tự vào và `BrokerId`. |
| `InstrumentConfig` | Cấu hình riêng cho mã FXS: bước giá, biên độ giá và đơn vị lô chẵn. |
| `OrderBook` | Các lệnh chưa khớp hết, chia thành bên mua và bên bán, được sắp theo ưu tiên giá rồi thời gian. |
| `Trade` | Kết quả một lần khớp giữa một lệnh mua và một lệnh bán, gồm giá, khối lượng và tham chiếu hai lệnh. |
| Sự kiện | `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled`; là đầu ra để MVP 02 công bố API/sự kiện và MVP 05 liên kết lệnh khách hàng. |
| Nghĩa vụ thanh toán | Tiền/chứng khoán phải nhận hoặc phải trả sau giao dịch. Đối tượng này chỉ phát sinh từ MVP 08, không được tạo trong MVP 01. |

## Quy tắc của MVP 01

- Chỉ nhận limit order mua hoặc bán trong một phiên `continuous`.
- Lệnh phải hợp lệ theo bước giá, biên độ và lô chẵn cấu hình trước khi vào sổ hoặc khớp.
- Bên mua có giá cao hơn được ưu tiên; bên bán có giá thấp hơn được ưu tiên.
- Khi cùng giá, lệnh vào hệ thống trước được ưu tiên trước.
- Giá khớp là giá của lệnh đối ứng đã chờ trong order book, tức lệnh bị động.
- Một lệnh có thể khớp qua nhiều lệnh đối ứng và có thể khớp một phần. Phần còn lại tiếp tục chờ cho đến khi được khớp, hủy hoặc kết thúc lần chạy mô phỏng.
- Chỉ lệnh còn khối lượng chờ mới hủy được. Lệnh đã khớp hết, đã hủy hoặc không tồn tại bị từ chối hủy và không làm thay đổi order book.
- Cùng chuỗi lệnh và thứ tự vào phải cho cùng chuỗi sự kiện và snapshot cuối; thứ tự thời gian trong mô phỏng là thứ tự xử lý, không phụ thuộc đồng hồ máy.

## Đối chiếu thị trường HOSE và FlexSim

| Nội dung | Thị trường HOSE tham chiếu | FlexSim MVP 01 |
| --- | --- | --- |
| Phương thức khớp | Có khớp lệnh định kỳ và khớp lệnh liên tục theo quy định hiện hành. | Chỉ khớp lệnh liên tục. |
| Loại lệnh | Có các loại lệnh/phương thức phục vụ từng phiên, gồm ATO/ATC và lệnh thị trường theo quy định. | Chỉ limit order. |
| Ưu tiên | Giá trước, thời gian sau trong khớp lệnh liên tục. | Mô phỏng đầy đủ quy tắc này. |
| Giá khớp liên tục | Giá của lệnh giới hạn đối ứng đang chờ. | Mô phỏng đầy đủ quy tắc này. |
| Sửa, hủy lệnh | Phụ thuộc loại lệnh và phiên; việc sửa có ảnh hưởng ưu tiên thời gian. | Chỉ hủy lệnh còn dư; không có amend. |
| Mã và thành viên | Nhiều mã, nhiều CTCK thành viên, có các kiểm soát theo đối tượng giao dịch. | Một mã FXS và một `DemoBroker`. |
| Giới hạn sở hữu nước ngoài | Có kiểm soát theo quy định thị trường. | Ngoài phạm vi. |
| Giao dịch thỏa thuận | Có quy trình riêng, không phải khớp qua order book liên tục. | Ngoài phạm vi. |
| Hậu giao dịch | VSDC bù trừ; cổ phiếu thanh toán T+2 theo nguyên tắc DVP. | Ngoài phạm vi, để MVP 08. |

ATO/ATC, lệnh thị trường, sửa lệnh, giao dịch thỏa thuận, kiểm soát nhà đầu tư nước ngoài, đa mã, đa CTCK và settlement T+2 được ghi nhận để không nhầm MVP 01 là một sàn HOSE hoàn chỉnh. Việc bổ sung bất kỳ nội dung nào trong số này phải đi qua MVP tương ứng hoặc đặc tả mới.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
| --- | --- |
| Không có lệnh đối ứng thỏa giá | Lệnh hợp lệ được chấp nhận và nằm chờ trong order book. |
| Khớp toàn phần | Phát `TradeExecuted`; cả hai lệnh hoàn tất và không còn trong sổ. |
| Khớp một phần | Phát `TradeExecuted`; phần dư của lệnh còn khối lượng tiếp tục nằm sổ. |
| Ưu tiên giá | Lệnh bán giá thấp hơn hoặc lệnh mua giá cao hơn được khớp trước. |
| Ưu tiên thời gian | Hai lệnh cùng giá được khớp theo thứ tự vào hệ thống. |
| Hủy lệnh chờ | Phát `OrderCancelled`, gỡ toàn bộ phần dư và không cho phần đó khớp về sau. |
| Lệnh sai cấu hình | Phát `OrderRejected` kèm lý do; không tạo giao dịch và không thay đổi order book. |
| Hủy lệnh không còn trong sổ | Từ chối hủy kèm lý do; không phát sự kiện thay đổi sổ. |

## Truy vết và nguồn tham khảo

- [Quy tắc khớp lệnh và order book — MVP 01](../mvp/01-matching-rules.md): phạm vi MVP và điều kiện hoàn thành.
- [Đặc tả lõi khớp lệnh](../../specs/000010-matching-engine-core/spec.md): yêu cầu, trạng thái, acceptance criteria và ràng buộc kỹ thuật.
- [Quy chế Niêm yết và giao dịch chứng khoán niêm yết — VNX](https://vnx.vn/vi/van-ban-phap-ly/6): chuẩn tham chiếu cho thị trường cổ phiếu niêm yết.
- [Bù trừ và thanh toán — VSDC](https://www.vsd.vn/vi/sd/XAz40d2Q-9j569TvBgLQaQ): ranh giới bù trừ, thanh toán và nguyên tắc DVP/T+2.
