# Constitution của [PROJECT_NAME]
<!-- Ví dụ: Spec Constitution, TaskFlow Constitution, v.v. -->

## Nguyên tắc cốt lõi

### [PRINCIPLE_1_NAME]
<!-- Ví dụ: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Ví dụ: Mọi feature bắt đầu như một thư viện độc lập; thư viện phải tự chứa, test độc lập được, có tài liệu; mục đích rõ ràng là bắt buộc - không tạo thư viện chỉ để tổ chức code -->

### [PRINCIPLE_2_NAME]
<!-- Ví dụ: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Ví dụ: Mỗi thư viện expose chức năng qua CLI; giao thức text in/out: stdin/args -> stdout, errors -> stderr; hỗ trợ JSON và format dễ đọc cho người dùng -->

### [PRINCIPLE_3_NAME]
<!-- Ví dụ: III. Test-First (NON-NEGOTIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Ví dụ: TDD là bắt buộc: viết test -> user duyệt -> test fail -> sau đó implement; tuân thủ nghiêm Red-Green-Refactor cycle -->

### [PRINCIPLE_4_NAME]
<!-- Ví dụ: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Ví dụ: Các phạm vi cần integration test: contract test cho thư viện mới, contract thay đổi, giao tiếp giữa service, shared schemas -->

### [PRINCIPLE_5_NAME]
<!-- Ví dụ: V. Observability, VI. Versioning & Breaking Changes, VII. Simplicity -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Ví dụ: Text I/O giúp dễ debug; structured logging là bắt buộc; hoặc: dùng format MAJOR.MINOR.BUILD; hoặc: bắt đầu đơn giản, tuân thủ YAGNI -->

## [SECTION_2_NAME]
<!-- Ví dụ: Ràng buộc bổ sung, yêu cầu bảo mật, tiêu chuẩn hiệu năng, v.v. -->

[SECTION_2_CONTENT]
<!-- Ví dụ: yêu cầu về technology stack, compliance standards, deployment policies, v.v. -->

## [SECTION_3_NAME]
<!-- Ví dụ: Development Workflow, Review Process, Quality Gates, v.v. -->

[SECTION_3_CONTENT]
<!-- Ví dụ: yêu cầu code review, testing gates, deployment approval process, v.v. -->

## Governance
<!-- Ví dụ: Constitution có hiệu lực cao hơn các practice khác; amendment cần tài liệu, phê duyệt và migration plan -->

[GOVERNANCE_RULES]
<!-- Ví dụ: Mọi PR/review phải xác minh compliance; complexity phải được biện minh; dùng [GUIDANCE_FILE] làm hướng dẫn runtime development -->

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
<!-- Ví dụ: Version: 2.1.1 | Ratified: 2025-06-13 | Last Amended: 2025-07-16 -->
