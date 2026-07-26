# Đặc tả tính năng: Quản lý Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

**Branch**: `000020-session-lifecycle`  
**Ngày tạo**: 2026-07-26  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Admin  
**Stakeholder xác nhận**: Admin  
**Đầu vào**: Nâng cấp bộ máy Quản lý Phiên giao dịch chứng khoán chuẩn quy định Việt Nam (HOSE, HNX, UPCoM, Phái sinh), bao gồm máy trạng thái đa phiên (PreOpen, ATO, Continuous, Intermission, ATC, PLO, Close) và van chặn cấm sửa/hủy lệnh trong phiên định kỳ ATO/ATC.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:
Hiện tại hệ thống `flex-exchange-service` chỉ hỗ trợ 3 trạng thái phiên đơn giản (`Open`, `Continuous`, `Close`), chưa phản ánh đúng thực tế nghiệp vụ Thị trường Chứng khoán Việt Nam. Quan trọng hơn, hệ thống chưa có van chặn nghiệp vụ để cấm sửa/hủy lệnh trong phiên định kỳ (`ATO` và `ATC`), dẫn tới rủi ro lọt lệnh vi phạm quy định của Sở Giao dịch Chứng khoán.

**Tổng quan tính năng**:
Cung cấp máy trạng thái phiên đầy đủ chuẩn nghiệp vụ chứng khoán cho các thị trường (`HOSE`, `HNX`, `UPCoM`, `Phái sinh`), bổ sung kiểm soát loại lệnh được phép đặt và tự động ngăn chặn hành vi sửa/hủy lệnh trong các phiên khớp lệnh định kỳ (`ATO`, `ATC`).

---

## 2. Mục tiêu

- **MT-001**: Chuẩn hóa máy trạng thái phiên giao dịch khớp với quy định thực tế của các sàn HOSE, HNX, UPCoM và Phái sinh.
- **MT-002**: Ngăn chặn 100% các thao tác sửa hoặc hủy lệnh vi phạm quy định trong các phiên định kỳ `ATO` và `ATC`.
- **MT-003**: Cung cấp cơ chế kiểm tra loại lệnh phù hợp theo từng phiên giao dịch cụ thể tại tầng Pre-Trade và Matching Engine.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Mở rộng Enum trạng thái phiên hỗ trợ: `PreOpen`, `ATO`, `Continuous`, `Intermission`, `ATC`, `PLO`, `Close`.
- **MVP-002**: Ràng buộc cấm hủy lệnh khi phiên đang ở trạng thái `ATO` hoặc `ATC` (Trả về lỗi `CancelNotAllowedInCurrentSession`).
- **MVP-003**: Cấu hình thời biểu phiên riêng biệt cho từng thị trường (`HOSE`, `HNX`, `UPCoM`, `Phái sinh`).
- **MVP-004**: Kiểm soát loại lệnh (`LO`, `ATO`, `ATC`) được phép đặt theo từng trạng thái phiên hiện tại (Trả về lỗi `OrderTypeNotAllowedInCurrentSession` nếu sai).

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Nhà đầu tư, Công ty chứng khoán (Broker), Hệ thống tự động (Worker / MarketMakerBot).

**Bối cảnh sử dụng**: Đặt lệnh, hủy lệnh, hoặc xem bảng giá realtime trong suốt thời gian giao dịch từ 08:45 đến 15:00.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ chứng khoán.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Chặn hủy lệnh trong phiên định kỳ ATO / ATC (Ưu tiên: P1)

Nhà đầu tư gửi yêu cầu hủy lệnh trong phiên ATO hoặc ATC ➔ Hệ thống kiểm tra trạng thái phiên hiện tại và ngay lập tức từ chối yêu cầu hủy lệnh.

**Lý do ưu tiên**: Đây là quy định pháp lý bắt buộc của Sở Giao dịch Chứng khoán, vi phạm sẽ bị Sở từ chối và phạt.

**Liên quan yêu cầu**: FR-002, FR-003, BR-001

