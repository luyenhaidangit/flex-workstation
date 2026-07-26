# Nghiệp vụ MVP 08 — Database, clearing, settlement và đối chiếu

## Mục đích và phạm vi

MVP 08 đưa các quy tắc sổ cái của MVP 07 vào một luồng vận hành có thể kiểm soát: ghi nhận giao dịch một lần, tạo nghĩa vụ thanh toán, hoàn tất theo chu kỳ T+ và đối chiếu cuối ngày. Mục tiêu là mô phỏng đúng phần hậu giao dịch của một công ty chứng khoán, để số dư và nghĩa vụ luôn truy vết được thay vì chỉ là kết quả tạm thời.

MVP này phục vụ kịch bản demo/staging với tenant Alpha và Beta. Hệ thống mô phỏng clearing, settlement và sao kê EOD; không kết nối thị trường, ngân hàng, VSDC hoặc file sao kê thật. Chi tiết requirement và điều kiện kỹ thuật nằm trong [đặc tả MVP 08](../../specs/000017-database-clearing-settlement/spec.md).

## Bối cảnh nghiệp vụ

Sau khi một lệnh mua và một lệnh bán đã được khớp, việc giao dịch chưa thực sự hoàn tất. Bên mua có nghĩa vụ trả tiền, bên bán có nghĩa vụ giao chứng khoán. Trong thời gian chờ thanh toán, các khoản này phải được theo dõi riêng với số dư đã sẵn sàng sử dụng. Đến ngày thanh toán T+, nghĩa vụ mới được hoàn tất và số dư mới trở thành khả dụng.

Trong thực tế, bộ phận vận hành phải trả lời được ba câu hỏi: giao dịch này đã được ghi nhận chưa, đang chờ điều gì để hoàn tất, và số liệu nội bộ có khớp với sao kê cuối ngày hay không. MVP 08 mô phỏng đầy đủ chuỗi trả lời đó, đồng thời giữ lịch sử nguyên vẹn để xử lý sự cố và kiểm tra sau này.

## Vai trò trong thị trường thực tế

