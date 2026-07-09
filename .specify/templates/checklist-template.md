# Checklist [LOẠI CHECKLIST]: [TÊN TÍNH NĂNG]

## Metadata

**Mục đích**: [Mô tả ngắn gọn checklist này kiểm tra gì và hỗ trợ quyết định nào]

**Checklist ID**: [CL-YYYYMMDD-001 hoặc tên định danh]

**Ngày tạo**: [DATE]

**Người review**: [Tên người review hoặc team]

**Trạng thái review**: [Chưa bắt đầu / Đang review / Hoàn tất]

**Lần review**: [Lần 1 / Lần 2 / Final]

**Tính năng**: [Link tới spec.md hoặc tài liệu liên quan]

**Loại checklist**: [Requirement Quality / Plan Readiness / Task Quality / Release Readiness / Custom]

**Bước hiện tại**: [spec / plan / tasks / implementation / release]

**Bước tiếp theo cần quyết định**: [/speckit-plan / /speckit-tasks / implement / release]

**Artifact chính được kiểm tra**: [`spec.md` / `plan.md` / `tasks.md` / release package / artifact khác]

**Nguồn tham chiếu**: [`constitution.md`, `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `tasks.md`]

**Ghi chú**: Checklist này được sinh bởi lệnh `/speckit-checklist` dựa trên bối cảnh và yêu cầu của tính năng.

---

## Phạm vi kiểm tra

<!--
  Nêu rõ checklist này kiểm quality requirement, readiness để chuyển bước, task quality,
  hay release readiness. Không kiểm implementation nếu loại checklist là Requirement Quality.
-->

**Trong phạm vi**:
- [Artifact/khía cạnh sẽ kiểm tra]
- [Gate hoặc quyết định checklist hỗ trợ]

**Ngoài phạm vi**:
- [Nội dung không kiểm tra hoặc ghi "Không áp dụng"]
- [Implementation/runtime nếu không thuộc loại checklist này]

---

## Artifact đã kiểm tra

| Artifact | Đường dẫn/Link | Trạng thái | Ghi chú |
|----------|----------------|------------|---------|
| `spec.md` | [link/path] | Đã kiểm/Không có/Không áp dụng | [Ghi chú] |
| `plan.md` | [link/path] | Đã kiểm/Không có/Không áp dụng | [Ghi chú] |
| `tasks.md` | [link/path] | Đã kiểm/Không có/Không áp dụng | [Ghi chú] |
| `contracts/` | [link/path] | Đã kiểm/Không có/Không áp dụng | [Ghi chú] |

---

## Kết quả tổng hợp

**Trạng thái**: [Chưa review / Pass / Pass có điều kiện / Fail]

**Tổng số item**: [N]

**Pass**: [N]

**Fail**: [N]

**Không áp dụng**: [N]

**Blocker fail**: [N]

**Ghi chú chính**:
- [Vấn đề lớn nhất nếu có hoặc "Không áp dụng"]

**Quy tắc kết luận**:
- `Pass`: Không có item `[Blocker]` hoặc `[High]` fail.
- `Pass có điều kiện`: Không có `[Blocker]` fail; các `[High]`/`[Medium]` fail còn lại đã có owner, hạn xử lý, và không chặn trực tiếp bước tiếp theo.
- `Fail`: Có ít nhất một `[Blocker]` fail hoặc thiếu artifact chính để kiểm tra.

---

## Quy tắc sinh checklist

<!--
  ============================================================================
  QUY TẮC NGÔN NGỮ

  Nội dung người dùng đọc và review PHẢI dùng tiếng Việt có dấu. Giữ nguyên
  các định danh kỹ thuật như command, file path, package, API, framework,
  Markdown checkbox, mã `CHK###`, marker `[Gap]`, `[Spec §X]`, `[Ambiguity]`,
  `[Conflict]`, `[Assumption]`.

  Checklist là quality gate cho artifact được chỉ định. Mỗi item phải kiểm một
  vấn đề cụ thể và trả lời được bằng Pass/Fail/Không áp dụng.

  Quy tắc theo loại checklist:
  - Requirement Quality: kiểm `spec.md`, không kiểm implementation.
  - Plan Readiness: kiểm `plan.md` đã đủ để sinh task chưa.
  - Task Quality: kiểm `tasks.md` có rõ, trace được, đúng dependency không.
  - Release Readiness: kiểm rollout, rollback, migration, observability, smoke test.
  - Custom: ghi rõ artifact và gate được kiểm trong "Phạm vi kiểm tra".

  Các item bên dưới chỉ là VÍ DỤ MINH HỌA.

  Lệnh /speckit-checklist PHẢI thay thế chúng bằng item thực tế dựa trên:
  - Yêu cầu checklist cụ thể của người dùng
  - Artifact chính được kiểm tra
  - Nguồn tham chiếu liên quan
  - Constitution gate nếu áp dụng

  KHÔNG giữ các item ví dụ này trong checklist sinh ra.
  ============================================================================
-->

- Mỗi item chỉ kiểm một vấn đề.
- Mỗi item PHẢI trả lời được bằng Pass/Fail/Không áp dụng.
- Mỗi item sau review PHẢI có status: `Pass`, `Fail`, `Không áp dụng`, hoặc `Chưa kiểm`.
- Không dùng item mơ hồ như "requirement đã tốt chưa?".
- Không kiểm implementation nếu checklist là `Requirement Quality`.
- Item `[Blocker]` fail thì KHÔNG ĐƯỢC chuyển bước tiếp theo nếu chưa có ngoại lệ được phê duyệt.
- Mỗi item `[Blocker]` hoặc `[High]` NÊN có tham chiếu tới artifact nguồn, ví dụ `[Spec §4, US-001]`, `[Plan §8]`, `[Task T012]`.
- Mã `CHK###` PHẢI là duy nhất trong một checklist.
- Không tái sử dụng mã item đã bị xóa trong cùng lần review.
- Khi thêm item mới sau review, tiếp tục tăng số thay vì đánh số lại toàn bộ nếu checklist đã được tham chiếu.

### Gợi ý nhóm theo loại checklist

**Requirement Quality**:
- Completeness
- Clarity
- Consistency
- Measurability
- Coverage
- Assumption

**Plan Readiness**:
- Technical scope
- Traceability
- Impact analysis
- Migration/contract/permission
- Test strategy
- Rollout/observability

**Task Quality**:
- Dependency order
- Independent task
- Test task coverage
- Path/module clarity
- No vague task

**Release Readiness**:
- Rollout
- Rollback
- Migration/backfill
- Feature flag/config
- Observability
- Smoke test

**Constitution Gate**:
- Scope Gate
- Traceability Gate
- Test Gate
- Security Gate
- Compatibility Gate
- Observability Gate
- Complexity Gate
- Release Gate

---

## Quy ước tag và mức độ

### Mức độ nghiêm trọng

- `[Blocker]`: Không được đi tiếp nếu fail.
- `[High]`: Rủi ro lớn, cần xử lý trước khi implement/release.
- `[Medium]`: Nên xử lý.
- `[Low]`: Cải thiện chất lượng.

### Tag chuẩn

- `[Completeness]`: Thiếu nội dung bắt buộc.
- `[Clarity]`: Diễn đạt chưa rõ, dễ hiểu sai.
- `[Consistency]`: Mâu thuẫn giữa các requirement/artifact.
- `[Measurability]`: Chưa đo hoặc xác minh được.
- `[Coverage]`: Chưa bao phủ đủ luồng/trạng thái.
- `[Traceability]`: Chưa trace được sang artifact khác.
- `[Security]`: Rủi ro quyền hoặc dữ liệu nhạy cảm.
- `[Data]`: Rủi ro liên quan dữ liệu, entity, dữ liệu cũ, dữ liệu bẩn hoặc mất dữ liệu.
- `[Migration]`: Rủi ro liên quan schema migration, backfill, cleanup hoặc rollback dữ liệu.
- `[Compatibility]`: Rủi ro API/data backward compatibility.
- `[Observability]`: Thiếu log/trace/debug.
- `[Release]`: Thiếu readiness cho rollout/rollback/smoke test.
- `[Constitution]`: Vi phạm nguyên tắc hoặc gate trong `constitution.md`.
- `[Readiness]`: Chưa đủ điều kiện để chuyển sang bước tiếp theo.
- `[Gap]`: Có khoảng trống cần bổ sung.
- `[Ambiguity]`: Có điểm mơ hồ.
- `[Conflict]`: Có mâu thuẫn.
- `[Assumption]`: Có giả định chưa xác minh.

---

## Quy tắc đánh dấu Không áp dụng

Một item chỉ được đánh dấu `Không áp dụng` khi:

- Artifact/luồng được kiểm không có phần tương ứng.
- Không có tác động tới phạm vi item kiểm tra.
- Reviewer ghi lý do ngắn nếu item có mức `[Blocker]` hoặc `[High]`.

Ví dụ:

- API contract không thay đổi -> item contract test có thể `Không áp dụng`.
- Feature không có phân quyền riêng -> permission matrix có thể `Không áp dụng`, nhưng phải nêu lý do.

---

## [Nhóm kiểm tra theo loại checklist - VÍ DỤ, PHẢI THAY THẾ]

<!-- EXAMPLE ITEMS - MUST BE REPLACED -->

<!--
  Các item ví dụ dưới đây minh họa cho Requirement Quality.
  Khi sinh checklist loại khác, PHẢI thay bằng item phù hợp với
  Plan Readiness / Task Quality / Release Readiness / Custom.
-->

- [ ] CHK001 `[Blocker]` `[Status: Chưa kiểm]` Requirement P1 đã có acceptance criteria kiểm được chưa? [Completeness, Measurability, Spec §4, US-001]
- [ ] CHK002 `[High]` `[Status: Chưa kiểm]` Thuật ngữ dễ gây hiểu nhầm đã được định nghĩa bằng tiêu chí rõ ràng chưa? [Clarity, Ambiguity]
- [ ] CHK003 `[High]` `[Status: Chưa kiểm]` Requirement trong cùng phạm vi có nhất quán với nhau và với constitution không? [Consistency, Conflict, Constitution]

## [Nhóm kiểm tra bổ sung theo rủi ro - VÍ DỤ, PHẢI THAY THẾ]

<!-- EXAMPLE ITEMS - MUST BE REPLACED -->

- [ ] CHK004 `[Blocker]` `[Status: Chưa kiểm]` Các yêu cầu ảnh hưởng quyền, dữ liệu, contract hoặc migration đã được trace sang artifact liên quan chưa? [Traceability, Security, Data, Migration, Compatibility, Readiness]
- [ ] CHK005 `[High]` `[Status: Chưa kiểm]` Các trường hợp biên hoặc trạng thái lỗi quan trọng đã được mô tả đủ chưa? [Coverage, Gap]
- [ ] CHK006 `[Medium]` `[Status: Chưa kiểm]` Giả định hoặc phụ thuộc bên ngoài đã được ghi rõ và kiểm chứng chưa? [Assumption]

---

## Format ghi nhận khi item fail

Khi một item fail hoặc cần làm rõ, ghi nhận trực tiếp bên dưới item theo format:

```md
  - **Phát hiện**: [Mô tả vấn đề]
  - **Ảnh hưởng**: [Rủi ro nếu không xử lý]
  - **Đề xuất**: [Cách sửa spec/plan/tasks/release artifact]
  - **Tham chiếu**: [Spec §X / Plan §Y / Task ID / Contract]
  - **Owner**: [Người/team xử lý]
  - **Hạn xử lý**: [Ngày hoặc mốc trước khi chuyển bước]
```

---

## Phát hiện chính

- [CHK###] [Tóm tắt phát hiện quan trọng hoặc "Không có"]
- [CHK###] [Tóm tắt phát hiện quan trọng hoặc "Không có"]

---

## Ngoại lệ được phê duyệt

| Item | Lý do ngoại lệ | Rủi ro chấp nhận | Người phê duyệt | Hạn xem lại |
|------|----------------|------------------|------------------|-------------|
| [CHK### hoặc "Không áp dụng"] | [Lý do] | [Rủi ro] | [Tên] | [Ngày] |

---

## Kết luận và hành động tiếp theo

**Kết quả checklist**: [Pass / Pass có điều kiện / Fail]

**Có được chuyển bước tiếp theo không**: [Có/Không]

**Bước tiếp theo được đề xuất**: [/speckit-plan / /speckit-tasks / implement / release / cần cập nhật artifact]

**Điều kiện để được chuyển bước**:
- [Điều kiện 1 hoặc "Không áp dụng"]
- [Điều kiện 2 hoặc "Không áp dụng"]

**Item cần xử lý trước**:
- [CHK### hoặc "Không áp dụng"]
- [CHK### hoặc "Không áp dụng"]

---

## Ghi chú

- Đánh dấu item đã hoàn thành bằng `[x]`.
- Thêm nhận xét hoặc phát hiện trực tiếp bên dưới item liên quan.
- Liên kết tới tài liệu hoặc artifact liên quan khi cần.
- Item được đánh số tuần tự bằng mã `CHK###` duy nhất để dễ tham chiếu.
- Checklist chỉ ghi nhận phát hiện và quyết định review. Nội dung sửa chính thức PHẢI được cập nhật trong artifact gốc tương ứng.
- Checklist không thay thế việc cập nhật artifact gốc; nếu phát hiện gap, PHẢI sửa artifact tương ứng hoặc ghi ngoại lệ được phê duyệt.
