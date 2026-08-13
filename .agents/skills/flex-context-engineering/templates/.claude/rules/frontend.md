---
paths:
  - "src/components/**/*.tsx"
  - "src/app/**/*.tsx"
---

# Frontend rules

- Component mặc định là Server Component. Chỉ thêm `'use client'` khi thực sự cần state/effect/event handler — và ghi comment 1 dòng nêu lý do.
- Đặt file: `TODO_src/components/<domain>/<ComponentName>/index.tsx` + `styles.ts` + `index.test.tsx`.
- Props: interface đặt tên `TODO_<ComponentName>Props`, export cùng component. Không dùng `React.FC`.
- Styling: TODO_Tailwind utility class. NEVER dùng inline `style={{}}` trừ giá trị tính động lúc runtime.
- Dùng design token có sẵn (`TODO_bg-surface`, `TODO_text-muted`), NEVER hardcode mã màu hex.
- Data fetching qua TODO_TanStack Query hook trong `TODO_src/hooks/queries/`. NEVER gọi `fetch` trực tiếp trong component.
- Accessibility bắt buộc: mọi phần tử tương tác phải focus được bằng bàn phím, icon-only button phải có `aria-label`.
- NEVER sửa file trong `TODO_src/components/ui/**` (generated từ TODO_shadcn) — wrap lại thay vì sửa trực tiếp.
