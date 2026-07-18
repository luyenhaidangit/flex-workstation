# Nghiệp vụ MVP 04 — Phiên giao dịch, realtime và market-maker bot

## Mục đích và phạm vi

MVP này biến thị trường ảo FXS từ một bảng điện tĩnh thành một phiên giao dịch có nhịp sống. Người dùng có thể quan sát thời gian mở/đóng phiên, giá và giao dịch thay đổi liên tục, đồng thời đặt lệnh đối ứng với một nhà tạo lập thị trường mô phỏng.

MVP chỉ mô phỏng khâu giao dịch và khớp lệnh. Các hoạt động sau giao dịch như thanh toán, lưu ký, đối soát và quản lý tiền/chứng khoán chưa thuộc phạm vi. Chi tiết nguồn: `specs/000013-trading-session-bots/spec.md`.

## Bối cảnh nghiệp vụ

Trong thị trường chứng khoán thực tế, lệnh chỉ được tiếp nhận trong những giai đoạn nhất định của phiên. Khi thị trường đang giao dịch liên tục, lệnh mua và bán được đưa vào sổ lệnh để tìm đối tác và khớp theo giá, sau đó đến cuối phiên các lệnh còn lại được xử lý theo quy định của sàn.

Ở FlexSim, một market-maker bot đóng vai trò nhà đầu tư mô phỏng, liên tục chào một mức giá mua và một mức giá bán để tạo thanh khoản nền. Nhờ vậy, người dùng không cần tự mở hai tài khoản để tạo cả hai phía giao dịch.

```text
Người vận hành → Khởi động phiên ảo
                       ↓
              open → continuous → close
                       ↓
Người dùng demo ↔ Sổ lệnh FXS ↔ Market-maker bot
                       ↓
                 Giao dịch được khớp
```

## Vai trò trong thị trường thực tế

```text
Người vận hành phiên → Sàn giao dịch → Nhà đầu tư / Market maker
                             ↓
                    Sổ lệnh và giao dịch FXS
```

| Vai trò | Trách nhiệm thực tế | Trong FlexSim MVP này |
|---|---|---|
| Người quan sát | Theo dõi giá, khối lượng và giao dịch | Mở bảng điện, xem phiên và dữ liệu realtime |
| Nhà đầu tư demo | Đặt, theo dõi và hủy lệnh | Sử dụng một trong hai tài khoản demo để giao dịch |
| Market maker | Chào giá mua/bán hai chiều để tạo thanh khoản | Bot gửi lệnh mô phỏng quanh giá tham chiếu FXS |
| Người vận hành | Mở phiên, theo dõi trạng thái và xử lý vận hành | Khởi động ngày giao dịch ảo và giám sát bot |
| Sàn giao dịch mô phỏng | Điều phối phiên, khớp lệnh và đóng sổ | FlexSim giữ sổ lệnh, áp dụng ưu tiên giá-thời gian và hủy lệnh cuối phiên |

## Luồng nghiệp vụ đầu-cuối

1. **Khởi động ngày giao dịch** — Người vận hành bắt đầu một ngày ảo. Phiên mở ở trạng thái `open`.
2. **Giai đoạn chuẩn bị** — Trong `open`, hệ thống cho người quan sát biết phiên chưa bước vào giao dịch liên tục; lệnh mới chưa được chấp nhận.
3. **Mở giao dịch liên tục** — Hết thời lượng chuẩn bị, phiên chuyển sang `continuous`. Đây là giai đoạn nhận lệnh và khớp lệnh chính của MVP.
4. **Tạo thanh khoản nền** — Market-maker bot chào một giá mua và một giá bán quanh giá tham chiếu cố định. Bot được xử lý như một nhà đầu tư mô phỏng, không có quyền đặc biệt trong việc khớp lệnh.
5. **Đặt và khớp lệnh** — Người dùng đặt lệnh đối ứng với giá bot. Nếu thỏa điều kiện, hai lệnh khớp theo ưu tiên giá rồi thời gian; giao dịch xuất hiện trên trade tape.
6. **Lệnh chờ** — Nếu chưa có giá đối ứng, lệnh tiếp tục nằm trong sổ lệnh để chờ đối tác.
7. **Theo dõi realtime** — Người quan sát ở nhiều tab đều thấy thay đổi của sổ lệnh, giá gần nhất, giao dịch và trạng thái phiên mà không cần tải lại trang.
8. **Đóng phiên** — Hết thời lượng `continuous`, phiên chuyển sang `close`. Bot chủ động hủy lệnh của mình trước; sàn mô phỏng hủy các lệnh còn lại làm cơ chế an toàn.
9. **Kết thúc và bắt đầu ngày mới** — Không có lệnh nào được giữ qua phiên đóng. Người vận hành có thể bắt đầu ngày mới với sổ lệnh và lịch sử giao dịch của ngày đó được làm sạch.

