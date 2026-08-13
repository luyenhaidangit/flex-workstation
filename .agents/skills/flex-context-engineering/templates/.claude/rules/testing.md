---
paths:
  - "**/*.test.{ts,tsx}"
  - "**/*.spec.{ts,tsx}"
  - "tests/**/*"
---

# Testing rules

<!-- Chỉ nạp vào context khi Claude đọc file khớp `paths` ở trên. -->

- Runner: TODO_Vitest. Chạy 1 file: `TODO_pnpm test <path> -- --run`.
- Cấu trúc: `describe(<đơn vị>)` → `it('should <hành vi mong đợi>')`. Không dùng `test()`.
- Arrange–Act–Assert, ngăn bằng dòng trống. Mỗi `it` một assertion chính.
- Mock ở ranh giới I/O (HTTP client, repository, clock). KHÔNG mock module nội bộ mình sở hữu.
- Thời gian: dùng `TODO_vi.useFakeTimers()`, không `sleep`.
- Fixture đặt ở `TODO_tests/fixtures/`, tạo qua factory function, không hardcode object lớn trong test.
- NEVER: xoá/skip test đang fail để làm xanh CI. Nếu test sai, sửa test và nói rõ lý do.
- Bug fix bắt buộc kèm 1 test tái hiện lỗi, đặt tên `it('should not <lỗi> (regression #TODO_123)')`.

Mẫu:

```ts
describe('createInvoice', () => {
  it('should reject invoice with negative amount', async () => {
    const repo = makeFakeInvoiceRepo();

    const result = await createInvoice({ amount: -1 }, ctx(repo));

    expect(result.ok).toBe(false);
    expect(result.error).toBeInstanceOf(ValidationError);
  });
});
```
