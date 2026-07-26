# Nghiệp vụ & Kiến trúc Hệ thống Chứng khoán: Vòng đời Session State Machine và Giao tiếp Sở - Broker

## Mục đích và phạm vi

Tài liệu này hệ thống hóa kiến thức nghiệp vụ và đặc tả kiến trúc kỹ thuật về **Vòng đời State Machine của Phiên Giao dịch** cùng **Cơ chế Giao tiếp giữa Sở Giao dịch (HNX/HOSE) và Công ty Chứng khoán (Broker thành viên)** trong hệ thống Flex.

Tài liệu đóng vai trò là nguồn tri thức chuẩn (Source of Truth) cho các phân hệ:
- **Matching Engine & Order Book**: Xử lý logic chuyển pha phiên và thay đổi thuật toán khớp lệnh tương ứng.
- **Broker Gateway & Pre-trade Risk Check**: Cấu hình bộ lọc chặn lệnh tại nguồn theo trạng thái phiên realtime.
- **Market Data Feed & Notification**: Multicast/Broadcast tín hiệu phiên và dữ liệu thị trường đến các Broker thành viên.

---

## 1. Vòng đời State Machine của Phiên Giao Dịch

Mỗi khi hệ thống chuyển trạng thái (ví dụ từ 8:59:59 sang 9:00:00), một sự kiện chuyển pha (Session Phase Event) được trigger để thay đổi thuật toán xử lý bên trong Order Book và hành vi của Gateway.

```text
[ Nhận lệnh đầu ngày ] ──FIX Broadcast Ready──> [ Khớp lệnh định kỳ (ATO) ]
         │                                                      │
         ▼                                                      ▼
[ Tạm ngừng (Halt) ] <─── 11:30 - 13:00 Nghỉ trưa ─── [ Khớp lệnh liên tục (Continuous) ]
         │                                                      │
         ▼                                                      ▼
[ Khớp lệnh liên tục (Chiều) ] ─── 14:30 Multicast Status ──> [ Khớp lệnh định kỳ (ATC) ]
                                                                │
                                                                ▼
                                                   [ Đóng cửa & EOD Purge / VSDC Sync ]
```

### Trạng thái 1: Nhận lệnh đầu ngày / Khởi động hệ thống (System Startup / Pre-Open)

- **Hành vi của Engine**: Hệ thống mở kết nối Gateway, chấp nhận các lệnh mới đẩy vào hàng đợi (Queue) nhưng **chưa thực hiện khớp lệnh**.
- **Giao tiếp với Broker**: Sở bắt đầu broadcast tín hiệu "Hệ thống sẵn sàng" (*System Ready / Pre-Open Status*) qua giao thức **FIX (Financial Information eXchange)** đến toàn bộ các Broker thành viên.

### Trạng thái 2: Khớp lệnh định kỳ (Call Auction - ATO / ATC)

- **Thời gian thực tế**: 
  - **Phái sinh HNX**: ATO (8:45 - 9:00), ATC (14:30 - 14:45).
  - **Cổ phiếu cơ sở (HOSE/HNX)**: ATO (9:00 - 9:15 tại HOSE), ATC (14:30 - 14:45 tại cả HOSE và HNX).
- **Hành vi của Engine**: Order Book đóng vai trò là một bộ gom (**Aggregator**). Engine không khớp lệnh ngay theo cơ chế FIFO thông thường mà dồn toàn bộ lệnh mua/bán vào sổ. Thuật toán liên tục quét để tính toán ra một mức giá duy nhất sao cho khối lượng giao dịch tích lũy đạt mức lớn nhất (**Max Volume Clearing Price**).
- **Xử lý tại Broker & Gateway**: Nếu hệ thống Broker đẩy một lệnh thị trường không hợp lệ (ví dụ: đẩy lệnh `MP` vào phiên ATO thay vì dùng đúng loại lệnh `ATO`), Gateway của Sở sẽ lập tức **Reject** và trả về Error Code cho Broker.

### Trạng thái 3: Khớp lệnh liên tục (Continuous Matching)

