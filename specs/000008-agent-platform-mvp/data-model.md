# Data Model: Nền tảng AI Agent đa tenant — MVP

**Feature**: `000008-agent-platform-mvp` | **Ngày**: 2026-07-12

Chia miền dữ liệu theo tài liệu kiến trúc: PostgreSQL = control plane + runtime catalog; MySQL database-per-tenant = dữ liệu vận hành; Qdrant = vector; MinIO = file gốc. Migration PostgreSQL: `flex-environment/migrations/002_create_agent_platform_control_plane.sql`.

---

## 1. PostgreSQL `flexdb` — Control plane + Runtime catalog

### Bảng tái dùng từ 000005 (chỉ đọc/ghi theo contract sẵn có — KHÔNG alter)

- **`tenant_databases`** — registry tenant → MySQL database (`tenant_id`, `db_name`, `db_user`, `db_host`, `db_port`, `status: provisioning|active|error|deleting`, `schema_version`, `status_reason`, `provisioned_at`). Provisioning của platform ghi qua đúng flow 000005.
- **`tenant_database_audit_logs`** — audit provisioning mức hạ tầng (giữ nguyên).

### Bảng mới (migration 002)

#### `platform_users`
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | uuid PK | |
| email | text | UNIQUE, NOT NULL |
| password_hash | text | NOT NULL |
| display_name | text | NOT NULL |
| is_platform_admin | boolean | default false |
| created_at | timestamptz | NOT NULL |

#### `tenant_members`
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | uuid PK | |
| tenant_id | text | NOT NULL, FK→tenant_databases(tenant_id) |
| user_id | uuid | NOT NULL, FK→platform_users |
| role | text | NOT NULL, CHECK in ('owner','editor','viewer') |
| created_at | timestamptz | NOT NULL |
| | | UNIQUE(tenant_id, user_id) |

Quy tắc: mỗi tenant có ≥ 1 owner; không cho hạ role/xóa owner cuối cùng (BR-003).

#### `agents_runtime` — con trỏ runtime per agent (FR-014, FR-016)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| agent_id | uuid PK | (id agent bên tenant DB) |
| tenant_id | text | NOT NULL — `owner_tenant_id` theo tài liệu kiến trúc |
| active_version | int | NULL = chưa/đã gỡ phát hành |
| status | text | CHECK in ('published','unpublished') |
| updated_at | timestamptz | |

#### `agent_versions` — snapshot bất biến (BR-002)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | uuid PK | |
| agent_id | uuid | NOT NULL |
| tenant_id | text | NOT NULL |
| version | int | NOT NULL, UNIQUE(agent_id, version) |
| visibility | text | NOT NULL default 'private' (MVP chỉ 'private' — BR-001) |
| config_json | jsonb | NOT NULL — name, persona, instructions, greeting |
| source_ids_json | jsonb | NOT NULL — danh sách knowledge source id lúc publish |
| content_hash | text | NOT NULL — idempotency publish (spec §5) |
| published_by | uuid | NOT NULL |
| published_at | timestamptz | NOT NULL |

Bất biến: chỉ INSERT, không UPDATE/DELETE (enforce ở tầng app; không cấp quyền sửa qua API).

#### `widget_keys` (FR-012, FR-016)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| key | text PK | random 32+ ký tự |
| agent_id | uuid | NOT NULL, UNIQUE — 1 key active per agent ở MVP |
| tenant_id | text | NOT NULL |
| status | text | CHECK in ('active','revoked') |
| created_at | timestamptz | |

Key trỏ `agent_id` (không trỏ version) → rollback không đổi snippet (FR-016).

#### `audit_logs` — append-only (FR-021, BR-006)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | bigserial PK | |
| tenant_id | text | NULL với thao tác platform-level |
| actor_user_id | uuid | NULL với hệ thống |
| actor_role | text | |
| action | text | NOT NULL — `tenant.provisioned`, `tenant.suspended`, `agent.created`, `agent.updated`, `agent.published`, `agent.rolled_back`, `agent.unpublished`, `source.uploaded`, `source.deleted`, `member.role_changed` |
| object_type | text | NOT NULL |
| object_id | text | NOT NULL |
| detail_json | jsonb | KHÔNG chứa secret/password (spec §10) |
| result | text | CHECK in ('success','failure') |
| created_at | timestamptz | NOT NULL |

Không có API/endpoint UPDATE/DELETE; user DB của app không được cấp quyền DELETE trên bảng này.

#### `usage_daily` (FR-019)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| tenant_id | text | PK part |
| usage_date | date | PK part |
| conversations | int | default 0 |
| messages | int | default 0 |
| tokens_in / tokens_out | bigint | default 0 |

Chỉ đếm hội thoại thật (`is_test=false` — FR-010); upsert increment.