**Test độc lập**: Đưa phiên về `ATO` hoặc `ATC`, gửi lệnh `DELETE /api/orders/{orderId}`, kiểm tra hệ thống trả về lỗi từ chối hủy lệnh; gửi lệnh `LO` thường trong phiên `ATO`/`ATC`, kiểm tra hệ thống từ chối với lý do sai loại lệnh.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** phiên giao dịch đang ở trạng thái `ATO` hoặc `ATC`, **Khi** nhà đầu tư gửi yêu cầu hủy lệnh, **Thì** hệ thống trả về phản hồi thất bại kèm lý do `CancelNotAllowedInCurrentSession`.
2. **AC-002**: **Cho trước** phiên giao dịch đang ở trạng thái `Continuous` (Liên tục), **Khi** nhà đầu tư gửi yêu cầu hủy lệnh hợp lệ, **Thì** hệ thống cho phép hủy lệnh bình thường.
3. **AC-005**: **Cho trước** phiên giao dịch đang ở trạng thái `ATO`, **Khi** nhà đầu tư gửi lệnh loại `ATC`, **Thì** hệ thống trả về phản hồi thất bại kèm lý do `OrderTypeNotAllowedInCurrentSession`.

---

### US-002 — Chuyển đổi trạng thái phiên theo đúng lịch trình từng sàn (Ưu tiên: P1)

Hệ thống tự động chuyển phiên theo lịch trình từng thị trường (Phái sinh mở ATO từ 08:45, HOSE mở ATO từ 09:00, HNX/UPCoM mở Continuous từ 09:00).

**Lý do ưu tiên**: Đảm bảo đồng bộ thời gian và loại lệnh cho từng sàn.

**Liên quan yêu cầu**: FR-001, FR-004

**Test độc lập**: Kiểm tra luồng chuyển phiên của Worker cho từng sàn `HOSE`, `HNX`, `UPCOM`, `Phái sinh`.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** thị trường Phái sinh (`DERIVATIVES`), **Khi** đến 08:45, **Thì** phiên giao dịch chuyển sang `ATO`.
2. **AC-004**: **Cho trước** thị trường `UPCOM`, **Khi** đến 09:00, **Thì** phiên giao dịch chuyển thẳng sang `Continuous` (không qua `ATO`).

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Hủy lệnh trong phiên định kỳ**: Trả về lỗi `CancelNotAllowedInCurrentSession`.
- **Đặt lệnh sai loại trong phiên**: Trả về lỗi `OrderTypeNotAllowedInCurrentSession`.
- **Hệ thống nghỉ trưa**: Chấp nhận lệnh chờ (Queue) nhưng không khớp lệnh cho đến phiên chiều.
- **Đặt lệnh trong `PreOpen`**: Hệ thống từ chối mọi lệnh gửi vào (trả lỗi `SessionNotOpen`), không giữ hàng đợi chờ như `Intermission`.
- **Đặt lệnh trong `PLO`**: Hệ thống từ chối mọi lệnh gửi vào (trả lỗi `SessionClosed`), vì cơ chế khớp lệnh PLO chưa được triển khai trong MVP này (xem mục 13).
- **Ghi CSDL thất bại khi chuyển phiên**: Hệ thống PHẢI thử lại việc ghi trạng thái phiên; trạng thái phiên KHÔNG được coi là đã chuyển (kể cả in-memory và phát sự kiện WebSocket) cho đến khi ghi CSDL thành công.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI hỗ trợ máy trạng thái phiên đầy đủ: `PreOpen`, `ATO`, `Continuous`, `Intermission`, `ATC`, `PLO`, `Close`.  
  **Liên quan**: US-002, AC-003, AC-004
- **FR-002** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép hủy lệnh khi phiên đang ở trạng thái `ATO` hoặc `ATC`. (Chặn sửa lệnh nằm ngoài phạm vi MVP này — xem mục 13, vì hệ thống hiện chưa có chức năng sửa lệnh.)  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI cho phép đặt lệnh `LO` và lệnh định kỳ tương ứng (`ATO`/`ATC`) trong phiên `ATO`/`ATC`, và PHẢI từ chối đặt lệnh `ATO`/`ATC` ngoài phiên định kỳ của chúng.  
  **Liên quan**: US-001, AC-001, MVP-004
