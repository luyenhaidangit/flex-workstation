# Quickstart: Xác minh persistence MVP 01–08

1. Khởi động ba PostgreSQL databases staging: `exchange`, `broker`, `vsd`; cấp secret riêng ngoài Git.
2. Chạy `scripts/validate-all.sh` và `scripts/update-sql.sh`; CI/CD hoặc Kubernetes Job chạy `scripts/migrate.sh` theo thứ tự `exchange` → `broker` → `vsd`. Seed Alpha/Beta trong `seed/local` hoặc `seed/test` không được chạy production.
3. Chạy kịch bản MVP 01 trong `exchange`, khởi động lại service và xác minh rehydration cùng `TradeExecuted` reference.
4. Đưa trade reference vào `broker`, tạo account/reservation, gửi lại source và xác nhận không có reservation/balance trùng.
5. Đưa clearing instruction vào `vsd`, ghi ledger từ external trade/account reference, chạy T+ và kiểm tra journal cân bằng cùng obligation trace.
6. Chạy reconciliation với statement khớp/lệch; xác nhận matched/alert và không auto-fix.
7. Thử truy vấn chéo tenant/broker; phải bị từ chối không lộ dữ liệu.
8. Restore backup staging cho từng database, gọi health/trace/reconciliation smoke xuyên contract và lưu bằng chứng NFR-006.
