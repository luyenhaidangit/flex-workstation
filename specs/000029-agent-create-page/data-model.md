# Mô hình dữ liệu & State (Data Model & Wizard State)

## 1. Wizard Step State Interface

```typescript
export interface WizardStep {
  id: number;
  title: string;
  subTitle?: string;
  isCompleted: boolean;
  isActive: boolean;
  isDisabled: boolean;
}
```

Danh sách 7 bước mặc định:
1. `Thiết lập thông tin chung`
2. `Thêm thủ tục hành chính Công an`
3. `Thêm thông tin Cơ quan Công an`
4. `Thêm văn bản khác`
5. `Thiết lập kỹ năng`
6. `Kiểm tra nhân viên AI`
7. `Phát hành`

---

## 2. Agent Form State Interface (Bước 1 & các bước kế tiếp)

```typescript
export interface CreateAgentFormState {
  // Step 1: Thông tin chung
  avatarUrl: string;
  name: string;
  role: string;
  executionLevel: 'province' | 'commune'; // Cấp tỉnh | Cấp xã
  organization: string;
  instructions: string; // Chỉ dẫn cho Agent

  // Step 2-4: Thủ tục & Tài liệu
  procedures?: any[];
  organizationDocs?: any[];
  otherDocs?: any[];

  // Step 5: Kỹ năng
  skills?: string[];

  // Step 7: Trạng thái phát hành
  status: 'active' | 'inactive';
}
```

---

## 3. Avatar Preset Data Model

Danh sách mẫu hình đại diện công an/nhân viên gợi ý ở Bước 1:
```typescript
export interface AvatarPreset {
  id: string;
  url: string;
  label: string;
}
```
