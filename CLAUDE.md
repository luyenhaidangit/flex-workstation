# CLAUDE.md

Tài liệu này là chỉ dẫn tổng quan cho Claude Code khi làm việc trong repository `flex-workstation`.

## Vai trò của repository

`flex-workstation` là workstation trung tâm để điều phối nhiều project trong cùng hệ thống Flex. Repository này không phải nơi chứa toàn bộ mã nguồn nghiệp vụ. Nó giữ vai trò:

- Quản lý tài liệu định hướng chung cho hệ thống.
- Theo dõi danh sách project con, trạng thái, task và ghi chú triển khai.
- Lưu quy ước kiến trúc, cách tổ chức thư mục và quyết định kỹ thuật.
- Lưu skill, checklist hoặc quy trình có thể tái sử dụng.
- Bootstrap máy mới để người mới clone repo có thể bắt đầu làm việc nhanh.

## Ngôn ngữ và phong cách

- Dùng tiếng Việt có dấu trong tài liệu, ghi chú, mô tả task và nội dung hướng dẫn.
- Giữ nguyên tiếng Anh cho tên file, thư mục, command, biến môi trường, package, API, framework và thuật ngữ kỹ thuật phổ biến.
- Viết ngắn, rõ, trực tiếp. Ưu tiên hướng dẫn có thể thực hiện được.
- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repository.

## Tài liệu cần đọc trước

Khi bắt đầu một phiên làm việc mới, đọc theo thứ tự:

1. `README.md`: mục đích workspace, cách mở workspace và cách khởi tạo nhanh.
2. `docs/tasks.md`: danh sách task, trạng thái và ưu tiên hiện tại.
3. `docs/projects.md`: các Git project đang được theo dõi.
4. `docs/architecture.md`: cách tổ chức workspace và quy ước kiến trúc.
5. `docs/onboarding.md`: bootstrap máy mới và cài Claude Code.
6. `skills/README.md`: cách tổ chức skill dùng chung.

Nếu task liên quan trực tiếp đến một project con, đọc thêm `README.md` và tài liệu riêng của project đó trước khi sửa.

## Quy trình làm việc mặc định

1. Xác định yêu cầu thuộc `flex-workstation` hay thuộc một project con.
2. Kiểm tra tài liệu liên quan trước khi đề xuất hoặc sửa.
3. Khi onboarding người mới hoặc thêm repo mới, xác nhận cấu trúc thư mục mục tiêu trước khi clone, tạo thư mục hoặc cập nhật workspace.
4. Nếu triển khai thay đổi, giữ phạm vi nhỏ và đúng mục tiêu.
5. Nếu thêm project, cập nhật `docs/projects.md`, `flex-workstation.code-workspace` và task liên quan trong `docs/tasks.md`.
6. Nếu thêm quy trình lặp lại, cân nhắc đưa vào `skills/` hoặc tài liệu trong `docs/`.
7. Nếu thay đổi onboarding hoặc công cụ cài đặt, cập nhật `bootstrap.ps1`, `docs/onboarding.md` và phần liên quan trong `README.md`.
8. Nếu thay đổi trải nghiệm khởi tạo cho người dùng Windows, cập nhật thêm `START_HERE.cmd` hoặc `OPEN_PROJECT.cmd`.
9. Sau khi sửa, chạy kiểm tra phù hợp, ví dụ parse JSON, chạy script ở chế độ an toàn hoặc kiểm tra Git status.

## Cấu trúc thư mục cần xác nhận khi onboarding

Trước khi hướng dẫn người mới clone repo hoặc trước khi tự động thêm project vào workspace, cần xác nhận với người onboard rằng cấu trúc local sẽ theo dạng:

```text
C:\Workspace\Project\
|-- flex-workstation\
|-- flex-frontend\
|-- flex-backend\
|-- flex-api-gateway\
+-- ...
```

Quy ước:

