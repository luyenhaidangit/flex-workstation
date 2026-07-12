# Research: Nền tảng AI Agent đa tenant — MVP

**Feature**: `000008-agent-platform-mvp` | **Ngày**: 2026-07-12

Trả lời các câu hỏi kỹ thuật TQ-001..TQ-005 trong [plan.md](./plan.md), dựa trên khảo sát trực tiếp workspace (repo con, compose, spec cũ) ngày 2026-07-12.

---

## R1 — Hiện trạng workspace (khảo sát nền)

**Phát hiện**:

- Repo con thực tế: `flex-agents` (Claude plugin — KHÔNG phải code sản phẩm), `flex-auth-service` (.NET 9, EF Core + **Oracle** — `EntityFrameworkCoreExtensions.cs` dùng `UseOracle`), `flex-api-gateway` (.NET 9), `flex-microfrontend` (Angular 16.1), `flex-environment` (compose). KHÔNG tồn tại `flex-microservice` (INSTALL.md nhắc tới là tài liệu cũ/lỗi thời).
- `flex-environment` active stack: HAProxy, PostgreSQL 16 (`flexdb`), MySQL 8 (tenant DB — 000005), RabbitMQ 4.1, Elasticsearch/Logstash/Kibana/Filebeat, Portainer, Prometheus/Grafana + oracle-exporter. **Không có Redis, không có MinIO.**
- ELK index template `flex-ecs-template` đã có sẵn field `labels.tenant_id`, `trace.id` — observability đa tenant dùng được ngay.
- `docker-compose.app.yml` khai báo `flex-ai-gateway` (image `luyenhaidangit/flex-ai-gateway:1.0.2-dev`, Python — DSN `oracle+oracledb`) `depends_on` các service `ollama`, `ollama-init`, `qdrant` — nhưng các service này **chỉ còn trong `temp/`** (bị comment/di dời), tức app stack AI hiện không chạy được từ compose active.
- Cấu hình Ollama/Qdrant đã từng chạy: `qwen2.5:1.5b` (chat), embed `nomic-embed-text-v2-moe` (768d, Cosine), Qdrant `v1.16.3`, chunk 1000/overlap 200/top-k 5 (`mounts/flex-ai-gateway/.env`).

**Hệ quả cho plan**: MVP tái dùng tối đa hạ tầng đã có (PostgreSQL, MySQL, RabbitMQ, ELK, Ollama/Qdrant config cũ); phần thiếu (MinIO) bổ sung nhỏ. Code sản phẩm cần repo mới vì không repo hiện có nào đúng bounded context.

## R2 — TQ-001: Provisioning tenant trong app

**Decision**: Port flow SQL của `flex-environment/scripts/provision-tenant-db.sh` (000005) vào `ProvisioningService` trong platform (in-app, programmatic): tạo MySQL database + user + grant, ghi `tenant_databases`/`tenant_database_audit_logs`, rollback khi fail; bổ sung bước mới: apply schema tenant v1, tạo bucket MinIO, tạo tenant owner + membership.

**Rationale**: App cần provisioning theo request API với transaction, audit và trạng thái — gọi shell script từ container .NET fragile (không có bash/docker CLI trong image), khó test và khó kiểm soát lỗi từng bước. Flow SQL của 000005 đã được validate trên môi trường thật (xác nhận 2026-07-12) nên port lại là rủi ro thấp.

**Alternatives considered**: (a) `Process.Start` gọi script — loại vì phụ thuộc docker CLI trong container; (b) sidecar provisioner riêng — loại vì thêm deployable không cần ở MVP. Scripts 000005 giữ nguyên làm công cụ ops thủ công.

## R3 — TQ-002: Model và embedding cho tiếng Việt trên hạ tầng local

**Decision**: Giữ cấu hình đã có: Ollama `qwen2.5:1.5b` cho chat, `nomic-embed-text-v2-moe` cho embedding (768 chiều, Cosine — khớp `QDRANT_VECTOR_SIZE=768` đã cấu hình). Model name/params đặt trong env config của platform (`OLLAMA_MODEL_NAME`, `OLLAMA_EMBED_MODEL`), swap không cần build lại.

**Rationale**: Qwen2.5 hỗ trợ đa ngôn ngữ gồm tiếng Việt; nomic-embed-v2 là MoE multilingual — đây là bộ đã được chọn và chạy trong environment trước đó. Chạy CPU local nên 1.5b là trade-off hợp lý cho MVP solo; chất lượng chưa cao là rủi ro đã ghi trong spec §15 (mitigate bằng test chat trước publish + rollback).

**Alternatives considered**: (a) OpenAI/Claude API — chất lượng tốt hơn nhiều nhưng cần API key trả phí + gửi dữ liệu tenant ra ngoài, để giai đoạn sau qua `IModelGateway`; (b) model lớn hơn (7b) — CPU local không kham nổi 20 hội thoại đồng thời. Rủi ro còn lại: NFR-001 (first-token < 5s) có thể không đạt với câu hỏi dài trên CPU — chấp nhận đo thực tế ở quickstart, nếu fail thì giảm `max_tokens`/nâng model gateway lên API ngoài.