- **Thời gian thực tế**: 9:00 - 11:30 và 13:00 - 14:30 (áp dụng chung cho cả thị trường cơ sở và phái sinh).
- **Hành vi của Engine**: Trạng thái yêu cầu **throughput cao nhất** và **độ trễ (latency) thấp nhất** (tính bằng microsecond). Thuật toán chuyển sang cơ chế **Ưu tiên Giá - Thời gian (Price-Time Priority)**. Bất kỳ lệnh giới hạn (`LO`) hoặc lệnh thị trường (`MP`, `MTL`, `MOK`, `MAK`) khi đi qua **Sequencer** đều được đưa thẳng vào **Matching Engine** để đối soát FIFO. Lệnh nào vào trước (dựa trên timestamp do Sequencer đánh dấu) sẽ được ưu tiên khớp trước.

### Trạng thái 4: Tạm ngừng / Đóng cửa (Halt / End of Day - EOD)

- **Nghỉ trưa (11:30 - 13:00)**: State Machine chuyển sang trạng thái `Halt`. Client Gateway có thể vẫn duy trì kết nối để nhận lệnh chờ cho phiên chiều, nhưng Matching Engine tạm dừng mọi hoạt động so khớp.
- **End of Day (Sau 15:00)**: Engine thực hiện quy trình dọn dẹp (**Purge**). Toàn bộ các lệnh chưa khớp còn dư trong ngày (`DAY` order) sẽ tự động bị hủy khỏi hệ thống. Sở khởi chạy các batch job EOD để đồng bộ dữ liệu giao dịch sang **Trung tâm Lưu ký Chứng khoán (VSDC)** phục vụ cho việc bù trừ và thanh toán (**Clearing & Settlement**).

---

## 2. Giao tiếp giữa Sở (HNX/HOSE) và Công ty Chứng khoán (Broker)

Để đồng bộ trạng thái từ Sở về hệ thống của các Broker thành viên trong môi trường phân tán, hệ thống áp dụng các chuẩn thiết kế sau:

### 2.1 Broadcast Trạng Thái (Trading Session Status Multicast)
- Khi Sở (HNX/HOSE) chuyển từ phiên Khớp lệnh liên tục sang phiên ATC lúc 14:30, Gateway của Sở sẽ bắn một bản tin trạng thái (**Trading Session Status Notification**) qua luồng multicast/message broker.
- Hệ thống Gateway/Order Service của Broker phải **subscribe** vào luồng này để cập nhật trạng thái sàn ngay lập tức trong memory cache.

### 2.2 Xử lý Bất biến (Idempotency)
- Trong môi trường phân tán microservices, mạng chớp tắt hoặc retry có thể khiến Broker nhận lại bản tin chuyển trạng thái phiên 2 lần.
- Hệ thống nội bộ của Broker phải thiết kế theo chuẩn **Idempotent**: khi nhận cùng một bản tin chuyển phiên hoặc trạng thái lệnh nhiều lần, state machine của Broker giữ nguyên trạng thái đúng, không làm sai lệch luồng chặn/mở lệnh của nhà đầu tư.

### 2.3 Chặn lệnh tại nguồn (Pre-trade Risk Check tại Broker Gateway)
- Dựa vào trạng thái phiên nhận được từ Sở, Gateway của Broker tự động cấu hình bộ lọc kiểm soát rủi ro trước giao dịch (*Pre-trade Risk Check*).
- **Ví dụ**: Nếu đồng hồ hệ thống và bản tin phiên báo đã 9:00 (chuyển sang Continuous Matching), Gateway của Broker từ chối ngay lập tức lệnh `ATO` do người dùng đặt ở màn hình giao dịch, thay vì gửi lệnh lên Sở rồi mới bị Sở Reject. Điều này giúp giảm thiểu độ trễ, tiết kiệm băng thông đường truyền FIX và cải thiện trải nghiệm người dùng.

---

## 3. Architecture Overview — Hệ thống Sở Giao dịch Chứng khoán

Sơ đồ kiến trúc chuẩn cho hệ thống Exchange (tham chiếu mô hình High-Throughput Exchange Engine):

