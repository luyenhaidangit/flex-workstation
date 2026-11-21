# C4 Context - Flex Platform

Nguồn: `workstation.json` và `docs/architecture/system-map.md` (mục 4, 5). Chưa đối chiếu với code từng repo.

```mermaid
C4Context
  title System Context - Flex Platform

  Person(user, "Người dùng", "Dùng giao diện web của Flex")
  Person(dev, "Developer / DevOps", "Phát triển, triển khai, vận hành")

  System(flex, "Flex Platform", "Frontend, gateway, auth, agent, exchange")
  System_Ext(oracle, "Oracle Cloud Database", "DB lịch sử, đang bị thay thế dần")
  System_Ext(github, "GitHub", "Lưu mã nguồn các repo Flex")

  Rel(user, flex, "Sử dụng", "HTTPS")
  Rel(dev, flex, "Triển khai và vận hành")
  Rel(dev, github, "Push code", "Git")
  Rel(flex, oracle, "Đọc/ghi dữ liệu lịch sử", "SQL")
```

## Ghi chú

| Cạnh | Trạng thái | Bằng chứng |
| --- | --- | --- |
| Flex Platform → Oracle | `Confirmed by user`, đang bỏ dần | `system-map.md` mục 5 |
| Developer → GitHub | `Confirmed` | `workstation.json` (url các repo) |
| Người dùng → Flex Platform | `Inferred` | Có `flex-microfrontend` |
