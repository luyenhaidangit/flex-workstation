---
paths:
  - "src/api/**/*.{ts,js}"
  - "src/routes/**/*.{ts,js}"
---

# API rules

- Mọi endpoint validate input bằng TODO_Zod schema đặt ở `TODO_src/api/schemas/`. Không tin `req.body`.
- Lỗi trả về đúng envelope chung:

```ts
// 4xx/5xx luôn có shape này — client đang phụ thuộc vào nó
{ error: { code: 'INVALID_INPUT', message: string, details?: unknown } }
```

- Status code: 200 đọc, 201 tạo (kèm `Location`), 204 xoá, 400 validate, 401 chưa auth, 403 không đủ quyền, 409 xung đột state, 422 hợp lệ về cú pháp nhưng sai nghiệp vụ.
- Handler chỉ làm: validate → gọi service → map sang response. KHÔNG đặt business logic hay truy vấn DB trong handler.
- Mọi endpoint mới phải khai báo trong TODO_`openapi.yaml` cùng PR.
- Đổi/xoá field trong response là **breaking change**: dừng lại và hỏi trước khi làm.
- Log: dùng logger có sẵn với `requestId`. NEVER log PII, token, password.
- Pagination theo cursor (`?cursor=&limit=`), không offset. Mặc định `limit=50`, tối đa `200`.