```text
                                       ┌─────────────────────────┐
                                       │       Data Service      │◄───(M3)─── Broker
                                       └────────────▲────────────┘
                                                    │ (M2) candlestick chart, order book
                                       ┌────────────┴────────────┐
                                       │ Market Data Publisher   │
                                       └────────────▲────────────┘
                                                    │ (M1)
┌──────────┐  (1)  ┌──────────┐  (2)   ┌────────────┴────────────┐  (7)  ┌───────────┐  (8)  ┌─────────────────────────┐
│ Client UI├──────►│  Broker  ├───────►│     Client Gateway      ├──────►│ Sequencer ├──────►│     Matching Engine     │
└──────────┘ (14)  └────▲─────┘ (13)   └────────────┬────────────┘      └─────▲─────┘      │ ┌─────────────────────┐ │
                        │                           │ (3)                     │ (10)     │ │     Order Book      │ │
                        └────────(M3)───────────────┼─────────────────────────┼──────────► │ └─────────────────────┘ │
                                                    ▼                         │ (11)     └────────────┬────────────┘
                                       ┌─────────────────────────┐            │                       │ (R1)
                                       │      Order Manager      ├────────────┘                       ▼
                                       │   ┌─────────────────┐   │                               ┌──────────┐
                                       │   │     Wallet      │   │                               │ Reporter │
                                       │   └─────────────────┘   │                               └────┬─────┘
                                       └────────────┬────────────┘                                    │ (R2)
                                                 (4)│ ▲(5)                                            ▼
                                                    ▼ │                                          ┌──────────┐
                                       ┌─────────────────────────┐                               │    DB    │
                                       │ Aggregated Risk Check   │                               └──────────┘
                                       └─────────────────────────┘                            orders, executions
```

### Các luồng chính trong kiến trúc:
1. **Critical Path (Luồng lệnh trực tiếp)**:
   - **(1) -> (2)**: Nhà đầu tư gửi lệnh từ Client UI -> Broker -> Client Gateway của Sở.
   - **(3) -> (4) -> (5)**: Client Gateway đưa lệnh vào `Order Manager` để gọi `Aggregated Risk Check` (kiểm tra hạn mức, phiên, định dạng lệnh).
   - **(7) -> (8)**: Lệnh hợp lệ được gửi sang `Sequencer` để gắn số thứ tự tuyệt đối (Sequence Number / Timestamp microsecond), sau đó đẩy vào `Matching Engine`.
   - **(9)**: `Matching Engine` đưa lệnh vào `Order Book` để khớp (định kỳ hoặc FIFO liên tục).
   - **(10) -> (11) -> (12) -> (13) -> (14)**: Kết quả khớp/từ chối lệnh được phản hồi ngược về Broker và Client UI qua luồng báo khớp real-time.

2. **Market Data Flow (Luồng dữ liệu thị trường)**:
   - **(M1) -> (M2) -> (M3)**: `Matching Engine` phát sự kiện khớp/thay đổi sổ lệnh sang `Market Data Publisher` -> `Data Service` -> Khách hàng/Broker (cập nhật biểu đồ nến, sổ lệnh 3 giá realtime).

3. **Reporting & Settlement Flow (Luồng lưu trữ & bù trừ cuối ngày)**:
   - **(R1) -> (R2)**: `Order Manager` chuyển dữ liệu lệnh và kết quả giao dịch sang `Reporter` để ghi bền vững vào Database. Cuối ngày (EOD), dữ liệu này được trích xuất để đồng bộ sang **VSDC** cho quy trình Clearing & Settlement.

---

## Truy vết và Nguồn tham khảo

- [Cấu trúc thị trường chứng khoán Việt Nam](00-vietnamese-securities-market-structure.md)
- [Nghiệp vụ MVP 01 — Exchange khớp lệnh](01-mvp-exchange-matching.md)
- [Nghiệp vụ MVP 04 — Phiên giao dịch, realtime và market-maker bot](02-trading-session-bots.md)
- [Nghiệp vụ MVP 08 — Database, clearing, settlement và đối chiếu](04-database-clearing-settlement.md)
