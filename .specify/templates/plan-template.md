# Kế hoạch triển khai: [TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]` | **Ngày**: [NGÀY] | **Chế độ Spec**: [Full / Compact] | **Đặc tả**: [spec.md](./spec.md)  
**Đầu vào**: `/specs/[NNNNNN-ten-tinh-nang]/spec.md` và phạm vi repo tại `repos.md` (nếu chạm repo con)

<!-- Chế độ Compact (1 repo, không đổi DB dùng chung, không breaking public contract): nhúng thẳng research, entity/data và quickstart gọn ngay trong file plan.md này, không cần sinh file rời research.md / data-model.md / quickstart.md trừ khi thực sự phức tạp. Chế độ Full: sinh đầy đủ các file Phase 0/1. Giữ nguyên các heading; phần không liên quan ghi "Không áp dụng — <lý do 1 dòng>". -->

## Tóm tắt

- **Yêu cầu chính từ spec**: [Tóm tắt US/FR/MVP trọng tâm]
- **Hướng tiếp cận kỹ thuật**: [Giải pháp kiến trúc được chọn]
- **Kết quả research**: [Tóm tắt từ `research.md` hoặc ghi trực tiếp nếu ở chế độ `Compact`]

## Phạm vi kỹ thuật

- **Trong phạm vi**: [Repo/service/module/API/config sẽ thay đổi — phải khớp `repos.md` và MVP trong `spec.md`]
- **Ngoài phạm vi kỹ thuật**: [Phần chủ đích không làm ở phase này hoặc "Không áp dụng"]

## Bối cảnh kỹ thuật

- **Ngôn ngữ / Framework**: [Ví dụ: .NET 8 / ASP.NET Core, Angular 17... hoặc `CẦN LÀM RÕ`]
- **Service / Repo liên quan**: [Đối chiếu `repos.md` (`Edit` / `Read`)]
- **Convention skill áp dụng**: [Map theo từng repo — vd: `flex-agent-service` → `flex-dotnet-engineering`, `flex-codebase-architect`; `flex-microfrontend` → `flex-frontend-engineering`]
- **Lưu trữ & Phụ thuộc chính**: [PostgreSQL / Redis / SDK nội bộ... hoặc `Không áp dụng`]
- **Kiểm thử & Đơn vị deploy**: [xUnit / Karma / container / job...]
- **Mục tiêu hiệu năng & Ràng buộc**: [Theo NFR/SC hoặc chuẩn hiện hữu]

## Kiểm tra constitution

*GATE: Đánh giá trước Phase 0 và xác nhận lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú / Dẫn chứng |
|------|--------------------|-----------------------|---------------------|
| Scope & Traceability Gate | Pass/Fail | Pass/Fail | [Khớp MVP, US/FR/BR/SEC/NFR có mapping] |
| Test & Security Gate | Pass/Fail/Không áp dụng | Pass/Fail/Không áp dụng | [Chiến lược test theo rủi ro & phân quyền] |
| Compatibility & DB Placement (VI) | Pass/Fail/Không áp dụng | Pass/Fail/Không áp dụng | [DB đích, repo migration, backward compatibility] |
| Observability & Complexity Gate | Pass/Fail/Không áp dụng | Pass/Fail/Không áp dụng | [Log/metric không lộ secret, thiết kế tối giản] |
| Specialist Skill Gate | Pass/Fail | Pass/Fail | [Đã route và áp dụng skill chuyên môn phù hợp] |

## Câu hỏi kỹ thuật & Quyết định thiết kế

<!-- Mọi TQ chặn thiết kế/task phải được giải quyết trước /speckit-tasks (tại đây với Compact, hoặc chi tiết trong research.md với Full). -->

| Mã | Vấn đề / Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại |
|----|---------------------|----------|------------|-------------------|
| DEC-001 | [Vấn đề kỹ thuật 1] | [Giải pháp chọn] | [Vì sao phù hợp codebase] | [Phương án khác & lý do loại] |

