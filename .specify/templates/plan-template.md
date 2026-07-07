# Kế hoạch triển khai: [TÍNH NĂNG]

**Branch**: `[NNNNNN-ten-tinh-nang]` | **Ngày**: [NGÀY] | **Đặc tả**: [link]

**Đầu vào**: Đặc tả tính năng từ `/specs/[NNNNNN-ten-tinh-nang]/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

[Trích từ spec: yêu cầu chính + hướng tiếp cận kỹ thuật từ research]

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

## Theo dõi độ phức tạp

> **Chỉ điền nếu kiểm tra constitution có vi phạm cần biện minh**

| Vi phạm | Vì sao cần | Phương án đơn giản hơn bị loại vì |
|---------|------------|-----------------------------------|
| [ví dụ: project thứ 4] | [nhu cầu hiện tại] | [vì sao 3 project không đủ] |
| [ví dụ: Repository pattern] | [vấn đề cụ thể] | [vì sao truy cập DB trực tiếp không đủ] |