## Đối tượng nghiệp vụ và đầu ra

| Đối tượng | Ý nghĩa trong MVP này |
|---|---|
| Phiên giao dịch ảo | Một ngày giao dịch FXS có ba giai đoạn: mở, giao dịch liên tục và đóng |
| Sổ lệnh | Tập hợp các lệnh mua/bán đang chờ đối tác |
| Lệnh | Yêu cầu mua hoặc bán FXS của người dùng hoặc bot |
| Giao dịch | Kết quả khi một lệnh mua và một lệnh bán được khớp |
| Market-maker bot | Nhà đầu tư mô phỏng tạo giá mua/bán hai chiều |
| Bảng điện | Màn hình cho người dùng quan sát giá, sổ lệnh, giao dịch và trạng thái phiên |
| Sự kiện thị trường | Thông báo thay đổi để các bảng điện đang mở cùng cập nhật |

## Quy tắc nghiệp vụ

- Phiên đi một chiều `open → continuous → close`; không quay ngược hoặc chạy song song hai phiên.
- Chỉ `continuous` nhận lệnh mới. Lệnh gửi trong `open` hoặc `close` bị từ chối với lý do rõ ràng.
- Bot phải được xử lý như một nhà đầu tư mô phỏng thông thường, đi qua cùng quy trình đặt lệnh với người dùng.
- `close` chỉ kết thúc giao dịch; MVP không thực hiện clearing, settlement hoặc các nghiệp vụ sau giao dịch.
- Khi đóng phiên, bot hủy lệnh của mình trước; sàn mô phỏng hủy toàn bộ lệnh còn lại để không có lệnh tồn qua ngày giao dịch.
- Bot dùng một giá tham chiếu cố định và spread có thể cấu hình. Giá tham chiếu không tự động chạy theo giá khớp gần nhất, giúp kịch bản demo dễ dự đoán.
- Kết nối realtime chỉ dùng để phát dữ liệu. Người dùng vẫn đặt và hủy lệnh qua luồng giao dịch thông thường.

## Kịch bản và ngoại lệ

| Tình huống | Kết quả nghiệp vụ mong đợi |
|---|---|
| Mở bảng điện trước khi khởi động phiên | Hiển thị trạng thái chưa bắt đầu, chưa có thanh khoản bot |
| Khởi động khi phiên đang chạy | Từ chối, không tạo phiên thứ hai |
| Lệnh gửi trong `open` | Từ chối vì chưa đến giai đoạn giao dịch liên tục |
| Lệnh gửi trong `continuous` có giá đối ứng | Khớp lệnh, cập nhật giao dịch và sổ lệnh |
| Lệnh gửi trong `continuous` chưa có giá đối ứng | Được giữ chờ trong sổ lệnh |
| Lệnh gửi trong `close` | Từ chối, sổ lệnh không thay đổi |
| Mất kết nối bảng điện | Hiển thị mất kết nối và tự khôi phục; khi vào lại nhận dữ liệu hiện tại |
| Bot không gửi được một chu kỳ giá | Ghi nhận sự cố vận hành, chờ chu kỳ tiếp theo, không thử lại vô hạn |
| Khởi động ngày mới sau khi đóng phiên | Sổ lệnh và giao dịch của ngày mới bắt đầu sạch |

## Ngoài phạm vi

- Đấu giá mở cửa ATO và đóng cửa ATC; dành cho các MVP về cơ chế đấu giá sau này.
- Nhiều loại bot như noise trader, trend follower hoặc arbitrage bot.
- Nhiều mã chứng khoán hoặc nhiều thị trường trong cùng một phiên.
- Tài khoản chứng khoán thật, xác thực, phân quyền đa người dùng và mô hình CTCK tenant.
- Kiểm tra số dư tiền/chứng khoán, ledger, T+, clearing, settlement và custody.
- Lưu trữ bền vững phiên và giao dịch qua lần khởi động lại dịch vụ.
- Ứng dụng mobile hoặc tối ưu responsive hoàn chỉnh.

## Truy vết và nguồn tham khảo

- [Đặc tả tính năng](../../specs/000013-trading-session-bots/spec.md): mục tiêu, phạm vi, user story và quy tắc nghiệp vụ.
- [Tài liệu MVP 04](../mvp/04-trading-session-bots.md): định hướng nghiệp vụ trong roadmap FlexSim.
- [Roadmap FlexSim](../mvp/flexsim-roadmap.md): vị trí của MVP 04 trong lộ trình thị trường ảo.
