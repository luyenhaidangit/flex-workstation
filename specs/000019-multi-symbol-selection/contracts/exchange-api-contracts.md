# Contract API: Tùy chọn Mã Chứng khoán & Sổ Lệnh Đa Mã

## 1. API Danh sách Mã Chứng khoán (Mới)

### `GET /api/instruments`
Lấy danh sách các mã chứng khoán đang ở trạng thái `ACTIVE`.

* **Query Parameters**: Không
* **Response `200 OK`**:
```json
[
  {
    "instrumentId": 1,
    "symbol": "FXS",
    "market": "HNX",
    "status": "ACTIVE"
  },
  {
    "instrumentId": 2,
    "symbol": "HNX",
    "market": "HNX",
    "status": "ACTIVE"
  },
  {
    "instrumentId": 3,
    "symbol": "VND",
    "market": "HNX",
    "status": "ACTIVE"
  }
]
```

---

## 2. API Sổ lệnh theo Mã Chứng khoán (Cập nhật)

### `GET /api/orderbook?symbol={symbol}`
Lấy ảnh chụp tức thời (Snapshot) của Sổ lệnh theo mã chứng khoán chỉ định.

* **Query Parameters**:
  * `symbol` *(string, optional)*: Mã chứng khoán cần lấy Sổ lệnh (Ví dụ: `HNX`). Nếu không truyền, mặc định lấy `FXS`.
* **Response `200 OK`**:
```json
{
  "symbol": "HNX",
  "asOfEventSequence": 12,
  "bids": [
    { "price": 50.0, "totalQuantity": 1000 }
  ],
  "asks": [
    { "price": 50.5, "totalQuantity": 500 }
  ]
}
```

---

## 3. API Băng khớp lệnh theo Mã Chứng khoán (Cập nhật)

### `GET /api/trades?symbol={symbol}`
Lấy danh sách các giao dịch đã khớp thành công theo mã chứng khoán chỉ định.

* **Query Parameters**:
  * `symbol` *(string, optional)*: Mã chứng khoán cần xem lịch sử giao dịch (Ví dụ: `HNX`). Nếu không truyền, mặc định lấy `FXS`.
* **Response `200 OK`**:
```json
[
  {
    "tradeId": 101,
    "symbol": "HNX",
    "price": 50.0,
    "quantity": 200,
    "executedSequence": 1
  }
]
```
