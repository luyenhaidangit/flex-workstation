# Hợp đồng giao tiếp UI Component & Routing (UI Contract)

## 1. Route Definition

- **Path**: `/agents/create`
- **Module**: `AgentCatalogModule`
- **Route Guard**: `CanDeactivateGuard` (Kiểm tra Form dirty khi chuyển trang)

---

## 2. Component Output & Events

```typescript
export interface AgentCreateWizardEvents {
  /** Phát ra khi tạo agent thành công */
  saved: EventEmitter<Agent>;
  
  /** Phát ra khi hủy tạo và quay về danh sách */
  cancelled: EventEmitter<void>;
}
```

---

## 3. Navigation Rules

| Thao tác | Hành vi | Điều kiện |
|---|---|---|
| Bấm `+ Thêm mới` tại `/agents` | Điều hướng sang `/agents/create` | Luôn cho phép |
| Bấm `Tiếp tục` tại Step N | Kiểm tra validation Step N, nếu thành công -> sang Step N+1 | Step N form valid |
| Bấm trực tiếp vào Step K trên Stepper | Chuyển đến Step K | K <= currentStep hoặc Step K đã pass validation |
| Bấm `Hủy` / biểu tượng `(X)` | Hiển thị Dialog cảnh báo nếu Form dirty -> quay về `/agents` | - |
