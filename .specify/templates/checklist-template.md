# Checklist [LOẠI CHECKLIST]: [TÊN TÍNH NĂNG]

## Metadata

**Mục đích**: [Checklist này kiểm tra chất lượng yêu cầu/readiness nào]  
**Checklist ID**: `[CL-YYYYMMDD-001]` | **Ngày tạo**: `[DATE]` | **Người review**: `[Tên/Team]`  
**Trạng thái review**: `[Chưa bắt đầu / Đang review / Hoàn tất]` | **Lần review**: `[Lần 1 / Final]`  
**Tính năng**: `[Link tới spec.md]` | **Loại checklist**: `[Requirement Quality / Plan Readiness / Task Quality / Release Readiness / Custom]`  
**Bước hiện tại → Bước tiếp theo**: `[spec → /speckit-docbiz hoặc /speckit-plan | plan → /speckit-tasks | tasks → /speckit-implement]`  
**Artifact chính được kiểm tra**: `[spec.md / plan.md / tasks.md]` | **Nguồn tham chiếu**: `[constitution.md, spec.md, plan.md...]`

---

## Phạm vi & Artifact đã kiểm tra

- **Trong phạm vi**: [Khía cạnh/rủi ro được kiểm tra — lưu ý: Requirement Quality chỉ kiểm chất lượng câu chữ/đặc tả, KHÔNG kiểm code implementation]
- **Ngoài phạm vi**: [Phần không kiểm tra]

| Artifact | Đường dẫn/Link | Trạng thái | Ghi chú |
|----------|----------------|------------|---------|
| `spec.md` | [link/path] | Đã kiểm / Không áp dụng | [Ghi chú] |
| `plan.md` | [link/path] | Đã kiểm / Không có / Không áp dụng | [Ghi chú] |

---

## Kết quả tổng hợp

**Trạng thái**: `[Chưa review / Pass / Pass có điều kiện / Fail]`  
**Tổng số item**: `[N]` | **Pass**: `[N]` | **Fail**: `[N]` | **Không áp dụng**: `[N]` | **Blocker fail**: `[N]`

**Quy tắc kết luận & checkbox**:
- `Pass` (0 `[Blocker]`/`[High]` fail), `Không áp dụng` (kèm lý do ngắn nếu `[Blocker]`/`[High]`), và `Fail (ngoại lệ đã phê duyệt)` (có đủ dòng trong bảng Ngoại lệ): dùng `[x]`.
- `Fail` chưa phê duyệt hoặc `Chưa kiểm`: dùng `[ ]` và chặn gate `/speckit-implement`.
- Severity chuẩn: `[Blocker]`, `[High]`, `[Medium]`, `[Low]`. Tag chuẩn: `[Completeness]`, `[Clarity]`, `[Consistency]`, `[Measurability]`, `[Coverage]`, `[Traceability]`, `[Security]`, `[Data]`, `[Migration]`, `[Compatibility]`, `[Observability]`, `[Constitution]`, `[Readiness]`, `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`.

---

## [Nhóm kiểm tra — THAY THẾ VÍ DỤ BẰNG ITEM THỰC TẾ]

<!-- Mã CHK### tăng tuần tự duy nhất, không tái sử dụng mã đã xóa, ≥80% item có tham chiếu [Spec §X] / [Plan §Y] hoặc marker [Gap]/[Ambiguity]/[Conflict]/[Assumption]. -->

- [ ] CHK001 `[Blocker]` `[Status: Chưa kiểm]` [Câu hỏi kiểm tra chất lượng đặc tả/tài liệu cụ thể? `[Completeness, Spec §X]`]
- [ ] CHK002 `[High]` `[Status: Chưa kiểm]` [Câu hỏi kiểm tra tính rõ ràng/đo lường cụ thể? `[Clarity, Spec §Y]`]

<!-- Khi item Fail, ghi ngay bên dưới item: Phát hiện, Ảnh hưởng, Đề xuất, Tham chiếu, Owner, Hạn xử lý. -->

---

## Ngoại lệ được phê duyệt

| Item | Lý do ngoại lệ | Rủi ro chấp nhận | Owner | Hạn xử lý | Người phê duyệt | Hạn xem lại |
|------|----------------|------------------|-------|------------|------------------|-------------|
| [CHK### hoặc "Không áp dụng"] | [Lý do] | [Rủi ro] | [Tên/team] | [Ngày/mốc] | [Tên] | [Ngày] |

---

## Kết luận và hành động tiếp theo

**Kết quả checklist**: `[Pass / Pass có điều kiện / Fail]`  
**Có được chuyển bước tiếp theo không**: `[Có / Không]`  
**Bước tiếp theo được đề xuất**: `[/speckit-clarify | /speckit-docbiz | /speckit-plan | /speckit-tasks | /speckit-implement]`  
**Item cần xử lý trước**: `[CHK### hoặc "Không có"]`