#### `outbox_events` (DEC-007)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | bigserial PK | |
| event_type | text | NOT NULL — `agent.published`, … |
| payload_json | jsonb | NOT NULL |
| created_at | timestamptz | NOT NULL |
| processed_at | timestamptz | NULL = chưa dispatch |

Ghi cùng transaction với `agent_versions`; dispatcher poll và đánh dấu processed (at-least-once).

#### `refresh_tokens`
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| token_hash | text PK | |
| user_id | uuid | NOT NULL |
| expires_at | timestamptz | NOT NULL |
| revoked_at | timestamptz | NULL |

---

## 2. MySQL — schema tenant v1 (apply lúc provisioning, `schema_version=1`)

Mỗi tenant một database `tenant_{sanitized_id}` (quy ước 000005). DDL nhúng trong `Data/TenantSchema/v1.sql` của platform.

#### `agents` — draft (US-002)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | char(36) PK | uuid |
| name | varchar(200) | NOT NULL, UNIQUE trong tenant (spec §5) |
| persona | text | |
| instructions | text | NOT NULL |
| greeting | text | |
| row_version | int | NOT NULL — optimistic concurrency (spec §5) |
| created_by / updated_by | char(36) | |
| created_at / updated_at | datetime | |

#### `knowledge_sources` (US-003)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | char(36) PK | |
| agent_id | char(36) | NOT NULL, FK→agents |
| file_name | varchar(500) | NOT NULL |
| file_type | varchar(20) | CHECK in ('pdf','docx','txt') (FR-006) |
| file_size_bytes | bigint | ≤ 10 MB validate ở app (FR-007) |
| storage_object | varchar(500) | NOT NULL — MinIO object key |
| status | varchar(20) | CHECK in ('processing','ready','error') |
| error_reason | text | NULL |
| chunk_count | int | default 0 |
| created_at / updated_at | datetime | |

Chuyển trạng thái: `processing → ready` | `processing → error`; xóa record đi kèm xóa Qdrant points + MinIO object (FR-008).

#### `conversations` (US-004, US-005)
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | char(36) PK | |
| agent_id | char(36) | NOT NULL |
| agent_version | int | NULL khi test-chat draft |
| is_test | tinyint(1) | NOT NULL — tách thử/thật (FR-010) |
| started_at / last_message_at | datetime | |

#### `messages`
| Cột | Kiểu | Ràng buộc |
|-----|------|-----------|
| id | char(36) PK | |
| conversation_id | char(36) | NOT NULL, FK→conversations |
| sender | varchar(10) | CHECK in ('user','agent') |
| content | mediumtext | NOT NULL |
| tokens | int | default 0 |
| created_at | datetime(3) | NOT NULL |

---

## 3. Qdrant — collection `knowledge_chunks`

- Vector: 768d, Cosine (khớp `nomic-embed-text-v2-moe`).
- Point ID: deterministic `uuid5(source_id, chunk_index)` — ingestion idempotent.
- Payload: `tenant_id` (indexed), `agent_id` (indexed), `source_id` (indexed), `chunk_index`, `text`.
- **Bất biến truy vấn**: mọi search PHẢI có filter `tenant_id` + `agent_id` (FR-020, SEC-002); xóa source = delete by filter `source_id`.

## 4. MinIO

- Bucket per tenant: `tenant-{sanitized_id}` (tạo lúc provisioning).
- Object key: `knowledge/{source_id}/{file_name}`.
- Không public access; chỉ platform service account đọc/ghi.

---

## 5. Quan hệ tổng thể

```text
platform_users ──< tenant_members >── tenant_databases (000005)
                                            │ 1:1 theo tenant_id
                                            ▼
                              MySQL tenant_{id}: agents ──< knowledge_sources
                                                  │              │
                                                  │              ├── MinIO object
                                                  │              └── Qdrant points (payload tenant_id/agent_id/source_id)
                                                  └──< conversations ──< messages

agents_runtime (PG) ── active_version ──> agent_versions (PG, immutable)
       ▲                                        ▲
widget_keys (PG) ── agent_id                    └── source_ids_json → Qdrant filter lúc RAG public
audit_logs / usage_daily / outbox_events (PG) — cross-cutting
```

**Ánh xạ thực thể spec §8 → schema**: Tenant → `tenant_databases` (+bucket, +MySQL db); Thành viên & vai trò → `platform_users` + `tenant_members`; Agent → `agents` (tenant DB); Phiên bản agent → `agent_versions` + `agents_runtime`; Nguồn tri thức → `knowledge_sources` + MinIO + Qdrant; Hội thoại → `conversations` + `messages`; Bản ghi audit → `audit_logs`; Chỉ số sử dụng → `usage_daily`.
