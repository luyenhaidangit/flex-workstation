# Quickstart: Xác minh persistence MVP 01–08

1. Khởi động PostgreSQL staging và cấp tenant connection secret ngoài Git.
2. Chạy `liquibase --defaults-file=liquibase.properties validate`, kiểm tra `update-sql`, rồi để CI/CD hoặc Kubernetes Job chạy `update`; seed Alpha/Beta chỉ dùng local/test và phải chạy lại an toàn.
3. Chạy kịch bản MVP 01 tạo order/trade, khởi động lại service và xác minh rehydration/trade trace.
4. Tạo account/reservation, gửi lại source và xác nhận không có reservation/balance trùng.
5. Ghi ledger từ trade, chạy T+ và kiểm tra journal cân bằng cùng obligation trace.
6. Chạy reconciliation với statement khớp/lệch; xác nhận matched/alert và không auto-fix.
7. Thử truy vấn chéo tenant/broker; phải bị từ chối không lộ dữ liệu.
8. Restore backup tenant staging, gọi health/trace/reconciliation smoke và lưu bằng chứng NFR-006.