## Thiết kế tổng quan

- **Luồng xử lý chính**: [Các bước kỹ thuật ngắn gọn 1 → 2 → 3]
- **Component / Module tham gia & Boundary**: [Module nào giữ trách nhiệm gì; thay đổi ranh giới nếu có]
- **Luồng lỗi & Idempotency / Concurrency**: [Xử lý retry, thao tác lặp, cập nhật đồng thời hoặc "Không áp dụng"]

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID (`MVP`/`US`/`FR`/`BR`/`SEC`/`NFR`) | Ưu tiên | Hướng xử lý kỹ thuật | Module / Path dự kiến | API / Contract | Data / Entity | Kiểm thử |
|---|---|---|---|---|---|---|
| US-001 / FR-001 | P1 | [Thiết kế] | [path thật] | [endpoint/event hoặc Không áp dụng] | [entity/table hoặc Không áp dụng] | [unit/integration/e2e] |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược / Rủi ro | Cách kiểm tra |
|---------|------------------|----------------------------|---------------|
| Database / Migration | [Mô tả hoặc Không áp dụng] | [Rủi ro dữ liệu] | [Cách verify] |
| API / Contract | [Mô tả hoặc Không áp dụng] | [Backward compatibility] | [Contract/consumer check] |
| Permission / Security | [Mô tả hoặc Không áp dụng] | [Rủi ro lộ/sai phạm vi] | [Permission test] |
| Logging / Audit | [Mô tả hoặc Không áp dụng] | [Thiếu truy vết / lộ secret] | [Log/audit check] |
| UI / UX | [Mô tả hoặc Không áp dụng] | [Gián đoạn luồng cũ] | [UI/manual/e2e check] |
| Job / Worker / Integration | [Mô tả hoặc Không áp dụng] | [Timeout/retry/idempotency] | [Integration check] |

## API/Contract Detail

<!-- Nếu không đổi API/event/webhook/public contract, ghi 1 dòng: "Không áp dụng — không thay đổi contract." và bỏ bảng. -->

**Có thay đổi contract không**: [Có / Không áp dụng — lý do ngắn]

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|-----------------------|
| [Endpoint/Event hoặc Không áp dụng] | API/Event | [Mô tả] | Có/Không | [Consumer] |

## Permission Matrix

<!-- Nếu không có phân quyền theo role/tenant/scope riêng, ghi 1 dòng: "Không áp dụng — lý do ngắn." -->

| Vai trò / Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Điều kiện / Ghi chú |
|-----------------|-----|-----|-----|-----|-------------|---------------------|
| [Role hoặc Không áp dụng] | Có/Không | Có/Không | Có/Không | Có/Không | Có/Không | [Điều kiện] |

## Dữ liệu & Migration

<!-- Bắt buộc đối chiếu docs/architecture/system-map.md và tiền lệ spec khi có DB/schema (Constitution VI). Ghi 1 dòng "Không áp dụng — không chạm DB/schema" nếu không liên quan. -->

- **Có thay đổi dữ liệu/schema không**: [Có / Không áp dụng]
- **Database đích & Repo chứa migration**: [Tên DB + tên repo kèm dẫn chứng `system-map.md`/spec tiền lệ, hoặc "Không áp dụng"]
- **Chi tiết Migration / Backfill / Tương thích dữ liệu cũ**: [Mô tả ngắn hoặc tham chiếu `data-model.md`]
- **Rủi ro & Cách xác minh dữ liệu**: [Query/smoke check hoặc "Không áp dụng"]

## Chiến lược kiểm thử

