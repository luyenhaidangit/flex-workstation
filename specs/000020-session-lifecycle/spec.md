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

**Liên quan yêu cầu**: FR-002, BR-001

**Test độc lập**: Đưa phiên về `ATO` hoặc `ATC`, gửi lệnh `DELETE /api/orders/{orderId}`, kiểm tra hệ thống trả về lỗi từ chối hủy lệnh.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** phiên giao dịch đang ở trạng thái `ATO` hoặc `ATC`, **Khi** nhà đầu tư gửi yêu cầu hủy lệnh, **Thì** hệ thống trả về phản hồi thất bại kèm lý do `CancelNotAllowedInCurrentSession`.
2. **AC-002**: **Cho trước** phiên giao dịch đang ở trạng thái `Continuous` (Liên tục), **Khi** nhà đầu tư gửi yêu cầu hủy lệnh hợp lệ, **Thì** hệ thống cho phép hủy lệnh bình thường.

---

### US-002 — Chuyển đổi trạng thái phiên theo đúng lịch trình từng sàn (Ưu tiên: P1)

Hệ thống tự động chuyển phiên theo lịch trình từng thị trường (Phái sinh mở ATO từ 08:45, HOSE mở ATO từ 09:00, HNX/UPCoM mở Continuous từ 09:00).

**Lý do ưu tiên**: Đảm bảo đồng bộ thời gian và loại lệnh cho từng sàn.

**Liên quan yêu cầu**: FR-001, FR-004

**Test độc lập**: Kiểm tra luồng chuyển phiên của Worker cho từng sàn `HOSE`, `HNX`, `UPCoM`, `Phái sinh`.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** thị trường Phái sinh (`HNX-Derivatives`), **Khi** đến 08:45, **Thì** phiên giao dịch chuyển sang `ATO`.
2. **AC-004**: **Cho trước** thị trường `UPCoM`, **Khi** đến 09:00, **Thì** phiên giao dịch chuyển thẳng sang `Continuous` (không qua `ATO`).

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Hủy lệnh trong phiên định kỳ**: Trả về lỗi `CancelNotAllowedInCurrentSession`.
- **Đặt lệnh sai loại trong phiên**: Trả về lỗi `OrderTypeNotAllowedInCurrentSession`.
- **Hệ thống nghỉ trưa**: Chấp nhận lệnh chờ (Queue) nhưng không khớp lệnh cho đến phiên chiều.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI hỗ trợ máy trạng thái phiên đầy đủ: `PreOpen`, `ATO`, `Continuous`, `Intermission`, `ATC`, `PLO`, `Close`.  
  **Liên quan**: US-002, AC-003, AC-004
- **FR-002** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép hủy lệnh hoặc sửa lệnh khi phiên đang ở trạng thái `ATO` hoặc `ATC`.  
  **Liên quan**: US-001, AC-001
- **FR-003** `[P1]`: Hệ thống PHẢI từ chối loại lệnh không được phép trong phiên hiện tại.  
  **Liên quan**: US-001, AC-001
- **FR-004** `[P1]`: Hệ thống PHẢI áp dụng đúng sơ đồ thời gian phiên riêng biệt cho từng thị trường (`HOSE`, `HNX`, `UPCoM`, `HNX-Derivatives`).  
  **Liên quan**: US-002, AC-003, AC-004
- **FR-005** `[P2]`: Dịch vụ `ISessionService` PHẢI cung cấp phương thức `IsAllowingCancel(market)` để kiểm tra quyền hủy lệnh.  
  **Liên quan**: US-001, AC-001, AC-002

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Trong các phiên định kỳ `ATO` (09:00-09:15 HOSE / 08:45-09:00 Phái sinh) và `ATC` (14:30-14:45 HOSE, HNX, Phái sinh), **CẤM SỬA VÀ CẤM HỦY LỆNH**.
- **BR-002**: Sàn `UPCoM` không có phiên `ATO` và `ATC`, chỉ có phiên `Continuous` từ 09:00 đến 15:00 (nghỉ trưa 11:30 - 13:00).
- **BR-003**: Sàn `HNX` cơ sở không có phiên `ATO` (bắt đầu 09:00 Continuous), có phiên `ATC` (14:30-14:45) và phiên `PLO` (14:45-15:00).

**Luồng trạng thái phiên chuẩn**:

| Trạng thái hiện tại | Hành động chuyển phiên | Trạng thái tiếp theo | Điều kiện / Ghi chú |
|---|---|---|---|
| `PreOpen` | Đến giờ mở cửa ATO | `ATO` | HOSE (09:00), Phái sinh (08:45) |
| `PreOpen` | Đến giờ mở cửa Continuous | `Continuous` | HNX (09:00), UPCoM (09:00) |
| `ATO` | Khớp lệnh ATO thành công | `Continuous` | 09:15 HOSE / 09:00 Phái sinh |
| `Continuous` (Sáng) | Đến giờ nghỉ trưa | `Intermission` | 11:30 |
| `Intermission` | Đến giờ chiều | `Continuous` | 13:00 |
| `Continuous` (Chiều) | Đến phiên đóng cửa | `ATC` | 14:30 (HOSE, HNX, Phái sinh) |
| `ATC` | Khớp lệnh ATC thành công | `PLO` / `Close` | 14:45 (HNX sang PLO, HOSE sang Close) |
| `PLO` | Hết giờ giao dịch sau giờ | `Close` | 15:00 |

---

## 9. Thực thể dữ liệu

- **SessionDto**: Đại diện cho phiên giao dịch của một thị trường (`sessionId`, `market`, `sessionDate`, `status`, `openedAt`, `closedAt`).

---

## 10. Phân quyền & Bảo mật

- **SEC-001**: Hệ thống PHẢI kiểm tra trạng thái phiên trước khi thực hiện bất kỳ lệnh hủy hoặc đặt lệnh nào.

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Thời gian kiểm tra van chặn trạng thái phiên phải đạt dưới 1ms để không ảnh hưởng tới hiệu năng đặt/hủy lệnh.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% các yêu cầu hủy lệnh trong phiên ATO và ATC bị hệ thống từ chối thành công.
- **SC-002**: Tất cả 4 thị trường (`HOSE`, `HNX`, `UPCoM`, `HNX-Derivatives`) hoạt động đúng sơ đồ chuyển phiên tương ứng.

---

## 13. Ngoài phạm vi

- Tích hợp kết nối trực tiếp gateway vật lý với Sở Giao dịch Chứng khoán (ngoài phạm vi Simulator/MVP).
