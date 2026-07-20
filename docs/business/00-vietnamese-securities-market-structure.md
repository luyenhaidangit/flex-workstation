# Cấu trúc thị trường chứng khoán Việt Nam

## Mục đích

Tài liệu này thống nhất cách gọi tổ chức, thị trường và sản phẩm trong FlexSim. Nó là ngữ cảnh nghiệp vụ chung cho các MVP có liên quan đến giao dịch; không thay thế quy định pháp lý hoặc quy chế giao dịch của từng thị trường.

## Phân biệt tổ chức và thị trường

- **VNX** là Sở Giao dịch Chứng khoán Việt Nam, công ty mẹ của HOSE và HNX. `VNX` không phải là một thị trường khớp lệnh nên không dùng làm giá trị `market`.
- **HOSE** và **HNX** là các sở giao dịch vận hành những phân đoạn thị trường khác nhau.
- **Thị trường** là nơi một nhóm công cụ được tổ chức giao dịch theo cùng quy tắc. Trong hệ thống, đây là ý nghĩa của trường `market`.
- **Sản phẩm/công cụ** là đối tượng giao dịch cụ thể, ví dụ cổ phiếu, trái phiếu, ETF, chứng quyền hoặc hợp đồng tương lai.

## Các phân đoạn thị trường

| Giá trị `market` định hướng | Phân đoạn giao dịch | Đơn vị vận hành | Sản phẩm chính |
| --- | --- | --- | --- |
| `HOSE` | Cổ phiếu niêm yết tại TP. Hồ Chí Minh | HOSE | Cổ phiếu, ETF, chứng quyền, quỹ niêm yết |
| `HNX` | Cổ phiếu niêm yết tại Hà Nội | HNX | Cổ phiếu niêm yết |
| `UPCOM` | Cổ phiếu đăng ký giao dịch | HNX | Cổ phiếu công ty đại chúng chưa niêm yết |
| `GOV_BOND` | Trái phiếu Chính phủ | HNX | Trái phiếu Chính phủ, chính quyền địa phương, được Chính phủ bảo lãnh |
| `CORP_BOND_LISTED` | Trái phiếu doanh nghiệp niêm yết | HNX | Trái phiếu doanh nghiệp niêm yết |
| `CORP_BOND_PRIVATE` | Trái phiếu doanh nghiệp riêng lẻ | HNX | Trái phiếu doanh nghiệp phát hành riêng lẻ |
| `DERIVATIVES` | Chứng khoán phái sinh | HNX | Hợp đồng tương lai và các sản phẩm phái sinh |

HNX công bố đang vận hành các thị trường cổ phiếu niêm yết, UPCoM, trái phiếu Chính phủ, trái phiếu doanh nghiệp, trái phiếu doanh nghiệp riêng lẻ và chứng khoán phái sinh. Xem [HNX — Hỏi đáp](https://upcom.hnx.vn/vi-vn/hoi-dap.html).

## Áp dụng cho MVP 01

Quy tắc khớp lệnh của MVP 01 là quy tắc tổng quát theo ưu tiên giá-thời gian. Tài liệu nghiệp vụ hiện dùng HOSE làm nguồn tham chiếu cho ví dụ và quy tắc thị trường.

Phần triển khai DB-backed của MVP 01 hiện chỉ phục vụ cổ phiếu niêm yết tại HNX. Vì vậy, trong phạm vi này:

- `exchange_instruments.market = 'HNX'`.
- `exchange_sessions.market = 'HNX'`.
- Các giá trị `market` khác chỉ là quy ước cho feature mở rộng sau này; không được đưa vào seed hay luồng khớp lệnh hiện tại.

Khi mở rộng sang một thị trường hoặc loại sản phẩm khác, phải đặc tả riêng quy tắc phiên, loại lệnh, bước giá, biên độ, lô giao dịch, điều kiện nhà đầu tư và hậu giao dịch. Không được giả định các quy tắc của `HNX`, `HOSE`, `UPCOM`, trái phiếu và phái sinh là giống nhau.
