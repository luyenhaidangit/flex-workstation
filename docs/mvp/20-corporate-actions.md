# MVP 20 — Corporate actions đầy đủ

## Mục tiêu

Mô phỏng toàn bộ vòng đời corporate action từ công bố đến điều chỉnh danh mục và ledger, bao gồm các loại phổ biến trên thị trường chứng khoán Việt Nam.

## Phạm vi

- Cổ tức tiền (cash dividend): chi trả tiền theo số CK tại record date.
- Cổ tức cổ phiếu (stock dividend): phát thêm CK tỷ lệ; điều chỉnh giá tham chiếu ngày ex-date.
- Phát hành quyền mua (rights issue): cổ đông hiện hữu được mua thêm CK giá ưu đãi trong thời hạn.
- Tách/gộp cổ phiếu (stock split/reverse split): điều chỉnh đồng thời giá, số lượng CK và tham số lot size.
- Mỗi corporate action có announcement date, ex-date, record date và payment/effective date.

## Luồng xử lý

1. Admin công bố corporate action với đầy đủ tham số và ngày.
2. Đến ex-date: giá tham chiếu điều chỉnh tự động; lệnh GTC cũng được điều chỉnh.
3. Đến record date: snapshot danh sách sở hữu để xác định đối tượng hưởng quyền.
4. Đến payment/effective date: ledger ghi bút toán tương ứng cho từng tài khoản đủ điều kiện.

## Kịch bản demo

Công bố cổ tức cổ phiếu 10%; tua thời gian đến ex-date và xác nhận giá tham chiếu giảm đúng; tua đến payment date và xác nhận số CK trong danh mục tăng tương ứng; kiểm tra bút toán ledger có đủ tham chiếu nguồn.

## Điều kiện hoàn thành

- Bút toán ledger có đầy đủ audit trail tới corporate action nguồn.
- Điều chỉnh giá tham chiếu đúng công thức; lệnh GTC đang chờ được cập nhật.
- Chưa có spin-off, merger/acquisition, delisting hay phiên đặc biệt xử lý quyền lô lẻ.
