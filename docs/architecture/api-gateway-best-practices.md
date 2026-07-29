# Best Practices cho API Gateway

Tài liệu này tổng hợp các nguyên tắc thiết kế/vận hành API Gateway áp dụng chung cho các gateway trong hệ thống Flex Workstation (hiện tại: `flex-api-gateway`). Dùng làm checklist tham chiếu khi review hoặc cải tiến gateway hiện có.

---

## 1. Authentication & Authorization

- Xác thực tập trung tại gateway (OAuth2/OIDC, JWT validation) thay vì để từng service tự làm.
- Hỗ trợ API key cho client-to-server, mTLS cho service-to-service.
- Tích hợp với identity provider (Keycloak, Auth0, Okta...).
- Áp dụng RBAC/ABAC để kiểm soát quyền truy cập theo endpoint/scope.

---

## 2. Rate Limiting & Throttling

- Giới hạn theo client, theo endpoint, theo tier (free/premium).
- Dùng thuật toán token bucket hoặc sliding window.
- Trả về `429 Too Many Requests` kèm header `Retry-After`.
- Có quota riêng cho traffic đột biến (burst) vs traffic ổn định (sustained).

---

## 3. Bảo mật

- Terminate TLS tại gateway, enforce HTTPS only.
- Validate và sanitize input (header, query param, body size limit).
- Tích hợp WAF để chặn injection, XSS.
- Cấu hình CORS chặt chẽ, tránh wildcard `*` ở production.
- IP whitelist/blacklist khi cần.

---

## 4. Routing & Load Balancing

- Path-based, header-based, hoặc weight-based routing.
- Hỗ trợ load balancing (round robin, least connections).
- Tích hợp service discovery (Consul, Eureka, Kubernetes DNS).
- Hỗ trợ canary release / blue-green deployment qua traffic splitting.

---

## 5. Resilience Patterns

- Circuit breaker để tránh cascading failure khi backend down.
- Retry với exponential backoff (cẩn thận với idempotency).
- Timeout hợp lý cho từng upstream service.
- Bulkhead isolation — tách resource pool giữa các service để lỗi 1 chỗ không lan ra toàn hệ thống.
- Fallback response/cached response khi backend lỗi.

---

## 6. Observability

- Structured logging (JSON) cho mọi request/response.
- Distributed tracing — propagate `trace-id`/`correlation-id` qua toàn bộ chuỗi service.
- Metrics theo mô hình RED (Rate, Errors, Duration) hoặc USE.
- Health check endpoint (`/healthz`, `/readyz`) để phục vụ load balancer & k8s probes.

---

## 7. Caching

- Cache response ở gateway cho GET request ít thay đổi.
- Hỗ trợ ETag/Last-Modified để giảm băng thông.
- Chiến lược invalidate cache rõ ràng (TTL, event-based).

---

## 8. Versioning & Transformation

- API versioning qua URL (`/v1/`) hoặc header, tránh breaking change đột ngột.
- Request/response transformation, protocol translation (REST ↔ gRPC/SOAP) nếu cần.
- Header manipulation (thêm/xóa header trước khi forward).

---

## 9. Hiệu năng

- Connection pooling tới backend.
- Bật compression (gzip/brotli).
- Gateway phải là stateless để scale ngang dễ dàng.
- Tối ưu để bản thân gateway không trở thành bottleneck (đo latency overhead riêng của nó).

---

## 10. High Availability

- Deploy nhiều instance, không có single point of failure.
- Multi-region/multi-AZ nếu traffic lớn.
- Zero-downtime deployment, hỗ trợ rollback nhanh.
- Dynamic config reload (thay đổi routing/rate limit mà không cần restart).

---

## 11. Developer Experience

- Cung cấp OpenAPI/Swagger spec tự động.
- Developer portal để quản lý API key, xem docs, theo dõi usage.
- Chuẩn hóa error response format (RFC 7807 Problem Details là một lựa chọn tốt).

---

## Tham khảo

Một số công cụ phổ biến để tham khảo cách triển khai: Kong, Apigee, AWS API Gateway, Envoy/Istio Gateway, Traefik, Spring Cloud Gateway.

Xem tài liệu kỹ thuật hiện có của gateway trong hệ thống tại `flex-api-gateway/docs/` (README, GlobalLogging, PRODUCTION-READY-GATEWAY...).
