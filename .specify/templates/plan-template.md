# Kế hoạch triển khai: [TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]` | **Ngày**: [NGÀY] | **Đặc tả**: [link]

**Đầu vào**: Đặc tả tính năng từ `/specs/[NNNNNN-ten-tinh-nang]/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

**Yêu cầu chính từ spec**: [Tóm tắt US/FR/MVP quan trọng]

**Hướng tiếp cận kỹ thuật dự kiến**: [Cách tiếp cận ban đầu, sẽ được xác nhận sau Phase 0 research]

**Kết quả sau research**: [Cập nhật sau khi hoàn thành research.md hoặc ghi "Chưa thực hiện"]

## Phạm vi kỹ thuật

<!--
  Xác định rõ phần code/config/data nào sẽ thay đổi trong phase này.
  Phần ngoài phạm vi kỹ thuật phải khớp với MVP và "Ngoài phạm vi" trong spec.
  Không dùng section này để mở rộng scope nghiệp vụ.
-->

**Trong phạm vi**:
- [Module/service/app/API/job/config sẽ được thay đổi]
- [Luồng kỹ thuật cần bổ sung để đáp ứng MVP]

**Ngoài phạm vi kỹ thuật**:
- [Phần không làm trong phase này hoặc ghi "Không áp dụng"]
- [Tích hợp/migration/automation chưa thực hiện ở phase này nếu có]

## Bối cảnh kỹ thuật

<!--
  CẦN THỰC HIỆN: Thay nội dung section này bằng chi tiết kỹ thuật thật của project.
  Cấu trúc dưới đây là gợi ý để hỗ trợ quá trình lặp và review.
-->

**Ngôn ngữ/Phiên bản**: [ví dụ: .NET/C# version, Node.js version hoặc CẦN LÀM RÕ]

**Service/App liên quan**: [Tên service/app/module bị ảnh hưởng hoặc CẦN LÀM RÕ]

**Phụ thuộc chính**: [Framework/package/internal SDK/service hiện có hoặc CẦN LÀM RÕ]

**Lưu trữ**: [SQL Server/PostgreSQL/MySQL/Redis/ElasticSearch/file hoặc Không áp dụng]

**Kiểm thử**: [xUnit/NUnit/Jest/integration test/manual test hoặc CẦN LÀM RÕ]

**Nền tảng chạy**: [Linux container, Windows service, Kubernetes, IIS, worker, browser hoặc CẦN LÀM RÕ]

**Đơn vị deploy**: [Service/app/job/package cần deploy hoặc CẦN LÀM RÕ]

**Loại project**: [ví dụ: web-service/admin-web/worker/library/cli hoặc CẦN LÀM RÕ]

**Mục tiêu hiệu năng**: [theo domain, ví dụ: phản hồi thao tác chính trong 3 giây hoặc CẦN LÀM RÕ]

**Ràng buộc**: [theo domain, ví dụ: <200ms p95, <100MB memory, offline-capable hoặc CẦN LÀM RÕ]

**Quy mô/Phạm vi**: [theo domain, ví dụ: 10k users, 1M LOC, 50 screens hoặc CẦN LÀM RÕ]

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| [Tên gate từ constitution] | Pass/Fail/Không áp dụng | Pass/Fail/Không áp dụng | [Lý do hoặc việc cần xử lý] |

## Câu hỏi kỹ thuật cần research

<!--
  Những điểm kỹ thuật chưa chắc chắn cần xử lý trong Phase 0.
  Không để câu hỏi mở nếu nó chặn thiết kế hoặc task generation.
-->

- **TQ-001**: [CẦN LÀM RÕ: Có cần migration/backfill không?]
- **TQ-002**: [CẦN LÀM RÕ: Dùng flow/module hiện có hay tạo extension point mới?]
- **TQ-003**: [CẦN LÀM RÕ: Contract hiện tại có cần giữ backward compatibility không?]

## Thiết kế tổng quan

<!--
  Mô tả luồng kỹ thuật ở mức high-level để reviewer hiểu feature gắn vào hệ thống như thế nào.
  Không liệt kê task chi tiết ở đây.
-->

**Luồng chính**:
1. [Bước kỹ thuật chính 1]
2. [Bước kỹ thuật chính 2]
3. [Bước kỹ thuật chính 3]

**Component/module tham gia**:
- [Module/service/app 1]: [Vai trò trong luồng]
- [Module/service/app 2]: [Vai trò trong luồng]

**Điểm mở rộng/thay đổi chính**:
- [Điểm thay đổi 1]
- [Điểm thay đổi 2]

**Luồng thay thế/lỗi chính**:
- [Luồng lỗi/quyền/timeout/retry nếu có hoặc "Không áp dụng"]

**Thay đổi boundary giữa service/module**:
- [Boundary thay đổi hoặc "Không áp dụng"]

**Idempotency/Concurrency**:
- [Cách xử lý thao tác lặp, retry, concurrent update hoặc "Không áp dụng"]

## Traceability từ spec sang thiết kế kỹ thuật

<!--
  Mỗi US/FR quan trọng trong spec phải có hướng xử lý kỹ thuật và cách kiểm thử tương ứng.
  Bắt buộc mapping cho P1/P2 hoặc FR ảnh hưởng code/data/API/permission.
  FR không tác động kỹ thuật ghi "Không áp dụng".
-->

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ / Cần làm rõ | [Cách đáp ứng yêu cầu ở mức thiết kế] | [path/module] | [endpoint/event/contract hoặc Không áp dụng] | [entity/table/file hoặc Không áp dụng] | [unit/integration/contract/e2e] |
| US-001 / FR-002 | P1 | Đủ rõ / Cần làm rõ | [Cách đáp ứng yêu cầu ở mức thiết kế] | [path/module] | [endpoint/event/contract hoặc Không áp dụng] | [entity/table/file hoặc Không áp dụng] | [unit/integration/contract/e2e] |

## Phân tích tác động

<!--
  Ghi rõ ảnh hưởng tới các phần hiện có để reviewer đánh giá rủi ro trước khi sinh task.
  Ghi "Không áp dụng" cho dòng không liên quan; không xóa dòng có thể xảy ra.
-->

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | [Có thay schema/data/migration không] | [Rủi ro dữ liệu hoặc Không áp dụng] | [Cách verify migration/data] |
| API/Contract | [Endpoint/event/payload thay đổi hoặc Không áp dụng] | [Backward compatibility] | [Contract test/consumer check] |
| Permission/Security | [Quyền, tenant, department, member scope] | [Rủi ro truy cập sai dữ liệu] | [Permission test] |
| Logging/Audit | [Log/audit thay đổi hoặc Không áp dụng] | [Thiếu truy vết khi lỗi] | [Kiểm tra log/audit record] |
| UI/UX | [Màn hình/flow thay đổi hoặc Không áp dụng] | [Rủi ro gián đoạn flow hiện có] | [Manual/e2e test] |
| Job/Worker/Integration | [Tác động async/integration hoặc Không áp dụng] | [Retry/idempotency/timeout] | [Integration test] |

## API/Contract Detail

<!--
  Dùng khi feature có thay đổi API, event, webhook, payload, OpenAPI, hoặc public contract.
  Nếu không có thay đổi contract, ghi "Không áp dụng".
-->

**Có thay đổi contract không**: [Có/Không áp dụng]

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| [Endpoint/Event/Webhook hoặc "Không áp dụng"] | API/Event/Webhook | [Mô tả thay đổi] | Có/Không/Không áp dụng | [Client/service/job hoặc Không áp dụng] |

## Permission Matrix

<!--
  Dùng khi feature có phân quyền theo role, tenant, department, member, scope, hoặc trạng thái.
  Nếu không liên quan, ghi "Không áp dụng".
-->

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| [Role/scope hoặc "Không áp dụng"] | Có/Không | Có/Không | Có/Không | Có/Không | Có/Không | [Điều kiện] |

## Dữ liệu & Migration

<!--
  Bắt buộc điền rõ khi tính năng có thay đổi dữ liệu/schema hoặc cần xử lý dữ liệu hiện có.
  Nếu không liên quan, ghi "Không áp dụng" và nêu lý do ngắn.
-->

**Có thay đổi dữ liệu/schema không**: [Có/Không áp dụng]

**Migration**:
- [Mô tả migration hoặc "Không áp dụng"]

**Backfill/Cleanup**:
- [Phạm vi dữ liệu cần xử lý hoặc "Không áp dụng"]

**Tương thích dữ liệu cũ**:
- [Cách hệ thống xử lý dữ liệu đã tồn tại hoặc "Không áp dụng"]

**Rủi ro dữ liệu**:
- [Mất dữ liệu, sai quyền, duplicate, dirty data hoặc "Không áp dụng"]

**Cách xác minh**:
- [Query/checklist/smoke test xác minh dữ liệu hoặc "Không áp dụng"]

## Quyết định kỹ thuật

<!--
  Tóm tắt quyết định cuối cùng từ research.md để plan.md tự đủ ngữ cảnh review.
  Không cần lặp toàn bộ phân tích; chỉ ghi quyết định, lý do và phương án đã loại.
-->

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| [DEC-001] | [Cách tiếp cận được chọn] | [Vì sao phù hợp với spec/codebase] | [Cách khác hoặc Không áp dụng] | [Vì sao không chọn] |
| [DEC-002] | [Cách tiếp cận được chọn] | [Vì sao phù hợp với spec/codebase] | [Cách khác hoặc Không áp dụng] | [Vì sao không chọn] |

## Chiến lược kiểm thử

<!--
  Xác định các lớp test cần có. Không viết test case chi tiết ở đây.
  Ghi "Không áp dụng" cho lớp test không liên quan.
-->

**Unit test**:
- [Logic/module cần unit test hoặc "Không áp dụng"]

**Integration test**:
- [Luồng cần test qua DB/service/integration hoặc "Không áp dụng"]

**Contract test**:
- [API/event/payload cần kiểm tra compatibility hoặc "Không áp dụng"]

**Permission/security test**:
- [Case quyền hợp lệ/không hợp lệ hoặc "Không áp dụng"]

**E2E/manual test**:
- [Luồng người dùng chính cần xác nhận hoặc "Không áp dụng"]

**Regression test**:
- [Luồng hiện có có nguy cơ bị ảnh hưởng hoặc "Không áp dụng"]

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/[NNNNNN-ten-tinh-nang]/
├── plan.md              # File này (output của lệnh /speckit-plan)
├── research.md          # Output Phase 0 (lệnh /speckit-plan)
├── data-model.md        # Output Phase 1 (lệnh /speckit-plan)
├── quickstart.md        # Output Phase 1 (lệnh /speckit-plan)
├── contracts/           # Output Phase 1 (lệnh /speckit-plan)
└── tasks.md             # Output Phase 2 (lệnh /speckit-tasks - KHÔNG tạo bởi /speckit-plan)
```

