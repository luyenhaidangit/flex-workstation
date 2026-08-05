# Contract Delta: Cấu hình kênh phát hành trên API Agent hiện có

**Feature**: `specs/000028-agent-publish-channels` | **Ngày**: 2026-08-05

Tính năng này KHÔNG tạo endpoint mới (xem [research.md](../research.md) TQ-003). Nó mở rộng payload của 2 endpoint đã có, định nghĩa gốc tại [`specs/000026-agent-catalog/contracts/agent-catalog-api.yaml`](../../000026-agent-catalog/contracts/agent-catalog-api.yaml):

- `POST /api/v1/agents`
- `PUT /api/v1/agents/{id}`
- `GET /api/v1/agents` / `GET /api/v1/agents/{id}` (response thêm field, không đổi request)

**Backward compatible**: Có — field mới là optional trên request, thêm mới trên response. Client cũ (chưa biết `publishLocations`) không bị ảnh hưởng.

---

## Field mới trên request: `CreateAgentRequest` / `UpdateAgentRequest`

```yaml
publishLocations:
  type: array
  nullable: true
  description: >
    Danh sách cấu hình kênh phát hành cần lưu cùng lúc với thông tin chung (BR-004/FR-008 —
    dùng chung 1 hành động Lưu). Không truyền hoặc mảng rỗng nghĩa là không có gì thay đổi ở
    cấu hình kênh.
  items:
    $ref: '#/components/schemas/PublishLocationRequest'

# Schema mới
PublishLocationRequest:
  type: object
  required: [locationCode, isEnabled]
  properties:
    locationCode:
      type: string
      example: "website"
      description: >
        MVP CHỈ chấp nhận "website" (FR-009). Giá trị khác PHẢI bị từ chối 400 —
        xem "Quy tắc validate" bên dưới.
    isEnabled:
      type: boolean
      example: true
```

## Field mới trên response: `AgentResponse`

```yaml
publishLocations:
  type: array
  description: >
    Trạng thái đã lưu của các kênh phát hành cho agent này. Chỉ chứa kênh đã từng được lưu
    (thường chỉ có tối đa 1 phần tử "website" ở MVP); agent chưa cấu hình kênh nào trả về
    mảng rỗng — Frontend tự suy ra "tắt" cho mọi kênh trong catalog tĩnh (AC-006).
  items:
    $ref: '#/components/schemas/PublishLocation'

PublishLocation:
  type: object
  required: [locationCode, isEnabled]
  properties:
    locationCode:
      type: string
      example: "website"
    isEnabled:
      type: boolean
      example: true
```

---

## Quy tắc validate mới (áp dụng cho `POST`/`PUT`)

| Tình huống | HTTP Status | `ErrorResponse.code` |
|---|---|---|
| `publishLocations` chứa `locationCode` ngoài whitelist MVP (khác `"website"`) và `isEnabled = true` | 400 | `PUBLISH_LOCATION_NOT_AVAILABLE` |
| `publishLocations` chứa `locationCode` trùng nhau trong cùng 1 request | 400 | `PUBLISH_LOCATION_DUPLICATE` |

Whitelist MVP tham chiếu ở [data-model.md](../data-model.md) (chỉ `website` được ghi thật; 4 mã còn lại — `facebook_fanpage`, `zalo_oa`, `chatbot`, `zalo_personal` — chỉ tồn tại phía Frontend, gửi lên đều bị từ chối).

**Lưu ý**: Không chặn `locationCode: "website", isEnabled: false` — đây là luồng tắt kênh hợp lệ (US-003).

---

## Ví dụ request/response

**PUT /api/v1/agents/{id}** — bật kênh Website cùng lúc sửa mô tả:

```json
{
  "name": "Support Agent A",
  "description": "Mô tả mới",
  "status": "active",
  "publishLocations": [
    { "locationCode": "website", "isEnabled": true }
  ]
}
```

**200 response**:

```json
{
  "id": "b3f1...",
  "name": "Support Agent A",
  "description": "Mô tả mới",
  "status": "active",
  "createdAt": "2026-07-01T02:00:00Z",
  "updatedAt": "2026-08-05T09:00:00Z",
  "publishLocations": [
    { "locationCode": "website", "isEnabled": true }
  ]
}
```
