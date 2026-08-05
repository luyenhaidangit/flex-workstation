# Research: Tab Thiết lập thông tin chung & Phát hành đa kênh cho Agent

**Feature**: `specs/000028-agent-publish-channels` | **Ngày**: 2026-08-05

---

## TQ-001: Vị trí migration cho bảng dữ liệu kênh phát hành mới trong `agentdb`

**Câu hỏi**: `agentdb` đã có xung đột tiền lệ: tài liệu convention (`constitution.md` §Nguyên tắc VI, `docs/architecture/system-map.md`) yêu cầu migration `agentdb` PHẢI nằm ở `flex-database/agentdb/migrations/` (versioned SQL), và bảng `agents` gốc (`specs/000026-agent-catalog`) đúng theo quy ước này (`flex-database/agentdb/migrations/V1.1__create_table_agents.sql`). Nhưng feature gần nhất cũng chạm `agentdb` — `specs/000022-instagram-business` — lại đặt migration (`AddInstagramTables.sql`, tạo bảng `meta_account_connections`, `instagram_page_connections`) trong `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/Migrations/`, không có file tương ứng trong `flex-database/agentdb/`. Đây là xung đột thực tế giữa tài liệu và tiền lệ code gần nhất, đúng loại tình huống Constitution VI yêu cầu không được tự chọn theo thói quen.

**Đã hỏi người dùng** (2026-08-05): Chọn giữa (a) theo tài liệu convention `flex-database/agentdb/`, (b) theo tiền lệ Instagram `flex-agent-service/.../Persistence/Migrations/`.

**Quyết định**: (a) `flex-database/agentdb/migrations/` — theo đúng tài liệu convention đã document ở `constitution.md`/`system-map.md`, và đúng tiền lệ của bảng `agents` gốc (000026). File mới: `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql`.

**Lý do chọn**:
- `constitution.md` §4 (Source of Truth) xếp `constitution.md` ưu tiên cao nhất khi có mâu thuẫn giữa các artifact — bao gồm cả mâu thuẫn giữa tài liệu và code thực tế.
- Việc `AddInstagramTables.sql` lệch quy ước là drift cần được sửa riêng (ghi nhận ở đây, không phải lý do để tiếp tục lệch thêm).
- Giữ một nguồn migration duy nhất cho `agentdb` (`flex-database/agentdb/`) giúp rollback tập trung, đúng lý do Nguyên tắc VI đưa ra.

**Rủi ro còn lại**: `agentdb` hiện có 2 nguồn migration không đồng bộ (`flex-database/agentdb/` có V1.1; `flex-agent-service/.../Persistence/Migrations/` có `AddInstagramTables.sql` chưa được đối chiếu ngược lại). Đây là nợ kỹ thuật ngoài phạm vi feature này — **được ghi nhận, không xử lý ở đây** (không tự ý dọn migration của feature khác ngoài yêu cầu). Đề xuất theo dõi riêng ở `docs/architecture/system-map.md` hoặc một task dọn dẹp độc lập.

---

## TQ-002: Mô hình dữ liệu cho "Cấu hình kênh phát hành"

**Câu hỏi**: Lưu trạng thái bật/tắt kênh theo agent bằng cách nào — thêm cột boolean vào bảng `agents`, hay bảng riêng?

**Đã hỏi người dùng** (2026-08-05): Người dùng đề xuất trực tiếp tạo bảng riêng `agent_publish_locations` với các trường `location_code`, `location_name`, `configuration` (JSON), `agent_id`, ...

**Quyết định**: Bảng riêng `agent_publish_locations` (agentdb), không thêm cột vào bảng `agents`.

**Lý do chọn**:
- Đúng yêu cầu người dùng (2026-08-05).
- Phù hợp hướng mở rộng đã ghi trong spec (§9 Thực thể dữ liệu — "cấu trúc PHẢI cho phép chuyển một loại kênh từ 'chưa khả dụng' sang thao tác được trong tương lai mà không đổi mô hình dữ liệu ở mức khái niệm"): cột `configuration JSONB` để dành cho cấu hình riêng từng kênh (domain whitelist cho Website, page id cho Facebook, ...) khi các kênh đó được kích hoạt thật ở các feature sau, không cần đổi schema lại từ đầu.
- Không đụng tới bảng `agents` hiện có (giảm rủi ro hồi quy trên `specs/000026-agent-catalog`).