### Source code (repository root)

<!--
  CẦN THỰC HIỆN: Thay cây placeholder bên dưới bằng layout thật cho feature.
  Chọn cấu trúc gần nhất với repo hiện tại, xóa phần không dùng, và thay bằng path thật.
  Plan cuối cùng không được giữ nhãn Option hoặc cây thư mục mẫu/generic.
-->

```text
# [XÓA NẾU KHÔNG DÙNG] Option 1: .NET/backend service
src/
├── [ServiceName]/
│   ├── Controllers/
│   ├── Services/
│   ├── Repositories/
│   ├── Models/
│   └── ...

tests/
├── [ServiceName].UnitTests/
├── [ServiceName].IntegrationTests/
└── [ServiceName].ContractTests/

# [XÓA NẾU KHÔNG DÙNG] Option 2: Monorepo app/service/worker
apps/
├── admin-web/
├── gov-api/
└── worker/

packages/
└── shared/

tests/
├── unit/
├── integration/
└── contract/
```

**Quyết định cấu trúc**: [Ghi lại cấu trúc đã chọn và tham chiếu các thư mục thật ở trên]

## Rollout & Rollback

<!--
  Bắt buộc điền khi có migration, thay API contract, thay permission, thay job runtime,
  hoặc thay đổi có thể ảnh hưởng dữ liệu/người dùng hiện có.
  Nếu không cần rollout đặc biệt, ghi "Không áp dụng" và nêu lý do.
