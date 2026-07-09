# Kế hoạch triển khai: [TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]` | **Ngày**: [NGÀY] | **Đặc tả**: [link]

**Đầu vào**: Đặc tả tính năng từ `/specs/[NNNNNN-ten-tinh-nang]/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

[Trích từ spec: yêu cầu chính + hướng tiếp cận kỹ thuật từ research]

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

## Traceability từ spec sang thiết kế kỹ thuật

<!--
  Mỗi US/FR quan trọng trong spec phải có hướng xử lý kỹ thuật và cách kiểm thử tương ứng.
  Nếu một yêu cầu không đụng API/data/module, ghi "Không áp dụng" thay vì để trống.
-->

| Spec ID | Ưu tiên | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | [Cách đáp ứng yêu cầu ở mức thiết kế] | [path/module] | [endpoint/event/contract hoặc Không áp dụng] | [entity/table/file hoặc Không áp dụng] | [unit/integration/contract/e2e] |
| US-001 / FR-002 | P1 | [Cách đáp ứng yêu cầu ở mức thiết kế] | [path/module] | [endpoint/event/contract hoặc Không áp dụng] | [entity/table/file hoặc Không áp dụng] | [unit/integration/contract/e2e] |

## Bối cảnh kỹ thuật

<!--
  CẦN THỰC HIỆN: Thay nội dung section này bằng chi tiết kỹ thuật thật của project.
  Cấu trúc dưới đây là gợi ý để hỗ trợ quá trình lặp và review.
-->

**Ngôn ngữ/Phiên bản**: [ví dụ: Python 3.11, Swift 5.9, Rust 1.75 hoặc CẦN LÀM RÕ]

**Phụ thuộc chính**: [ví dụ: FastAPI, UIKit, LLVM hoặc CẦN LÀM RÕ]

**Lưu trữ**: [nếu áp dụng, ví dụ: PostgreSQL, CoreData, file hoặc N/A]

**Kiểm thử**: [ví dụ: pytest, XCTest, cargo test hoặc CẦN LÀM RÕ]

**Nền tảng mục tiêu**: [ví dụ: Linux server, iOS 15+, WASM hoặc CẦN LÀM RÕ]

**Loại project**: [ví dụ: library/cli/web-service/mobile-app/compiler/desktop-app hoặc CẦN LÀM RÕ]

**Mục tiêu hiệu năng**: [theo domain, ví dụ: 1000 req/s, 10k lines/sec, 60 fps hoặc CẦN LÀM RÕ]

**Ràng buộc**: [theo domain, ví dụ: <200ms p95, <100MB memory, offline-capable hoặc CẦN LÀM RÕ]

**Quy mô/Phạm vi**: [theo domain, ví dụ: 10k users, 1M LOC, 50 screens hoặc CẦN LÀM RÕ]

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

## Quyết định kỹ thuật

<!--
  Tóm tắt quyết định cuối cùng từ research.md để plan.md tự đủ ngữ cảnh review.
  Không cần lặp toàn bộ phân tích; chỉ ghi quyết định, lý do và phương án đã loại.
-->

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| [DEC-001] | [Cách tiếp cận được chọn] | [Vì sao phù hợp với spec/codebase] | [Cách khác hoặc Không áp dụng] | [Vì sao không chọn] |
| [DEC-002] | [Cách tiếp cận được chọn] | [Vì sao phù hợp với spec/codebase] | [Cách khác hoặc Không áp dụng] | [Vì sao không chọn] |

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

[Các gate được xác định dựa trên constitution file]

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
  Xóa option không dùng và mở rộng cấu trúc đã chọn bằng path thật
  (ví dụ: apps/admin, packages/something). Plan cuối cùng không được giữ nhãn Option.
-->

```text
# [XÓA NẾU KHÔNG DÙNG] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [XÓA NẾU KHÔNG DÙNG] Option 2: Web application (khi phát hiện "frontend" + "backend")
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [XÓA NẾU KHÔNG DÙNG] Option 3: Mobile + API (khi phát hiện "iOS/Android")
api/
└── [giống backend ở trên]

ios/ hoặc android/
└── [cấu trúc theo nền tảng: feature modules, UI flows, platform tests]
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

**Kế hoạch rollback**: [Cách quay lại khi lỗi, bao gồm data/API/migration nếu có]

**Dữ liệu cần backfill/cleanup**: [Có/Không áp dụng. Nếu có, mô tả phạm vi và cách kiểm tra]

## Observability & Debug

<!--
  Xác định cách biết tính năng hoạt động đúng sau release và cách debug khi lỗi.
  Tập trung vào log field, trace/correlation, metric, alert, và quick check vận hành.
-->

**Log cần có**:
- [Tên event/log + field chính, ví dụ: traceId, tenantId, userId, entityId, action, result]

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
- [ ] Mỗi `US`/`FR` P1 có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [ ] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [ ] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [ ] Rollout, rollback, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [ ] Observability/debug plan có log field, metric/trace và cách kiểm tra sau release.
- [ ] Cấu trúc source code đã thay bằng path thật, không còn option placeholder không dùng.
- [ ] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