- **FR-004** `[P1]`: Hệ thống PHẢI áp dụng đúng sơ đồ thời gian phiên riêng biệt cho từng thị trường (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`).  
  **Liên quan**: US-002, AC-003, AC-004
- **FR-005** `[P2]`: Dịch vụ `ISessionService` PHẢI cung cấp phương thức `IsAllowingCancel(market)` để kiểm tra quyền hủy lệnh.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-006** `[P2]`: Dịch vụ `ISessionService` PHẢI cung cấp phương thức kiểm tra loại lệnh được phép theo phiên hiện tại (ví dụ `IsOrderTypeAllowed(market, orderType)`).  
  **Liên quan**: US-001, MVP-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Trong các phiên định kỳ `ATO` (09:00-09:15 HOSE / 08:45-09:00 Phái sinh) và `ATC` (14:30-14:45 HOSE, HNX, Phái sinh), **CẤM HỦY LỆNH**. Chỉ được đặt lệnh `LO` và lệnh định kỳ tương ứng (`ATO` trong phiên ATO, `ATC` trong phiên ATC).
- **BR-002**: Sàn `UPCoM` không có phiên `ATO` và `ATC`, chỉ có phiên `Continuous` từ 09:00 đến 15:00 (nghỉ trưa 11:30 - 13:00).
- **BR-003**: Sàn `HNX` cơ sở không có phiên `ATO` (bắt đầu 09:00 Continuous), có phiên `ATC` (14:30-14:45) và phiên `PLO` (14:45-15:00).
- **BR-004**: Khi phiên chuyển sang `Close` (từ `ATC` trực tiếp hoặc sau `PLO`), hệ thống PHẢI hủy toàn bộ lệnh trong ngày chưa khớp còn lại trong sổ lệnh (kế thừa quy tắc cuối ngày hiện có của `flex-exchange-service`). Không có lệnh nào được tồn tại qua trạng thái `Close`.
- **BR-005**: Trong trạng thái `PreOpen`, hệ thống KHÔNG được nhận bất kỳ lệnh nào (kể cả vào hàng đợi chờ) — mọi lệnh gửi vào bị từ chối với lý do `SessionNotOpen`, khác với `Intermission` (vẫn nhận lệnh chờ).
- **BR-006**: Trong trạng thái `PLO`, hệ thống KHÔNG được nhận bất kỳ lệnh nào — mọi lệnh gửi vào bị từ chối với lý do `SessionClosed`, vì cơ chế khớp lệnh sau giờ (PLO) chưa được triển khai trong MVP này.
- **BR-007**: Khi chuyển trạng thái phiên, hệ thống PHẢI ghi nhận trạng thái mới vào CSDL thành công trước khi coi transition là hoàn tất (cập nhật in-memory và phát `SESSION_STATE_CHANGED`). Nếu ghi CSDL thất bại, hệ thống PHẢI thử lại thay vì tiếp tục với trạng thái chỉ tồn tại in-memory — đây là thay đổi so với hành vi hiện tại của `flex-exchange-service` (chỉ log lỗi rồi vẫn tiếp tục). Chính sách thử lại/timeout cụ thể sẽ được quyết định ở bước lập plan kỹ thuật.

**Luồng trạng thái phiên chuẩn**:

| Trạng thái hiện tại | Hành động chuyển phiên | Trạng thái tiếp theo | Điều kiện / Ghi chú |
|---|---|---|---|
| `PreOpen` | Đến giờ mở cửa ATO | `ATO` | HOSE (09:00), Phái sinh (08:45) |
| `PreOpen` | Đến giờ mở cửa Continuous | `Continuous` | HNX (09:00), UPCoM (09:00) |
| `ATO` | Hết thời lượng phiên ATO (timer) | `Continuous` | 09:15 HOSE / 09:00 Phái sinh — chuyển theo thời gian cấu hình, không tính giá khớp duy nhất trong MVP này |
| `Continuous` (Sáng) | Đến giờ nghỉ trưa | `Intermission` | 11:30 |
| `Intermission` | Đến giờ chiều | `Continuous` | 13:00 |
| `Continuous` (Chiều) | Đến phiên đóng cửa | `ATC` | 14:30 (HOSE, HNX, Phái sinh) |
| `ATC` | Hết thời lượng phiên ATC (timer) | `PLO` / `Close` | 14:45 (HNX sang PLO, HOSE sang Close) — chuyển theo thời gian cấu hình, không tính giá khớp duy nhất trong MVP này |
| `PLO` | Hết giờ giao dịch sau giờ | `Close` | 15:00 |

---

## 9. Thực thể dữ liệu

- **SessionDto**: Đại diện cho phiên giao dịch của một thị trường (`sessionId`, `market`, `sessionDate`, `status`, `openedAt`, `closedAt`).
- **SessionOrderTypeRule**: Quy tắc ánh xạ trạng thái phiên → loại lệnh được phép cho từng thị trường (`market`, `sessionPhase`, `allowedOrderTypes`), dùng để phục vụ FR-003/FR-006.

---

## 10. Phân quyền & Bảo mật

- **SEC-001**: Hệ thống PHẢI kiểm tra trạng thái phiên trước khi thực hiện bất kỳ lệnh hủy hoặc đặt lệnh nào.

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Thời gian kiểm tra van chặn trạng thái phiên phải đạt dưới 1ms để không ảnh hưởng tới hiệu năng đặt/hủy lệnh.
- **NFR-002**: Nếu việc ghi CSDL khi chuyển phiên (BR-007) thất bại liên tục, hệ thống PHẢI ghi log cảnh báo mức độ nghiêm trọng cao sau mỗi lần thử lại thất bại, để người vận hành phát hiện và can thiệp kịp thời (tránh phiên bị treo vô thời hạn mà không ai biết).

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% các yêu cầu hủy lệnh trong phiên ATO và ATC bị hệ thống từ chối thành công.
- **SC-002**: Tất cả 4 thị trường (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`) hoạt động đúng sơ đồ chuyển phiên tương ứng.
- **SC-003**: 100% lệnh sai loại (ví dụ lệnh `LO` thường trong phiên định kỳ, hoặc lệnh `ATO`/`ATC` ngoài phiên định kỳ) bị hệ thống từ chối thành công.

