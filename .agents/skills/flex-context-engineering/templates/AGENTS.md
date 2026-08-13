# AGENTS.md

<!--
  Nguồn sự thật DUY NHẤT cho mọi coding agent (Claude Code, Codex, Copilot,
  Cursor, Gemini CLI, Windsurf, Aider...).
  Quy tắc vàng: nếu agent tự suy ra được từ repo (package.json, tsconfig,
  eslintrc, cấu trúc thư mục) thì XOÁ khỏi file này.
  Mục tiêu: 50-150 dòng. Trên 200 dòng là dấu hiệu cần cắt bớt.
-->

## Project

<!-- 2-3 câu. Chỉ những gì KHÔNG đọc được từ README. -->

TODO_PROJECT_NAME là TODO_MOTA_MOT_CAU.
Ngữ cảnh quan trọng: TODO (vd: "Đây là monolith đang tách dần sang service; code mới đi vào `src/modules/`, không thêm vào `src/legacy/`").

## Commands

<!-- Đặt SỚM. Agent tra lại mục này liên tục. Lệnh đầy đủ flag, copy-paste chạy được. -->

```bash
TODO_pnpm install --frozen-lockfile   # setup
TODO_pnpm dev                          # chạy local (port 3000)
TODO_pnpm test -- --run                # toàn bộ test, non-watch
TODO_pnpm test path/to/file.test.ts    # test 1 file (ưu tiên khi lặp nhanh)
TODO_pnpm lint --fix                   # lint + autofix
TODO_pnpm typecheck                    # tsc --noEmit
TODO_pnpm build                        # build production
```

**Definition of done:** `TODO_pnpm lint && pnpm typecheck && pnpm test` phải xanh trước khi báo hoàn thành.

## Tech constraints

<!-- Chỉ ghi cái ĐẶC THÙ / dễ sai. Không liệt kê cả stack. -->

- Package manager: TODO_pnpm — **không** dùng npm/yarn (lockfile sẽ hỏng).
- Node TODO_>=22. Runtime target: TODO.
- TODO_ORM/DB: dùng TODO, migration bằng `TODO_lệnh`. Không sửa file migration đã merge.
- TODO_Không thêm dependency mới nếu chưa hỏi.

## Code style

<!-- 1 đoạn code thật > 3 đoạn văn mô tả. -->

- Tuân theo linter/formatter đã cấu hình; không tự đặt style riêng.
- TODO_Named export, không default export.
- TODO_Không dùng `any`; dùng `unknown` + narrowing.
- TODO_Lỗi trả về theo Result type, không throw ở tầng domain.

Mẫu chuẩn cho một service function:

```ts
// TODO: dán 10-20 dòng code THẬT trong repo thể hiện đúng convention
export async function createInvoice(
  input: CreateInvoiceInput,
  ctx: RequestContext,
): Promise<Result<Invoice, DomainError>> {
  const parsed = createInvoiceSchema.safeParse(input);
  if (!parsed.success) return err(new ValidationError(parsed.error));
  // ...
}
```

## Testing

- Framework: TODO_Vitest. File test đặt cạnh source: `foo.ts` → `foo.test.ts`.
- TODO_Mọi bug fix phải kèm 1 test tái hiện lỗi (regression test).
- TODO_Không mock cái mình sở hữu; mock ở ranh giới I/O (HTTP, DB, clock).
- TODO_Test integration cần Docker: `docker compose up -d db` trước khi chạy.

## Boundaries — NEVER

<!-- Phần có ROI cao nhất. Viết mệnh lệnh, tuyệt đối, không "nên/hạn chế". -->

- NEVER commit trực tiếp vào `main`; luôn tạo branch `TODO_feat/<ticket>`.
- NEVER sửa: `TODO_src/generated/**`, `TODO_*.lock`, `TODO_db/migrations/*` đã merge.
- NEVER chạy lệnh phá huỷ dữ liệu (`drop`, `reset`, `--force` push) khi chưa được xác nhận.
- NEVER commit secret; biến môi trường khai báo trong `.env.example`.
- NEVER tự nâng version dependency ngoài phạm vi task.

## Ask, don't assume

<!-- Agent mặc định "cứ làm tới" — phải yêu cầu hỏi lại một cách tường minh. -->

Nếu yêu cầu mơ hồ về một trong các điểm sau, **dừng lại và hỏi** thay vì tự chọn:
- Thay đổi schema DB hoặc public API contract.
- Thêm dependency, thêm service, đổi kiến trúc.
- Có từ 2 cách làm hợp lệ trở lên với đánh đổi rõ rệt.

## Git & PR

- Commit: TODO_Conventional Commits (`feat:`, `fix:`, `chore:`).
- PR title: `TODO_[TICKET-123] mô tả ngắn`.
- Mỗi PR một mục đích; không trộn refactor với feature.
- Trước khi mở PR: chạy đủ bộ lệnh ở mục Definition of done.

<!--
  Ghi chú cho người maintain (agent không đọc phần comment này trong Claude Code):
  - Review file mỗi khi đổi tooling.
  - Chỉ thêm mục mới khi agent lặp lại SAI LẦM cụ thể lần thứ 2.
  - Thấy phần nào đã được lint/CI ép buộc → xoá khỏi đây.
-->