-->

**Kế hoạch rollout**: [Các bước deploy/bật feature/migration/backfill hoặc "Không áp dụng"]

**Tương thích ngược**: [Cách giữ tương thích với client/job/data cũ hoặc "Không áp dụng"]

**Feature flag/config**: [Flag/config dùng để bật tắt hoặc "Không áp dụng"]

**Thực thi migration/backfill khi rollout**:
- [Chạy trước deploy / sau deploy / qua job riêng / Không áp dụng]

**Rollback code/config**:
- [Cách quay lại version/flag/config cũ hoặc "Không áp dụng"]

**Rollback dữ liệu/migration**:
- [Có thể rollback không? Nếu không, dùng forward-fix thế nào?]

**Điều kiện kích hoạt rollback**:
- [Error rate, lỗi dữ liệu, lỗi quyền, lỗi contract hoặc "Không áp dụng"]

## Observability & Debug

<!--
  Xác định cách biết tính năng hoạt động đúng sau release và cách debug khi lỗi.
  Tập trung vào log field, trace/correlation, metric, alert, và quick check vận hành.
-->

**Log cần có**:
- [Tên event/log + field chính, ví dụ: traceId, tenantId, userId, entityId, action, result]

**Dữ liệu không được log**:
- [Token, secret, API key, dữ liệu nhạy cảm, nội dung người dùng hoặc "Không áp dụng"]

**Metric cần theo dõi**:
- [Latency/error rate/count/business metric hoặc "Không áp dụng"]

**Trace/Correlation**:
- [traceId/correlationId/requestId/jobId cần truyền qua các bước hoặc "Không áp dụng"]

**Cách kiểm tra sau release**:
- [Query log, dashboard, health check, smoke test hoặc "Không áp dụng"]

**Tình huống debug chính**:
- [Lỗi quyền, timeout, dữ liệu lệch, migration lỗi, integration lỗi hoặc "Không áp dụng"]

## Theo dõi độ phức tạp

> **Chỉ điền nếu kiểm tra constitution có vi phạm cần biện minh**

| Vi phạm | Vì sao cần | Phương án đơn giản hơn bị loại vì |
|---------|------------|-----------------------------------|
| [ví dụ: project thứ 4] | [nhu cầu hiện tại] | [vì sao 3 project không đủ] |
| [ví dụ: Repository pattern] | [vấn đề cụ thể] | [vì sao truy cập DB trực tiếp không đủ] |

## Checklist sẵn sàng cho `/speckit-tasks`

<!--
  Chỉ chuyển sang sinh tasks khi plan đã đủ chi tiết để tạo task độc lập, kiểm thử được.
  Nếu một điểm chưa rõ nhưng vẫn đi tiếp, ghi rủi ro hoặc câu hỏi mở tương ứng.
-->

- [ ] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [ ] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [ ] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [ ] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [ ] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [ ] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [ ] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [ ] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [ ] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [ ] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [ ] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [ ] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [ ] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [ ] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
