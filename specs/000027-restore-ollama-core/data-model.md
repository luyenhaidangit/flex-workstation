# Thực thể dữ liệu & Mô hình dữ liệu: Khôi phục hạ tầng lõi AI (Ollama)

**Branch**: `000027-restore-ollama-core` | **Ngày**: 2026-08-05 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md)

---

## 1. Trạng thái thực thể dữ liệu

**Không áp dụng**.

**Lý do**: Tính năng này khôi phục dịch vụ hạ tầng AI cục bộ (Ollama container + volume + HAProxy routing) trong môi trường phát triển `flex-environment`. Không có bảng dữ liệu database, migration script hay thực thể nghiệp vụ ứng dụng nào được tạo mới hoặc thay đổi.

---

## 2. Lưu trữ dữ liệu hạ tầng (Docker Volume)

Mặc dù không có thực thể dữ liệu ứng dụng, hệ thống sử dụng một Docker Volume để lưu vết weights mô hình AI:

- **Volume name**: `ollama_data`
- **Mount path trong container**: `/root/.ollama`
- **Mục đích**: Persistence lưu trữ các mô hình AI đã nạp (ví dụ `qwen2.5:1.5b`), đảm bảo mô hình không bị nạp lại từ đầu mỗi khi restart container (đáp ứng FR-004 & AC-002).
