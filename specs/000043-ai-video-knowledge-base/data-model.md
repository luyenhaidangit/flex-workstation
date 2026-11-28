# Mô hình dữ liệu (Phase 1): AI Video Knowledge Base

**Database**: `videodb` (PostgreSQL) | **Migration**: `flex-database/videodb/` (Liquibase SQL-first) | **Phạm vi**: MVP (P1)

Quy ước (theo `AGENTS.md` của `flex-database`): tên bảng/cột `snake_case`; khóa chính `uuid` (sinh ở service); trạng thái là `VARCHAR` chữ thường; **không** khóa ngoại và **không** `CHECK`; chỉ hai chỉ mục duy nhất do spec yêu cầu (BR-001, BR-007). Schema `hangfire` do thư viện Hangfire tự quản lý, không nằm trong migration.

## Quan hệ logic (không có khóa ngoại ở DB)

```text
drive_connections 1 ── n video_sources 1 ── n videos 1 ── n video_processing_jobs
                                              videos 1 ── n video_analyses 1 ── n video_chapters
```

## Bảng

### `drive_connections` (FR-001, SEC-001, SEC-003)

| Cột | Kiểu | Null | Ghi chú |
| --- | --- | --- | --- |
| id | uuid | không | khóa chính |
| account_email | varchar(320) | không | chỉ để hiển thị tài khoản Drive đang kết nối |
| encrypted_refresh_token | text | không | mã hóa bằng `ChannelTokenEncryptionService`; không bao giờ trả ra API/log |
| status | varchar(20) | không | `active`, `revoked` |
| connected_by | varchar(100) | không | `sub` của quản trị viên kết nối |
| created_at / updated_at | timestamptz | không | |

### `video_sources` (FR-002)

| Cột | Kiểu | Null | Ghi chú |
| --- | --- | --- | --- |
| id | uuid | không | |
| drive_connection_id | uuid | không | tham chiếu logic |
| drive_folder_id | varchar(100) | không | |
| folder_name | varchar(500) | không | |
| status | varchar(20) | không | `active`, `removed` |
| last_synced_at | timestamptz | có | |
| created_at | timestamptz | không | |

Chỉ mục thường: `(drive_connection_id, status)`.

### `videos` (FR-003, FR-004, BR-001, BR-007)

| Cột | Kiểu | Null | Ghi chú |
| --- | --- | --- | --- |
| id | uuid | không | |
| drive_connection_id | uuid | không | |
| video_source_id | uuid | không | |
| drive_file_id | varchar(100) | không | định danh bền vững của file trên Drive |
| name | varchar(500) | không | cập nhật khi đổi tên (không mất kết quả) |
| mime_type | varchar(100) | không | |
| duration_seconds | integer | có | |
| size_bytes | bigint | có | |
| content_key | varchar(100) | không | mã băm nội dung hoặc `v<revision>` (research TQ-005) |
| status | varchar(20) | không | `pending`, `downloading`, `processing`, `summarizing`, `indexing`, `completed`, `failed`, `access_denied` |
| failure_code | varchar(50) | có | ví dụ `unsupported_language`, `file_too_large`, `download_not_allowed`, `provider_error` |
| drive_modified_at | timestamptz | có | |
| last_seen_at | timestamptz | có | lần gần nhất đồng bộ còn thấy file |
| created_at / updated_at | timestamptz | không | |

**Chỉ mục duy nhất**: `ux_videos_connection_file (drive_connection_id, drive_file_id)` — mỗi file Drive chỉ có một bản ghi video (BR-001). Chỉ mục thường: `(status)`, `(video_source_id)`.

### `video_processing_jobs` (FR-004, FR-005, FR-010)

| Cột | Kiểu | Null | Ghi chú |
| --- | --- | --- | --- |
| id | uuid | không | |
| video_id | uuid | không | |
| content_key | varchar(100) | không | khóa nội dung tại thời điểm xử lý |
| status | varchar(20) | không | cùng bộ trạng thái của `videos` |
| attempt | integer | không | số lần thử |
| failure_code | varchar(50) | có | |
| hangfire_job_id | varchar(50) | có | để truy vết, không dùng làm khóa |
| input_tokens / output_tokens | bigint | có | chỗ sẵn cho theo dõi chi phí ở P2 (FR-018) |
| started_at / finished_at | timestamptz | có | |
| created_at | timestamptz | không | |

Chỉ mục thường: `(video_id, created_at)`.

### `video_analyses` (FR-004, FR-006, FR-007, FR-008)

| Cột | Kiểu | Null | Ghi chú |
| --- | --- | --- | --- |
| id | uuid | không | |
| video_id | uuid | không | |
| content_key | varchar(100) | không | |
| summary | text | không | tóm tắt đầy đủ (tiếng Việt) |
| key_points | jsonb | không | mảng chuỗi: kiến thức chính |
| tags | jsonb | không | mảng chuỗi |
| topic_group | varchar(200) | có | nhóm chủ đề |
| difficulty | varchar(20) | có | `beginner`, `intermediate`, `advanced` |
| model_name | varchar(100) | không | model đã dùng, phục vụ truy vết |
| created_at | timestamptz | không | |

**Chỉ mục duy nhất**: `ux_video_analyses_video_content (video_id, content_key)` — một kết quả cho mỗi phiên bản nội dung; xử lý lại cùng phiên bản thì ghi đè bằng cập nhật (BR-001). Không lưu transcript đầy đủ ở MVP (giảm dữ liệu nhạy cảm; vector/RAG thuộc P3).

### `video_chapters` (FR-008, FR-009)

| Cột | Kiểu | Null | Ghi chú |
| --- | --- | --- | --- |
| id | uuid | không | |
| analysis_id | uuid | không | |
| order_no | integer | không | |
| start_seconds / end_seconds | integer | không | mốc thời gian chương (SC-003) |
| title | varchar(500) | không | |
| summary | text | không | |
| visual_notes | text | có | thông tin hình ảnh: slide, sơ đồ, code (FR-009) |

Chỉ mục thường: `(analysis_id, order_no)`.

## Chuyển trạng thái của `videos.status`

```text
pending → downloading → processing → summarizing → indexing → completed
   │            │             │            │            │
   └────────────┴─────────────┴────────────┴────────────┴──→ failed
pending/downloading → access_denied   (mất quyền hoặc Drive không cho tải)
failed/completed/access_denied → pending   (xử lý lại thủ công)
```

Ở MVP bước `indexing` chỉ ghi nhận hoàn tất lưu kết quả để tìm theo từ khóa (cột `summary`, `tags`); chỉ mục vector không thuộc MVP. Quy tắc xử lý job đồng thời: chỉ một job `downloading/processing/summarizing/indexing` cho mỗi `video_id` tại một thời điểm (kiểm tra ở handler và khóa tư vấn PostgreSQL theo `video_id`).

## Seed dữ liệu

Không có seed. Không có dữ liệu cũ cần backfill (database mới).
