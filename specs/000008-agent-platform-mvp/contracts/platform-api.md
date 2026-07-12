# Contract: Platform REST API

**Feature**: `000008-agent-platform-mvp` | Base URL: qua HAProxy → `flex-agent-platform`

Quy ước chung:
- Auth: `Authorization: Bearer <JWT>` (claims: `sub`, `tenant_id`, `role`), trừ nhóm `/api/public` và `/api/auth/login`.
- Tenant context lấy từ claim — endpoint `/api/tenant/*` KHÔNG nhận `tenantId` trong body/query (BR-004).
- Error format thống nhất: `{ "error": { "code": "<machine_code>", "message": "<vi message>" } }`.
- Status codes: 400 validation, 401 chưa auth, 403 sai role/khác tenant, 404 không tồn tại (hoặc khác tenant — không phân biệt để tránh dò), 409 conflict, 410 gone (widget revoked), 429 rate limit.

---

## Auth

| Method | Path | Role | Mô tả |
|--------|------|------|-------|
| POST | `/api/auth/login` | anonymous | Body `{email, password}` → `{accessToken, refreshToken, tenantId, role}` |
| POST | `/api/auth/refresh` | anonymous | Body `{refreshToken}` → cặp token mới |

## Platform (quản trị nền tảng)

| Method | Path | Role | Mô tả |
|--------|------|------|-------|
| POST | `/api/platform/tenants` | platform_admin | Body `{tenantId, tenantName, ownerEmail, ownerPassword}` → 201 `{tenantId, status}`; 409 nếu trùng (FR-002); fail giữa chừng → 500 + status=`error`, không orphan (AC-003) |
| GET | `/api/platform/tenants` | platform_admin | Danh sách tenant + status |
| POST | `/api/platform/tenants/{id}/suspend` | platform_admin | Tạm ngưng tenant; audit |
| GET | `/api/platform/usage` | platform_admin | Usage tổng hợp theo tenant |

## Tenant — Agents (US-002)

| Method | Path | Role tối thiểu | Mô tả |
|--------|------|----------------|-------|
| GET | `/api/tenant/agents` | viewer | Danh sách agent + trạng thái publish (join `agents_runtime`) |
| POST | `/api/tenant/agents` | editor | Body `{name, persona?, instructions, greeting?}` → 201; 409 nếu trùng tên |
| GET | `/api/tenant/agents/{id}` | viewer | Chi tiết draft |
| PUT | `/api/tenant/agents/{id}` | editor | Body kèm `rowVersion`; 409 nếu conflict (spec §5) |
| DELETE | `/api/tenant/agents/{id}` | owner | Chỉ khi đã unpublished |

## Tenant — Knowledge (US-003)

| Method | Path | Role tối thiểu | Mô tả |
|--------|------|----------------|-------|
| POST | `/api/tenant/agents/{id}/sources` | editor | multipart file (pdf/docx/txt, ≤ 10 MB) → 202 `{sourceId, status: "processing"}`; 400 sai định dạng/size (FR-007) |
| GET | `/api/tenant/agents/{id}/sources` | viewer | Danh sách + status (`processing/ready/error` + `errorReason`) |
| POST | `/api/tenant/sources/{id}/retry` | editor | Re-queue ingestion khi status=error |
| DELETE | `/api/tenant/sources/{id}` | editor | Xóa record + Qdrant points + MinIO object (FR-008) |

## Tenant — Publishing & Versions (US-005, US-006)

| Method | Path | Role tối thiểu | Mô tả |
|--------|------|----------------|-------|
| POST | `/api/tenant/agents/{id}/publish` | owner | → 201 `{version, widgetKey, embedSnippet}`; idempotent theo content-hash: draft không đổi → 200 version hiện tại, không tạo mới (spec §5) |
| GET | `/api/tenant/agents/{id}/versions` | viewer | Danh sách version (số, thời điểm, người publish, active) |
| POST | `/api/tenant/agents/{id}/versions/{n}/activate` | owner | Rollback/kích hoạt version n (FR-015); audit từ→về (AC-015) |
| POST | `/api/tenant/agents/{id}/unpublish` | owner | Gỡ phát hành; widget trả 410 |

## Tenant — Members (US-007)

| Method | Path | Role tối thiểu | Mô tả |
|--------|------|----------------|-------|
| GET | `/api/tenant/members` | viewer | Danh sách thành viên + role |
| POST | `/api/tenant/members` | owner | Body `{email, displayName, password, role}` → tạo user + membership |
| PUT | `/api/tenant/members/{userId}` | owner | Đổi role; 409 nếu hạ owner cuối cùng |
| DELETE | `/api/tenant/members/{userId}` | owner | Gỡ thành viên; 409 nếu owner cuối |

## Tenant — Usage (US-008)

| Method | Path | Role tối thiểu | Mô tả |
|--------|------|----------------|-------|
| GET | `/api/tenant/usage?from=&to=` | viewer | `[{date, conversations, messages, tokensIn, tokensOut}]` — chỉ tenant của claim (AC-018) |

## Public (widget)

| Method | Path | Auth | Mô tả |
|--------|------|------|-------|
| POST | `/api/public/chat/sessions` | widget key (body `{widgetKey}`) | → `{sessionToken, greeting, agentName}`; 410 nếu key revoked/agent unpublished; rate limit theo key+IP (SEC-004) |
| GET | `/widget/flex-agent-widget.js` | anonymous | Bundle widget (immutable-cache theo version) |

## Event (outbox — nội bộ)

| Event | Payload | Ghi chú |
|-------|---------|---------|
| `agent.published` | `{tenantId, agentId, version, publishedBy, publishedAt}` | Ghi cùng transaction publish; dispatcher đánh dấu processed. MVP chưa có consumer ngoài — giữ cho analytics/channel connector giai đoạn sau |

## Quy tắc kiểm thử contract

- Mỗi endpoint: happy path + case 403 (role thấp hơn yêu cầu) + case cross-tenant (token tenant khác → 404/403).
- Error body đúng format thống nhất.
- Publish idempotency: 2 lần publish liên tiếp cùng draft → cùng version.
