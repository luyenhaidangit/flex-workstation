# Checklist chất lượng đặc tả: [TÊN TÍNH NĂNG]

## Metadata

**Mục đích**: Xác nhận `spec.md` đủ rõ, đầy đủ và sẵn sàng trước khi chuyển sang `/speckit-clarify`, `/speckit-docbiz` và `/speckit-plan`.  
**Checklist ID**: `REQ-[NNNNNN]`  
**Ngày tạo**: [NGÀY]  
**Người review**: {{GIT_USER_NAME}}  
**Trạng thái review**: Đang review  
**Lần review**: Lần 1  
**Tính năng**: [spec.md](../spec.md)  
**Artifact chính được kiểm tra**: `spec.md`  
**Nguồn tham chiếu**: `constitution.md`, `spec.md`

---

## Kết quả tổng hợp

**Trạng thái**: [Pass / Pass có điều kiện / Fail]  
**Tổng số item**: 16 | **Pass**: [N] | **Fail**: [N] | **Không áp dụng**: [N] | **Blocker fail**: [N]  
**Bước tiếp theo được phép**: `/speckit-clarify` (nếu còn mơ hồ) → `/speckit-docbiz` (bắt buộc nếu `spec.md §20` còn `CHƯA ĐÁNH GIÁ`) → `/speckit-plan`

**Quy tắc kết luận & checkbox**:
- `Pass` (không có `[Blocker]`/`[High]` fail), `Không áp dụng` (đã review và xác nhận không liên quan), và `Fail (ngoại lệ đã phê duyệt)` (có đủ thông tin ở bảng ngoại lệ bên dưới): dùng `[x]` và không chặn gate `/speckit-implement`.
- `Fail` chưa phê duyệt hoặc `Chưa kiểm`: dùng `[ ]` và chặn gate.

---

## Chất lượng nội dung

- [ ] CHK001 `[High]` `[Status: Chưa kiểm]` Spec không chứa chi tiết implementation không cần thiết (ngôn ngữ, framework, API, cấu trúc code). [Clarity]
- [ ] CHK002 `[High]` `[Status: Chưa kiểm]` Spec tập trung vào giá trị người dùng và nhu cầu nghiệp vụ. [Clarity]
- [ ] CHK003 `[Medium]` `[Status: Chưa kiểm]` Nội dung có thể hiểu bởi stakeholder không chuyên kỹ thuật. [Clarity]
- [ ] CHK004 `[Blocker]` `[Status: Chưa kiểm]` Các section bắt buộc của spec đã được hoàn tất (hoặc ghi `Không áp dụng` kèm lý do ngắn). [Completeness]

## Tính đầy đủ của requirement

- [ ] CHK005 `[Blocker]` `[Status: Chưa kiểm]` Không còn marker `[NEEDS CLARIFICATION]` hoặc `[CẦN LÀM RÕ]` chặn phạm vi, dữ liệu, quyền hoặc UX chính. [Readiness]
- [ ] CHK006 `[High]` `[Status: Chưa kiểm]` Requirement kiểm thử được, không mơ hồ và có priority/traceability khi áp dụng. [Measurability]
- [ ] CHK007 `[High]` `[Status: Chưa kiểm]` Success criteria đo lường được và không phụ thuộc công nghệ. [Measurability]
- [ ] CHK008 `[High]` `[Status: Chưa kiểm]` User scenario và acceptance criteria đã bao phủ luồng chính. [Coverage]
- [ ] CHK009 `[Medium]` `[Status: Chưa kiểm]` Trạng thái lỗi, edge case và thao tác lặp liên quan đã được xác định. [Coverage]
- [ ] CHK010 `[High]` `[Status: Chưa kiểm]` Phạm vi MVP, ngoài phạm vi, phụ thuộc và giả định đã rõ. [Completeness]

## Readiness và governance

- [ ] CHK011 `[High]` `[Status: Chưa kiểm]` Functional requirement quan trọng có acceptance criteria hoặc traceability phù hợp. [Traceability]
- [ ] CHK012 `[Medium]` `[Status: Chưa kiểm]` User scenario bao phủ các luồng P1/P2 thực tế. [Coverage]
- [ ] CHK013 `[High]` `[Status: Chưa kiểm]` Các gate constitution liên quan đến scope, data, permission, contract và security đã được đánh giá. [Constitution]
- [ ] CHK014 `[High]` `[Status: Chưa kiểm]` Không có chi tiết implementation làm sai phạm vi của spec. [Readiness]
- [ ] CHK015 `[Medium]` `[Status: Chưa kiểm]` Rủi ro, audit và dữ liệu nhạy cảm được ghi nhận khi áp dụng. [Coverage]
- [ ] CHK016 `[Medium]` `[Status: Chưa kiểm]` Feature có điều kiện sẵn sàng rõ ràng ở §19 và §20 được giữ để `/speckit-docbiz` đánh giá trước `/speckit-plan`. [Readiness]

---

## Ghi chú khi có item Fail

Khi item có `Status: Fail`, ghi trực tiếp ngay bên dưới item đó các trường: `Phát hiện`, `Ảnh hưởng`, `Đề xuất`, `Tham chiếu`, `Owner`, `Hạn xử lý`.

## Ngoại lệ được phê duyệt

| Item | Lý do ngoại lệ | Rủi ro chấp nhận | Owner | Hạn xử lý | Người phê duyệt | Hạn xem lại |
|------|----------------|------------------|-------|------------|------------------|-------------|
| Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng |

---

## Kết luận và hành động tiếp theo

**Kết quả checklist**: [Pass / Pass có điều kiện / Fail]  
**Có được chuyển bước tiếp theo không**: [Có / Không]  
**Bước tiếp theo được đề xuất**: [`/speckit-clarify` hoặc `/speckit-docbiz` trước khi sang `/speckit-plan`]
