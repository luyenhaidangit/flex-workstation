# Checklist: Thêm một service (repo con) mới

Áp dụng khi thêm một service/product mới vào workspace dưới dạng repo con độc lập (ví dụ: một backend service .NET mới tương tự `flex-auth-service`). Không áp dụng cho thay đổi bên trong repo con đã có — checklist đó thuộc về repo con, không phải workstation.

Tham chiếu: [system-map.md](../system-map.md) (bản đồ workspace), [speckit/workflow.md](../speckit/workflow.md) (luồng spec-trước-code).

## 0. Trước khi tạo repo

- [ ] Tính năng đã có spec Speckit (`$speckit-specify`) nếu đủ lớn/rủi ro để vượt quick gate; xem `CLAUDE.md` mục "Speckit Workflow" để biết ngưỡng.
- [ ] Plan (`$speckit-plan`) đã xác định repo con mới là cần thiết (không nhét được vào repo hiện có) — ghi lý do trong mục "Theo dõi độ phức tạp" của `plan.md`.
- [ ] Tên repo đã chốt **trước khi** viết plan/spec, hoặc nếu đổi tên sau khi đã viết, rà lại toàn bộ `specs/<feature>/` (`plan.md`, `research.md`, `data-model.md`, `contracts/*.md`, `quickstart.md`) để tên khớp 100% với repo thật — tránh lệch giữa tên dự kiến trong spec và tên repo thực tế đã tạo trên GitHub.

## 1. Tạo & đăng ký repo

- [ ] Tạo repo trên GitHub (hoặc git host tương ứng), clone vào root `flex-workstation/` với đúng tên thư mục sẽ dùng.
- [ ] Thêm entry vào `workstation.json` → `repositories.items` (`name` + `url`, không kèm token/credential trong URL).
- [ ] Xác nhận repo con nằm trong `.gitignore` của workstation (mẫu `<repo-con>/` — thường đã có quy tắc chung, chỉ cần verify không bị track nhầm vào git của workstation).

## 2. Khởi tạo cấu trúc project bên trong repo con

Mirror cấu trúc của service .NET hiện có (`flex-auth-service`) trừ khi tech stack khác:

- [ ] `README.md` — mô tả ngắn gọn service.
- [ ] `CLAUDE.md` — context riêng cho repo con này (project overview, solution structure, quy ước code) — **khác** với `CLAUDE.md` của workstation, không copy nguyên văn.
- [ ] `SPEC.md` (tùy chọn) — quy ước đặt tên/kiến trúc riêng của service nếu cần.
- [ ] `.gitignore`, `.gitattributes`, `.dockerignore` theo chuẩn .NET/Visual Studio.
- [ ] `.env.example` — liệt kê biến môi trường bắt buộc, không chứa giá trị thật.
- [ ] `Dockerfile` + `Jenkinsfile` nếu service có CI/CD pipeline riêng.
- [ ] Solution `.sln` + layering tương tự `Flex.Auth`/`Flex.Domain`/`Flex.Infrastructures` (đổi tên theo domain của service mới).
- [ ] `secrets/` (nếu cần credential dạng file, ví dụ Oracle Wallet) — phải nằm trong `.gitignore`, không commit.

## 3. Hạ tầng (nếu service cần datastore/dịch vụ mới)

Trong `flex-environment`:

- [ ] Thêm service vào đúng compose file theo vai trò (`docker-compose.infra.yml` hạ tầng nền, `docker-compose.app.yml` app, `docker-compose.tools.yml` công cụ, `docker-compose.monitoring.yml` giám sát).
- [ ] Nếu cần schema mới trên datastore chia sẻ (PostgreSQL `flexdb`) → viết migration có kèm rollback script (theo mẫu `NNN_*.sql` / `NNN_*_rollback.sql`), áp dụng thủ công qua `docker exec ... psql` trước khi start app — không dùng ORM auto-migrate ở môi trường chia sẻ.
- [ ] Tuân thủ quy ước riêng của `flex-environment`: env var inline default (`${VAR:-value}`), không tạo `secrets/` mechanism hay `*_PASSWORD_FILE`, volume khai báo `volume_name:` không `name:` tường minh.
- [ ] Cập nhật `flex-environment/INSTALL.md` nếu luồng cài đặt/khởi động thay đổi.

## 4. Tài liệu workstation cần cập nhật

- [ ] `docs/system-map.md`: thêm vào snapshot cây thư mục, bảng "Manifest repo" và bảng "Projects".
- [ ] `docs/onboarding.md`: chỉ cập nhật nếu luồng bootstrap thực sự đổi (ví dụ thêm bước cài tool mới) — cây thư mục ví dụ trong file này không cần liệt kê đủ mọi repo (đã có `+-- ...`).
- [ ] `README.md` (root workstation): thêm liên kết nếu có tài liệu mới cần lên index.

## 5. Sau khi implement

- [ ] `/speckit-tasks` → `/speckit-implement` đã chạy hết task trong `tasks.md`, đánh dấu `[X]`.
- [ ] `quickstart.md` của feature đã chạy thực tế, ghi kết quả vào bảng "Ghi kết quả".
- [ ] Nếu feature này supersede một spec cũ (ví dụ trùng phạm vi) → cập nhật header spec cũ là "superseded by <feature-id>", không xóa.

## Sai lầm cần tránh

- Đừng viết/hoàn thiện spec-plan trước rồi tạo repo với tên khác mà không đồng bộ lại — gây lệch tài liệu vs thực tế (đã xảy ra với `000008-agent-platform-mvp`: plan dự kiến `flex-agent-platform`, repo thực tế tạo là `flex-agent-service`).
- Đừng tạo submodule/subtree hoặc ràng buộc version giữa repo con và workstation nếu không được yêu cầu rõ.
- Đừng để credential/token lọt vào `workstation.json`, compose file của `flex-environment`, hoặc bất kỳ file nào commit vào repo.
