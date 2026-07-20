# Checklist chất lượng đặc tả: Migrate dữ liệu HNX khỏi in-memory

## Metadata

**Mục đích**: Xác nhận `spec.md` đủ rõ, đầy đủ và sẵn sàng trước khi chuyển sang `$speckit-clarify` hoặc `$speckit-plan`.  
**Checklist ID**: `REQ-000018`  
**Ngày tạo**: 2026-07-20  
**Người review**: Luyện Hải Đăng  
**Trạng thái review**: Hoàn tất  
**Lần review**: Lần 1  
**Tính năng**: [spec.md](../spec.md)  
**Artifact chính được kiểm tra**: `spec.md`  
**Nguồn tham chiếu**: `constitution.md`, `spec.md`

## Kết quả tổng hợp

**Trạng thái**: Fail

**Tổng số item**: 16  
**Pass**: 13  
**Fail**: 3  
**Không áp dụng**: 0  
**Blocker fail**: 1

**Bước tiếp theo được phép**: Cập nhật/trả lời câu hỏi mở trong `$speckit-clarify`; chưa được lập plan.

## Chất lượng nội dung

- [x] CHK001 `[High]` `[Status: Pass]` Spec không chứa chi tiết implementation không cần thiết. [Clarity]
- [x] CHK002 `[High]` `[Status: Pass]` Spec tập trung vào giá trị người dùng và nhu cầu nghiệp vụ. [Clarity]
- [x] CHK003 `[Medium]` `[Status: Pass]` Nội dung có thể hiểu bởi stakeholder không chuyên kỹ thuật. [Clarity]
- [x] CHK004 `[Blocker]` `[Status: Pass]` Các section bắt buộc của spec đã được hoàn tất. [Completeness]

## Tính đầy đủ của requirement

- [ ] CHK005 `[Blocker]` `[Status: Fail]` Còn câu hỏi làm rõ ảnh hưởng trực tiếp đến scope và data contract.
  - **Phát hiện**: §18 còn hai marker `[CẦN LÀM RÕ]` về nhóm migrate đầu tiên và chiến lược chuyển tiếp.
  - **Ảnh hưởng**: Không thể chốt phạm vi và rollout để lập plan kỹ thuật.
  - **Đề xuất**: Trả lời hai câu hỏi trong `$speckit-clarify` hoặc ghi nhận quyết định được stakeholder chấp nhận.
  - **Tham chiếu**: Spec §18.
  - **Owner**: Nhóm Flex.
  - **Hạn xử lý**: Trước `$speckit-plan`.
- [x] CHK006 `[High]` `[Status: Pass]` Requirement kiểm thử được, có priority và traceability. [Measurability]
- [x] CHK007 `[High]` `[Status: Pass]` Success criteria đo lường được và không phụ thuộc công nghệ. [Measurability]
- [x] CHK008 `[High]` `[Status: Pass]` User scenario và acceptance criteria bao phủ luồng chính. [Coverage]
- [x] CHK009 `[Medium]` `[Status: Pass]` Trạng thái lỗi, edge case và thao tác lặp đã được xác định. [Coverage]
- [x] CHK010 `[High]` `[Status: Pass]` Scope, ngoài phạm vi, phụ thuộc và giả định đã rõ. [Completeness]

## Readiness và governance

- [x] CHK011 `[High]` `[Status: Pass]` Functional requirement quan trọng có acceptance criteria hoặc traceability. [Traceability]
- [x] CHK012 `[Medium]` `[Status: Pass]` User scenario bao phủ các luồng P1/P2 thực tế. [Coverage]
- [ ] CHK013 `[High]` `[Status: Fail]` Các gate constitution liên quan đến scope, data, permission, contract và security chưa thể xác nhận đầy đủ trước khi chốt nhóm migrate đầu tiên.
  - **Phát hiện**: Chưa có quyết định về nhóm dữ liệu HNX được migrate đầu tiên và chiến lược cutover/đọc song song.
  - **Ảnh hưởng**: Có thể làm thay đổi scope, data contract và chiến lược tương thích của plan.
  - **Đề xuất**: Trả lời hai câu hỏi mở tại §18 trong `$speckit-clarify`.
  - **Tham chiếu**: Spec §3, §18, FR-004, FR-005.
  - **Owner**: Nhóm Flex.
  - **Hạn xử lý**: Trước `$speckit-plan`.
- [x] CHK014 `[High]` `[Status: Pass]` Không có chi tiết implementation làm sai phạm vi spec. [Readiness]
- [x] CHK015 `[Medium]` `[Status: Pass]` Rủi ro, audit và dữ liệu nhạy cảm được ghi nhận. [Coverage]
- [ ] CHK016 `[Medium]` `[Status: Fail]` Feature có điều kiện sẵn sàng rõ ràng trước khi chuyển bước.
  - **Phát hiện**: Điều kiện chọn đợt đầu tiên và quyết định chuyển tiếp chưa được xác nhận.
  - **Ảnh hưởng**: Chưa thể sinh plan kỹ thuật có dependency và rollout cụ thể.
  - **Đề xuất**: Làm rõ scope đợt đầu và chiến lược cutover.
  - **Tham chiếu**: Spec §19.
  - **Owner**: Nhóm Flex.
  - **Hạn xử lý**: Trước `$speckit-plan`.

## Ngoại lệ được phê duyệt

| Item | Lý do ngoại lệ | Rủi ro chấp nhận | Owner | Hạn xử lý | Người phê duyệt | Hạn xem lại |
|---|---|---|---|---|---|---|
| Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng |

## Kết luận và hành động tiếp theo

**Kết quả checklist**: Fail

**Có được chuyển bước tiếp theo không**: Chỉ được chuyển sang `$speckit-clarify`; chưa được `$speckit-plan`.

**Ghi chú**: Hai câu hỏi mở ảnh hưởng trực tiếp đến scope và data contract nên được giữ là blocker cho đến khi được xác nhận hoặc chấp nhận có chủ đích.
