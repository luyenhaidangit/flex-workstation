# MVP 26 — Anomaly detection bằng ML

## Mục tiêu

Nâng cấp giám sát thị trường từ rule-based sang model học từ pattern giao dịch, phát hiện hành vi bất thường không có rule định nghĩa sẵn.

## Phạm vi

- Unsupervised clustering (k-means hoặc DBSCAN) trên feature vector giao dịch: volume, price impact, order cancellation rate, inter-arrival time, account relationship graph.
- Phát hiện cluster bất thường so với baseline và gắn alert với độ tin cậy.
- Supervised model huấn luyện từ case điều tra đã xác nhận của MVP 10 (nhãn do điều tra viên gán).
- Human-in-the-loop: điều tra viên confirm/reject alert của model để cải thiện nhãn.
- Model retrain theo lịch với dữ liệu mới; version history được lưu.

## Quy tắc

- Model output là điểm risk và cluster; không tự block tài khoản hay gửi báo cáo.
- Alert phải đính feature values nguồn để điều tra viên hiểu được lý do.
- Thay alert rule-based của MVP 10 bằng model, không xoá hẳn rule đơn giản để fallback.

## Kịch bản demo

Huấn luyện model trên 90 ngày ảo; tiêm bot wash trading không có rule nào bắt; model sinh alert; điều tra viên confirm; model retrain với nhãn mới và bắt được pattern tiếp theo nhanh hơn.

## Điều kiện hoàn thành

- Model đạt recall cao hơn rule-based trên tập test có nhãn.
- Alert có đủ thông tin để điều tra viên ra quyết định mà không cần đọc thêm log kỹ thuật.
- Chưa có graph neural network, real-time inference sub-second hay mô hình ngôn ngữ lớn cho phân tích.
