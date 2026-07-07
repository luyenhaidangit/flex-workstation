# Quy ước của [PROJECT_NAME]
<!-- Ví dụ: Quy ước Spec, Quy ước TaskFlow, v.v. -->

## Nguyên tắc cốt lõi

### [PRINCIPLE_1_NAME]
<!-- Ví dụ: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Ví dụ: Mọi tính năng bắt đầu như một thư viện độc lập; thư viện phải tự chứa, kiểm thử độc lập được, có tài liệu; mục đích rõ ràng là bắt buộc - không tạo thư viện chỉ để tổ chức code -->

### [PRINCIPLE_2_NAME]
<!-- Ví dụ: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Ví dụ: Mỗi thư viện expose chức năng qua CLI; giao thức text in/out: stdin/args -> stdout, errors -> stderr; hỗ trợ JSON và format dễ đọc cho người dùng -->

### [PRINCIPLE_3_NAME]
<!-- Ví dụ: III. Test trước (không thương lượng) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Ví dụ: TDD là bắt buộc: viết test -> user duyệt -> test fail -> sau đó implement; tuân thủ nghiêm Red-Green-Refactor cycle -->

### [PRINCIPLE_4_NAME]
<!-- Ví dụ: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Ví dụ: Các phạm vi cần integration test: contract test cho thư viện mới, contract thay đổi, giao tiếp giữa service, shared schemas -->

### [PRINCIPLE_5_NAME]
<!-- Ví dụ: V. Observability, VI. Quản lý phiên bản và thay đổi phá vỡ tương thích, VII. Đơn giản hóa -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Ví dụ: Text I/O giúp dễ debug; structured logging là bắt buộc; hoặc: dùng format MAJOR.MINOR.BUILD; hoặc: bắt đầu đơn giản, tuân thủ YAGNI -->

## [SECTION_2_NAME]
<!-- Ví dụ: Ràng buộc bổ sung, yêu cầu bảo mật, tiêu chuẩn hiệu năng, v.v. -->

[SECTION_2_CONTENT]
<!-- Ví dụ: yêu cầu về tech stack, tiêu chuẩn tuân thủ, chính sách triển khai, v.v. -->

## [SECTION_3_NAME]
<!-- Ví dụ: Quy trình phát triển, Quy trình review, Cổng chất lượng, v.v. -->

[SECTION_3_CONTENT]
<!-- Ví dụ: yêu cầu review code, cổng kiểm thử, quy trình phê duyệt triển khai, v.v. -->

## Quản trị
<!-- Ví dụ: Quy ước có hiệu lực cao hơn các practice khác; sửa đổi cần tài liệu, phê duyệt và kế hoạch chuyển đổi -->

[GOVERNANCE_RULES]
<!-- Ví dụ: Mọi PR/review phải xác minh tuân thủ; độ phức tạp phải được biện minh; dùng [GUIDANCE_FILE] làm hướng dẫn phát triển runtime -->

**Phiên bản**: [CONSTITUTION_VERSION] | **Phê chuẩn**: [RATIFICATION_DATE] | **Sửa đổi gần nhất**: [LAST_AMENDED_DATE]
<!-- Ví dụ: Phiên bản: 2.1.1 | Phê chuẩn: 2025-06-13 | Sửa đổi gần nhất: 2025-07-16 -->
