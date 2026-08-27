# Tài liệu nghiệp vụ FlexSim

Index cho tài liệu nghiệp vụ dành cho BA và stakeholder không đọc trực tiếp spec kỹ thuật. Đọc theo thứ tự dưới đây.

## 1. Tài liệu nền (đọc trước tiên)

- [00 — Cấu trúc thị trường chứng khoán Việt Nam](00-vietnamese-securities-market-structure.md): thuật ngữ dùng chung (VNX/HOSE/HNX/UPCOM/market segment). Mọi tài liệu nghiệp vụ khác đều dựa trên thuật ngữ ở đây.

## 2. Tài liệu tổng quan theo nghiệp vụ (MVP)

Mỗi tài liệu mô tả tổng quan một MVP: vai trò thực tế, luồng đầu-cuối, quy tắc nghiệp vụ, phạm vi/ngoài phạm vi.

| Tài liệu | MVP | Nghiệp vụ |
| --- | --- | --- |
| [01-mvp-exchange-matching.md](01-mvp-exchange-matching.md) | MVP 01 | Exchange khớp lệnh — order book, matching engine |
| [02-trading-session-bots.md](02-trading-session-bots.md) | MVP 04 | Phiên giao dịch, realtime và market-maker bot |
| [03-cash-securities-ledger.md](03-cash-securities-ledger.md) | MVP 07 | Ledger tiền và chứng khoán |
| [04-database-clearing-settlement.md](04-database-clearing-settlement.md) | MVP 08 | Database, clearing, settlement và đối chiếu |

## 3. Tài liệu chi tiết cross-cutting (đọc khi cần đào sâu)

Không gắn với một MVP cụ thể — đào sâu kỹ thuật/nghiệp vụ cho một chủ đề xuyên suốt nhiều MVP.

- [05-trading-session-state-machine-exchange-communication.md](05-trading-session-state-machine-exchange-communication.md): chi tiết 7-phase state machine của phiên giao dịch (PreOpen/ATO/Continuous/Intermission/ATC/PLO/Close) và cơ chế giao tiếp Sở-Broker. Đọc sau khi đã đọc tổng quan ở mục 2 (đặc biệt `02-trading-session-bots.md`).

## 4. Nghiệp vụ AI Agent

| Tài liệu | MVP | Nghiệp vụ |
| --- | --- | --- |
| [12-agent-creation-and-configuration.md](12-agent-creation-and-configuration.md) | MVP 12 | Tạo Agent, mở khóa cấu hình và điều kiện kiểm thử |
| [13-meta-channel-connections.md](13-meta-channel-connections.md) | MVP 13 | Kết nối tài khoản Instagram và trang Facebook qua Meta |

## Quy ước

- Mỗi tài liệu tổng quan (mục 2) phải ref về tài liệu nền `00` và, nếu có, tài liệu chi tiết liên quan (mục 3) trong phần "Truy vết và nguồn tham khảo".
- Khi thêm tài liệu nghiệp vụ mới, cập nhật bảng ở mục tương ứng trong file này.