- **Unit test**: [Module/rule cần test hoặc "Không áp dụng — lý do"]
- **Integration / Contract test**: [Luồng DB/API/service cần test hoặc "Không áp dụng — lý do"]
- **Permission / Security test**: [Case hợp lệ & bị từ chối hoặc "Không áp dụng"]
- **E2E / Manual / Quickstart validation**: [Kịch bản chạy kiểm chứng đầu-cuối — nhúng thẳng lệnh kiểm tra tại đây nếu dùng chế độ `Compact`, hoặc tham chiếu `quickstart.md`]
- **Regression test**: [Luồng hiện hữu cần giữ xanh]

## Tác động tài liệu nghiệp vụ

- **Kết quả Documentation Impact Gate (`spec.md` §20)**: [CÓ CẬP NHẬT / KHÔNG CẦN CẬP NHẬT]
- **Tài liệu hiện hữu đã cập nhật**: [Path + section, hoặc "Không áp dụng"]
- **Cập nhật còn lại sau implementation**: [Path + section cụ thể nếu cần sinh task, hoặc "Không áp dụng"]

## Cấu trúc project

### Artifacts của feature
`specs/[NNNNNN-ten-tinh-nang]/`: `spec.md`, `plan.md`, `repos.md` *(nếu chạm repo con)*, `tasks.md` *(sinh bởi `/speckit-tasks`)*, và ở chế độ `Full`: `research.md`, `data-model.md`, `contracts/`, `quickstart.md`.

### Source code (thay bằng path thật của repo trong phạm vi)

```text
# [XÓA NẾU KHÔNG DÙNG] Thay thế hoàn toàn khối mẫu này bằng cây thư mục/file thật sẽ tạo hoặc sửa:
<repo-name>/
├── src/...
└── tests/...
```

**Quyết định cấu trúc**: [Giải thích ngắn vị trí đặt file mới/sửa khớp kiến trúc hiện có của repo]

## Rollout & Rollback

- **Kế hoạch rollout & Feature flag/config**: [Thứ tự deploy/migration/flag hoặc "Không áp dụng — deploy tiêu chuẩn"]
- **Rollback code/config**: [Cách revert nhanh]
- **Rollback dữ liệu/migration & Điều kiện kích hoạt**: [Rollback script hoặc phương án forward-fix; ngưỡng lỗi kích hoạt]

## Observability & Debug

- **Log / Metric / Trace cần có**: [Event, correlation field (`traceId`, `tenantId`, `userId`...) hoặc "Không áp dụng"]
- **Dữ liệu KHÔNG ĐƯỢC log**: [Token, secret, API key, credential, PII]
- **Cách kiểm tra sau release**: [Health check / smoke command / log query]

## Theo dõi độ phức tạp

> Chỉ điền khi có ngoại lệ vi phạm Constitution cần biện minh; mặc định ghi `Không có vi phạm.`

| ID / Nguyên tắc | Vì sao cần | Phương án đơn giản hơn bị loại vì | Người phê duyệt & Hạn xử lý |
|-----------------|------------|-----------------------------------|-----------------------------|
| Không áp dụng | — | — | — |

## Checklist sẵn sàng cho `/speckit-tasks`

- [ ] Phạm vi kỹ thuật và `repos.md` (nếu chạm repo con) đã rõ, khớp MVP của `spec.md`.
- [ ] Mọi câu hỏi kỹ thuật chặn thiết kế/task đã được chốt (trong `research.md` hoặc bảng quyết định ở trên).
- [ ] Mỗi `US`/`FR`/`BR`/`SEC`/`NFR` quan trọng đã map sang module/path, contract, data và kiểm thử.
- [ ] Database đích và repo chứa migration đã đối chiếu `docs/architecture/system-map.md` (hoặc ghi `Không áp dụng`).
- [ ] Chiến lược kiểm thử, rollout/rollback và observability (kèm danh mục cấm log secret) đã rõ.
- [ ] Khối cấu trúc source code đã thay hoàn toàn bằng path thật (không còn `# [XÓA NẾU KHÔNG DÙNG]`).
- [ ] Bảng Kiểm tra constitution không còn blocker chưa được phê duyệt.
