# API Contracts: Danh sách Thị trường (`Markets API`)

**Feature**: `000021-market-database-config`  
**Service**: `flex-exchange-service` / `flex-api-gateway`  

---

## 1. `GET /api/v1/markets`

Lấy danh sách các thị trường chứng khoán khả dụng trong hệ thống.

### Request Headers
* `Accept: application/json`

### Response (200 OK)
```json
{
  "success": true,
  "errorCode": "SUCCESS",
  "message": "Lấy danh sách thị trường thành công.",
  "data": [
    {
      "marketCode": "HOSE",
      "marketName": "Sở Giao dịch Chứng khoán TP.HCM",
      "status": "active",
      "hasAto": true,
      "hasPlo": false
    },
    {
      "marketCode": "HNX",
      "marketName": "Sở Giao dịch Chứng khoán Hà Nội",
      "status": "active",
      "hasAto": false,
      "hasPlo": true
    },
    {
      "marketCode": "UPCOM",
      "marketName": "Thị trường Công ty Đại chúng chưa niêm yết",
      "status": "active",
      "hasAto": false,
      "hasPlo": false
    },
    {
      "marketCode": "DERIVATIVES",
      "marketName": "Thị trường Chứng khoán Phái sinh",
      "status": "active",
      "hasAto": true,
      "hasPlo": false
    }
  ]
}
```

---

## 2. `GET /api/v1/markets/{marketCode}`

Lấy thông tin chi tiết và cấu hình phiên của một thị trường cụ thể.

### Request Parameters
* `marketCode` (path, string, required): Mã thị trường (VD: `HOSE`).

### Response (200 OK)
```json
{
  "success": true,
  "errorCode": "SUCCESS",
  "message": "Thành công.",
  "data": {
    "marketCode": "HOSE",
    "marketName": "Sở Giao dịch Chứng khoán TP.HCM",
    "status": "active",
    "hasAto": true,
    "hasPlo": false,
    "preOpenDurationSeconds": 5,
    "atoDurationSeconds": 10,
    "continuousDurationSeconds": 30,
    "intermissionDurationSeconds": 5,
    "continuous2DurationSeconds": 30,
    "atcDurationSeconds": 10,
    "ploDurationSeconds": 0
  }
}
```

### Response (404 Not Found)
```json
{
  "success": false,
  "errorCode": "MARKET_NOT_FOUND",
  "message": "Không tìm thấy thị trường 'XYZ'.",
  "data": null
}
```