- `C:\Workspace\Project` là thư mục cha chứa toàn bộ repository trong nhóm Flex.
- `flex-workstation` là repo điều phối, tài liệu và bootstrap.
- Các repo nghiệp vụ như `flex-frontend`, `flex-backend`, `flex-api-gateway` nằm ngang hàng với `flex-workstation`, không nằm bên trong `flex-workstation`.
- Không tự giả định repo đã tồn tại. Luôn kiểm tra thư mục thực tế và hỏi lại nếu tên repo, đường dẫn hoặc danh sách project chưa rõ.

Câu xác nhận nên ngắn gọn, ví dụ:

```text
Anh/chị xác nhận cấu trúc local sẽ là C:\Workspace\Project\ với các repo nằm ngang hàng như flex-workstation, flex-frontend, flex-backend, flex-api-gateway... đúng không?
```

## Quy ước khi chỉnh sửa

- Không refactor hoặc đổi cấu trúc ngoài phạm vi yêu cầu.
- Không xóa thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo ra.
- Không tự động sửa mã nguồn của project con nếu người dùng chỉ yêu cầu cập nhật workstation.
- Không tạo submodule, subtree hoặc liên kết version giữa repo nếu chưa có yêu cầu rõ ràng.
- Khi sửa Markdown, giữ tiêu đề, bullet và mô tả bằng tiếng Việt có dấu.
- Khi thêm lệnh shell, ưu tiên PowerShell cho Windows vì workstation hiện đang dùng Windows.

## Bootstrap và công cụ

Script bootstrap chính nằm tại:

```powershell
.\bootstrap.ps1
```

Entrypoint thân thiện cho người dùng Windows là:

```text
START_HERE.cmd
```

Người mới nên double-click `START_HERE.cmd` thay vì double-click trực tiếp `bootstrap.ps1`, vì Windows thường mở hộp thoại chọn app cho file `.ps1`.

Entrypoint mở nhanh VS Code là:

```text
OPEN_PROJECT.cmd
```

File này phải mở thư mục cha của `flex-workstation`, ví dụ `C:\Workspace\Project`, để VS Code nhìn thấy các repo nằm ngang hàng như `flex-frontend`, `flex-backend`, `flex-api-gateway`.

Mục tiêu của script:

- Kiểm tra các công cụ tối thiểu như `git`, VS Code CLI `code`, `winget` và Claude Code CLI `claude`.
- Cài Claude Code bằng native installer chính thức nếu máy chưa có `claude`.
- Cho phép dùng WinGet qua tùy chọn `-UseWinget` khi cần.
- Mở workspace bằng `-OpenWorkspace` nếu VS Code CLI có sẵn.
- Khi dùng `-OpenWorkspace`, mở thư mục cha `C:\Workspace\Project` thay vì chỉ mở riêng `flex-workstation`.

Khi thay đổi script này, cần chạy tối thiểu:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -SkipClaudeInstall
```

## Project đang theo dõi

Danh sách chính nằm trong `docs/projects.md`. Hiện workspace đang theo dõi:

- `flex-workstation`: repository điều phối.
- `flex-frontend`: frontend cho nhóm project Flex, cần xác nhận repository URL trước khi clone.
- `flex-backend`: backend cho nhóm project Flex, cần xác nhận repository URL trước khi clone.
- `flex-api-gateway`: API Gateway cho nhóm project Flex.

Mặc định các project con nằm ngang hàng với `flex-workstation` trong thư mục cha đã xác nhận. Luôn kiểm tra `docs/projects.md`, file `.code-workspace` và thư mục thực tế trước khi thao tác.

## Tiêu chuẩn hoàn tất

Một thay đổi được xem là hoàn tất khi:

- Yêu cầu chính đã được xử lý.
- Tài liệu liên quan đã được cập nhật nếu hành vi, cấu trúc hoặc quy trình thay đổi.
- Lệnh kiểm tra phù hợp đã chạy hoặc có ghi chú rõ vì sao chưa chạy.
- `git status --short` được kiểm tra để nắm phạm vi file thay đổi.