---

## 13. Ngoài phạm vi

- Tích hợp kết nối trực tiếp gateway vật lý với Sở Giao dịch Chứng khoán (ngoài phạm vi Simulator/MVP).
- Chặn/hỗ trợ sửa lệnh (amend order): hệ thống hiện chưa có chức năng sửa lệnh, nên quy tắc cấm sửa lệnh trong ATO/ATC sẽ được bổ sung khi tính năng sửa lệnh được xây dựng.
- Cơ chế khớp lệnh thực sự trong phiên `PLO` (khớp liên tục tại giá đóng cửa ATC, ưu tiên thời gian): MVP này chỉ triển khai `PLO` như một trạng thái chuyển tiếp trong máy trạng thái, chưa triển khai logic khớp lệnh riêng cho PLO.
- Các loại lệnh `MP`, `MTL`, `MOK`, `MAK`: hệ thống hiện chưa có khái niệm `OrderType` mở rộng này; MVP chỉ kiểm soát `LO`, `ATO`, `ATC`.
- Thuật toán đấu giá định kỳ (uniform-price call auction) xác định giá khớp duy nhất cho ATO/ATC: chuyển trạng thái `ATO`→`Continuous` và `ATC`→`PLO`/`Close` chỉ dựa trên thời lượng cấu hình (timer), không tính toán giá khớp lệnh thực sự trong MVP này.

---

## Clarifications

### Session 2026-07-26

- Q: Chuyển trạng thái `ATO`→`Continuous` và `ATC`→`PLO`/`Close` có cần thuật toán đấu giá định kỳ thực sự (tìm giá khớp duy nhất) hay chỉ là chuyển theo thời gian (timer)? → A: Chuyển theo thời gian (timer) thuần túy — không xây thuật toán đấu giá thực sự trong MVP này, giá ATO/ATC nằm ngoài phạm vi.
- Q: Trong trạng thái `PreOpen`, lệnh gửi vào có được nhận vào hàng đợi chờ hay bị từ chối hoàn toàn? → A: Từ chối tất cả lệnh trong `PreOpen` (giống hành vi `Open` hiện tại), không giữ hàng đợi chờ.
- Q: Trong trạng thái `PLO`, hệ thống xử lý lệnh gửi vào như thế nào? → A: Từ chối tất cả lệnh trong `PLO` (trả lỗi `SessionClosed`) — coi như chưa hỗ trợ giao dịch sau giờ trong MVP.
- Q: Khi lưu trạng thái phiên vào CSDL thất bại lúc chuyển phase, hệ thống có nên tiếp tục chuyển trạng thái in-memory hay dừng/rollback? → A: Chặn transition, giữ nguyên trạng thái cũ cho đến khi ghi CSDL thành công (đảm bảo nhất quán tuyệt đối) — khác với hành vi best-effort hiện tại.
