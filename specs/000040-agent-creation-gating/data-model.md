# Data model: Phân tách trạng thái tạo và cấu hình Agent

## Phạm vi dữ liệu

Feature không tạo hoặc sửa schema. Tài liệu này mô tả các thực thể và UI state đã tồn tại để implementation giữ đúng semantics.

## Agent

| Thuộc tính liên quan | Ý nghĩa | Sử dụng trong flow |
|---|---|---|
| `id` | Mã định danh Agent | `null` nghĩa là màn tạo chưa có Agent; có giá trị thì mở khóa cấu hình |
| `name` | Tên Agent | Hiển thị header và gửi trong create/update |
| `description` | Mô tả/vai trò Agent | Hiển thị header và gửi trong create/update |
| `status` | Trạng thái hiện có của Agent | `inactive` hiển thị “Bản nháp”; `active` giữ flow “Lưu và phát hành lại” |
| `updatedAt` | Thời điểm cập nhật từ server | Hiển thị “Cập nhật lúc” chỉ khi Agent đã tồn tại |

## Wizard UI state

| State | Điều kiện | Hành vi |
|---|---|---|
| `create` | `agentId === null` | Chỉ step 1 thao tác; lock step 2-5; hide chat/report; primary “Tạo Agent và tiếp tục” |
| `draft` | `agentId !== null` và `status === 'inactive'` | Step 2-5 được mở; primary “Lưu và tiếp tục”; status “Bản nháp” |
| `published` | `agentId !== null` và `status === 'active'` | Giữ publish flow hiện có; primary “Lưu và phát hành lại” |
| `view` | route data `mode === 'view'` | Form và actions read-only theo hành vi hiện có |

## Step state

- Step 1 active khi wizard ở thông tin chung.
- Step 1 completed khi đã có `agentId`.
- Step 2-5 locked khi chưa có `agentId`; unlocked khi đã có `agentId`.
- `currentStep` chỉ là UI navigation state, không được xem là persisted business state.

## Validation rules

- `name` bắt buộc trước create/update.
- `role` tối đa 500 ký tự theo form hiện có.
- `instructions` tiếp tục dùng validation hiện có trong form; việc persist field này không thuộc contract của feature.

## State transitions

```text
create --(valid createAgent)--> draft --(publish flow hiện có)--> published
create --(click locked step)--> create
draft --(valid updateAgent + save-and-continue)--> draft
```