## R4 — TQ-004: Cơ chế streaming cho widget

**Decision**: SignalR cho cả admin test chat và widget public. Widget authenticate bằng session token ngắn hạn (đổi từ widget key qua `POST /api/public/chat/sessions`), truyền qua query string `access_token` theo chuẩn SignalR.

**Rationale**: Một cơ chế streaming duy nhất cho hai luồng; SignalR tự fallback (WebSocket → SSE → long-polling) nên widget hoạt động sau proxy/firewall đa dạng của website tenant; server .NET native. HAProxy đã phục vụ WebSocket được (cấu hình timeout tunnel khi cần).

**Alternatives considered**: SSE thuần cho widget — nhẹ hơn (~0 dependency) nhưng phải viết thêm một đường streaming + reconnect thủ công song song với SignalR của admin; loại để giảm bề mặt code. Kích thước bundle widget (~40KB gzip gồm signalr.js) chấp nhận được.

## R5 — TQ-005: Khôi phục ollama/qdrant trong flex-environment

**Decision**: Đưa `ollama`, `ollama-init`, `qdrant` từ `temp/docker-compose.override.yml` về `docker-compose.app.yml` (giữ image version cũ: `ollama/ollama:0.6.2`, `qdrant/qdrant:v1.16.3`), sửa `ollama-init` pull đúng cặp model của R3; thêm `minio` vào `docker-compose.infra.yml`; thêm service `flex-agent-service` vào `docker-compose.app.yml`. Tuân thủ quy ước CLAUDE.md của repo: env var inline default, volume `name:` không explicit, comment `# Mô tả ngắn.`, không secrets mechanism.

**Rationale**: Cấu hình đã chạy trước đó chỉ bị di dời vào `temp/` — khôi phục ít rủi ro hơn viết mới. `flex-ai-gateway` (service cũ trong app.yml) không dùng cho MVP: giữ nguyên, không sửa/xóa (nguyên tắc thay đổi phẫu thuật — nhắc user quyết định riêng nếu muốn gỡ).

**Alternatives considered**: Tách stack AI sang file compose mới `docker-compose.ai.yml` — loại vì CLAUDE.md của repo quy định cấu trúc 4 file cố định.

## R6 — TQ-003: Spec 000003-ai-agent-base trùng phạm vi

**Decision**: `specs/000003-ai-agent-base` (chỉ có spec.md, không plan/tasks) được coi là bản phân tích sơ khởi và **bị thay thế (superseded) bởi 000008** — phạm vi của nó (tạo agent, huấn luyện tri thức, chạy thử, phát hành, theo dõi) là tập con của 000008. Ghi chú trạng thái này khi implement (task cập nhật header spec 000003), không xóa file.

**Rationale**: Tránh hai spec active trùng phạm vi gây mâu thuẫn source-of-truth (constitution §4); giữ file làm lịch sử phân tích.

**Alternatives considered**: Merge nội dung 000003 vào 000008 — không cần, 000008 đã phủ đầy đủ và chi tiết hơn (000003 còn nhiều câu hỏi mở chưa trả lời).

## R7 — Xác thực và phát hành JWT (bổ trợ DEC-005)

**Decision**: Platform tự phát hành JWT (HS256, secret qua env var), claims: `sub` (user id), `tenant_id`, `role`; refresh token lưu PostgreSQL. Password hash bằng ASP.NET Identity `PasswordHasher` (không kéo full ASP.NET Identity framework — chỉ dùng hasher + bảng users tự quản).

**Rationale**: Đủ cho MVP solo, không phụ thuộc `flex-auth-service` (Oracle, khác domain); giữ đường tích hợp SSO sau này bằng cách thay authentication scheme.

**Alternatives considered**: Full ASP.NET Identity — nặng schema không cần; Keycloak/IdentityServer — thêm hạ tầng vận hành ngoài phạm vi MVP.

---

## Tóm tắt rủi ro còn lại sau research

| Rủi ro | Mức | Xử lý |
|--------|-----|-------|
| First-token > 5s trên CPU với qwen2.5:1.5b | Trung | Đo ở quickstart; giảm max_tokens/top-k; đường swap sang API ngoài đã có (IModelGateway) |
| Chất lượng trả lời tiếng Việt của model 1.5b | Cao (đã ghi spec §15) | Test chat trước publish; rollback; nâng model qua config |
| HAProxy WebSocket timeout cắt streaming dài | Thấp | Cấu hình `timeout tunnel` cho route hub; SignalR tự reconnect |
| Image `flex-ai-gateway` cũ trong app.yml gây nhầm lẫn | Thấp | Không đụng; nhắc user quyết định gỡ ở PR riêng |