**Phương án đã loại**: Thêm cột `is_website_enabled BOOLEAN` vào bảng `agents`.
**Lý do loại**: Không mở rộng được khi có kênh thứ 2 hoạt động thật (phải thêm cột mới mỗi lần); người dùng đã chọn rõ phương án bảng riêng.

**MVP write scope**: Chỉ `location_code = 'website'` được phép ghi/bật thật ở MVP (FR-009); các `location_code` khác (`facebook_fanpage`, `zalo_oa`, `chatbot`, `zalo_personal`) hiển thị tĩnh phía Frontend, KHÔNG có row tương ứng trong bảng cho tới khi kênh đó thực sự được kích hoạt thật ở feature sau.

---

## TQ-003: Cơ chế lưu chung 1 nút "Lưu" cho cả 2 tab

**Câu hỏi**: Tab "Phát hành" có API/nút lưu riêng không?

**Đã hỏi người dùng** (2026-08-05, qua `/speckit-clarify`): Không tách biệt; dùng chung nút "Lưu" với tab "Thiết lập thông tin chung". Bật/tắt công tắc kênh chỉ là thay đổi tạm ở FE; chỉ khi bấm "Lưu" mới gửi xuống BE.

**Quyết định**: Mở rộng payload của 2 endpoint đã có `POST /api/v1/agents` và `PUT /api/v1/agents/{id}` (đã định nghĩa ở `specs/000026-agent-catalog/contracts/agent-catalog-api.yaml`) để nhận thêm mảng `publishLocations`, thay vì tạo endpoint mới. Không cần endpoint `PATCH` hoặc `POST` riêng cho tab "Phát hành".

**Lý do chọn**: Khớp chính xác cơ chế "1 nút Lưu chung" người dùng yêu cầu; endpoint hiện có đã có transaction/validation pipeline, tái sử dụng giảm rủi ro và đúng nguyên tắc thay đổi phẫu thuật (Constitution V).

**Phương án đã loại**: Endpoint riêng `PUT /api/v1/agents/{id}/publish-locations`.
**Lý do loại**: Sẽ cần 2 lần gọi API khi Lưu (1 cho info chung, 1 cho kênh) hoặc phải tự đồng bộ 2 network call ở FE để giả lập "1 nút Lưu" — phức tạp hơn không cần thiết so với gộp vào cùng 1 request.

---

## TQ-004: Danh sách 5 kênh cố định hiển thị ở tab Phát hành lấy từ đâu

**Câu hỏi**: Danh sách kênh (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân) và trạng thái "khả dụng"/"chưa khả dụng" của từng kênh nên định nghĩa ở đâu?

**Quyết định**: Định nghĩa tĩnh (hardcoded catalog) ở Frontend (`flex-microfrontend`), không lưu trong DB và không expose qua API riêng.

**Lý do chọn**: MVP chỉ có 1 kênh thật sự thao tác được (Website); 4 kênh còn lại chỉ là hiển thị tĩnh "chưa khả dụng", không có hành vi backend nào gắn với chúng (FR-009). Tạo bảng/endpoint riêng cho danh sách kênh tĩnh này là over-engineering so với yêu cầu MVP (Constitution V).

**Rủi ro chấp nhận**: Khi các kênh khác (Facebook, Zalo, Chatbot) được kích hoạt thật ở feature sau, danh sách catalog tĩnh này cần chuyển thành dữ liệu động (DB hoặc config service) — ghi nhận là công việc của feature đó, không xử lý trước ở đây.

---

## Tóm tắt quyết định

| TQ | Quyết định |
|----|------------|
| TQ-001 | Migration `agent_publish_locations` đặt tại `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql` |
| TQ-002 | Bảng riêng `agent_publish_locations` (agentdb), có cột `configuration JSONB` dự phòng mở rộng |
| TQ-003 | Mở rộng payload `POST`/`PUT /api/v1/agents` hiện có, không tạo endpoint mới |
| TQ-004 | Danh sách 5 kênh + trạng thái khả dụng định nghĩa tĩnh ở Frontend, không lưu DB |