```text
Nhà đầu tư
  → Công ty chứng khoán / Broker
  → Sở giao dịch (khớp lệnh)
  → Clearing & settlement
  → Lưu ký / Ngân hàng thanh toán

Phạm vi MVP 08: từ giao dịch đã khớp tại Broker đến nghĩa vụ, settlement T+,
đối chiếu và xử lý ngoại lệ nội bộ.
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Broker / Exchange | Phát sinh và chuyển thông tin lệnh, khớp lệnh | Cung cấp sự kiện nghiệp vụ đầu vào cho luồng ghi nhận |
| Nhân viên vận hành broker | Theo dõi số dư, nghĩa vụ, thanh toán và chênh lệch | Xem kết quả, chạy chu kỳ demo, đối chiếu và điều tra cảnh báo |
| Quản trị viên nền tảng | Đảm bảo dữ liệu sẵn sàng, xử lý sự cố có kiểm soát | Khởi tạo tenant, theo dõi tình trạng xử lý và thực hiện recovery được ủy quyền |
| Clearing/settlement | Xác định và hoàn tất nghĩa vụ tiền, chứng khoán | Được mô phỏng bằng chu kỳ T+ nội bộ |
| Lưu ký / ngân hàng thanh toán | Chuyển giao chứng khoán và tiền thật | Không nằm trong MVP; chỉ được mô phỏng qua kết quả settlement |

## Luồng nghiệp vụ đầu-cuối

1. **[Trong phạm vi]** Một tenant mới được chuẩn bị số dư opening để có thể bắt đầu giao dịch. Chạy lại bước chuẩn bị không làm tăng số dư lần hai.
2. **[Trong phạm vi]** Broker/Exchange gửi thông tin reserve, fill, fee hoặc cancel. Mỗi thông tin hợp lệ được ghi một lần vào lịch sử nghiệp vụ và phản ánh vào số dư liên quan.
3. **[Trong phạm vi]** Nếu cùng sự kiện được gửi lại, hệ thống nhận biết đây là bản lặp và trả kết quả đã có; số dư không bị thay đổi lần nữa.
4. **[Trong phạm vi]** Khi trade đã khớp ở ngày T, hệ thống tạo nghĩa vụ tiền/chứng khoán. Khoản đang chờ được theo dõi riêng, chưa dùng được như số dư khả dụng.
5. **[Trong phạm vi]** Đến T+ trong mô phỏng, nhân viên vận hành chạy chu kỳ thanh toán. Nghĩa vụ hoàn tất và khoản chờ được chuyển đúng sang khả dụng.
6. **[Trong phạm vi]** Cuối ngày, sao kê EOD giả lập được nạp để đối chiếu tổng số và từng giao dịch với số liệu nội bộ.
7. **[Trong phạm vi]** Nếu có chênh lệch, hệ thống tạo cảnh báo có tham chiếu tới giao dịch nguồn để điều tra. Lịch sử gốc không bị tự động sửa.
8. **[Ngoài phạm vi]** Việc gửi nhận tiền/chứng khoán với ngân hàng, VSDC hay tổ chức thanh toán thật sẽ thuộc các giai đoạn tích hợp sau.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Tài khoản ledger | Nơi theo dõi tiền hoặc chứng khoán của một tenant theo từng trạng thái nghiệp vụ |
| Lịch sử bút toán | Bằng chứng cân bằng, bất biến cho mỗi biến động nghiệp vụ đã được chấp nhận |
| Sự kiện giao dịch | Thông tin đầu vào có nguồn và tham chiếu rõ để nhận biết trùng lặp, truy vết và recovery |
| Số dư | Cách nhìn hiện tại của tài khoản: khả dụng, đã reserve, phải thu hoặc phải trả |
| Nghĩa vụ settlement | Cam kết tiền/chứng khoán phát sinh sau khi trade đã khớp và đang chờ T+ |
| Sao kê EOD | Số liệu cuối ngày được mô phỏng để kiểm tra với số liệu nội bộ |
| Kết quả đối chiếu / cảnh báo | Bằng chứng số liệu đã khớp hoặc một chênh lệch cần được nhân viên xử lý |
| Audit | Lịch sử ai đã thực hiện thao tác vận hành quan trọng, khi nào và với lý do gì |

## Quy tắc nghiệp vụ

- Mỗi giao dịch được chấp nhận phải cân bằng về giá trị ghi nhận. Đây là nguyên tắc để không thể tạo ra hoặc làm mất giá trị chỉ vì lỗi thao tác.
- Lịch sử đã ghi không được sửa hoặc xóa. Nếu có sai sót, người có quyền phải lập bút toán điều chỉnh hoặc đảo bút toán, kèm lý do và liên kết tới bản gốc; cách này bảo toàn khả năng kiểm toán.
- Một sự kiện nguồn trong cùng tenant chỉ được tạo một kết quả nghiệp vụ. Quy tắc này ngăn số dư và nghĩa vụ bị nhân đôi khi hệ thống gửi lại thông tin.
- Trade đã khớp tạo nghĩa vụ tại T, nhưng tiền/chứng khoán đang chờ thanh toán chưa là số dư khả dụng. Chỉ khi hoàn tất T+ mới được chuyển sang trạng thái dùng được.
- Dữ liệu của mỗi tenant phải tách biệt. Nhân viên chỉ nhìn thấy và thao tác trên tenant được cấp quyền; đây là điều kiện cơ bản để bảo vệ số liệu khách hàng.
- Chênh lệch đối chiếu là tín hiệu để điều tra, không phải cơ chế tự động sửa dữ liệu. Điều này giúp phân biệt rõ số liệu gốc, dấu vết chênh lệch và quyết định khắc phục.
- Recovery chỉ dành cho người được ủy quyền và luôn để lại audit, vì thao tác này có thể ảnh hưởng đến tiến trình xử lý giao dịch.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Tenant mới được chuẩn bị dữ liệu | Có số dư opening một lần, sẵn sàng nhận giao dịch |
| Sự kiện reserve/fill/fee/cancel hợp lệ | Có lịch sử cân bằng, số dư liên quan được cập nhật và truy vết được nguồn |
| `TradeExecuted` bị gửi lại | Được nhận diện là trùng; không có số dư hay nghĩa vụ tăng lần hai |
| Trade được khớp ở T | Tạo nghĩa vụ; tiền/chứng khoán ở trạng thái chờ, chưa khả dụng |
| Chạy chu kỳ đến T+ | Nghĩa vụ hoàn tất và số dư chuyển đúng trạng thái |
| Sự kiện lỗi nhiều lần | Được cô lập thành việc cần xử lý, không mất im lặng |
| Cần sửa sai nghiệp vụ | Tạo điều chỉnh/đảo bút toán có lý do; lịch sử gốc giữ nguyên |
| Sao kê EOD khớp | Ghi nhận kết quả đối chiếu khớp ở tổng và chi tiết |
| Sao kê EOD có lệch | Sinh cảnh báo có tham chiếu nguồn để điều tra, không tự sửa số liệu |
| Người dùng thử xem tenant khác | Bị từ chối và không nhận được bất kỳ số liệu nào của tenant kia |

## Ngoài phạm vi

- **Kết nối hạ tầng thật**: không kết nối VSDC, ngân hàng, clearing house hoặc nhận file sao kê thật; đây là bước tích hợp sau khi mô phỏng ổn định.
- **Sản phẩm và nghiệp vụ mở rộng**: không bao gồm margin, collateral, phái sinh, corporate action hoặc quy trình hậu giao dịch nâng cao.
- **Báo cáo và thanh toán production**: không phải ledger kế toán tổng hợp, báo cáo pháp định hay chuyển tiền/chứng khoán thật.
- **Tự động quyết định**: không dùng AI để phân loại, quyết định hoặc tự xử lý chênh lệch.
- **Xóa dấu vết**: không tự động sửa, xóa hoặc ghi đè lịch sử để che lỗi.

## Truy vết và nguồn tham khảo

- [Cấu trúc thị trường chứng khoán Việt Nam](00-vietnamese-securities-market-structure.md): thuật ngữ và phân biệt VNX/HOSE/HNX/market dùng chung.
- [Đặc tả MVP 08](../../specs/000017-database-clearing-settlement/spec.md): user stories, acceptance criteria, phân quyền, rủi ro và điều kiện chấp nhận.
- [MVP 08 gốc](../mvp/08-database-pipeline-clearing-settlement-reconciliation.md): mô tả phạm vi, luồng demo và điều kiện hoàn thành ban đầu.
- MVP 07: nguồn quy tắc ledger cho opening, reserve, fill, fee và cancel.
- Hạ tầng tenant registry/routing và database-per-tenant của workspace: phụ thuộc để điều phối dữ liệu theo từng tenant.
