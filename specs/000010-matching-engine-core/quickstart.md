# Quickstart: Xác minh lõi khớp lệnh (FlexSim MVP 01)

**Ngày**: 2026-07-14
**Repo đích**: `flex-exchange-service` (clone tại `C:\Workspace\Project\flex-workstation\flex-exchange-service`)

Hướng dẫn này xác minh feature chạy đúng end-to-end sau khi implement. Chi tiết schema xem [data-model.md](data-model.md) và [contracts/exchange-core.md](contracts/exchange-core.md).

## Điều kiện tiên quyết

- .NET 9 SDK (`dotnet --version` ≥ 9.0).
- Không cần database, message broker hay biến môi trường nào (FR-010).

## Build và test

Chạy từ root repo `flex-exchange-service`:

```powershell
dotnet restore Flex.Exchange.sln
dotnet build Flex.Exchange.sln
dotnet test Flex.Exchange.sln
```

**Kỳ vọng**: build 0 warning nghiêm trọng; toàn bộ test pass, trong đó tối thiểu có các nhóm (SC-003):

| Nhóm test | Xác minh |
|-----------|----------|
| Không khớp | Lệnh vào sổ nằm chờ, không sinh trade |
| Khớp toàn phần | AC-001, AC-002 |
| Khớp một phần | AC-003, AC-004 |
| Ưu tiên giá | AC-005 (kèm khớp xuyên nhiều mức giá) |
| Ưu tiên thời gian | AC-006 |
| Hủy lệnh | AC-007, AC-008 (kèm hủy lặp lại) |
| Validate lệnh | AC-009 — từng ràng buộc tick/biên độ/lô/khối lượng |
| Determinism | Cùng kịch bản chạy 10 lần → kết quả giống hệt (SC-002) |

## Chạy demo console

```powershell
dotnet run --project src/Flex.Exchange/Flex.Exchange.csproj
```

Demo chạy 3 kịch bản trong `docs/mvp/01-matching-rules.md` (workstation) và in dòng sự kiện + snapshot sau mỗi kịch bản.

**Kỳ vọng output theo kịch bản** (SC-001):

1. **Khớp toàn phần**: bán 100 FXS @20.000 rồi mua 100 FXS @20.000 → in `OrderAccepted` ×2, đúng **một** `TradeExecuted` (100 @20.000); snapshot rỗng hai bên.
2. **Khớp một phần**: bán 100 @20.000 rồi mua 200 @20.000 → một `TradeExecuted` (100 @20.000); snapshot: bên mua còn một mức 20.000 khối lượng 100, bên bán rỗng.
3. **Hủy lệnh** (mở rộng demo): đặt lệnh chờ, hủy (`OrderCancelled`), lệnh đối ứng vào sau không khớp — snapshot xác nhận.

## Kiểm tra tính xác định thủ công (tùy chọn)

Chạy demo 2 lần liên tiếp và so sánh output:

```powershell
dotnet run --project src/Flex.Exchange/Flex.Exchange.csproj > run1.txt
dotnet run --project src/Flex.Exchange/Flex.Exchange.csproj > run2.txt
git diff --no-index run1.txt run2.txt   # kỳ vọng: không khác biệt
```

(Nếu output có in timestamp `ReceivedAt`, demo phải in phần so sánh được — dòng sự kiện — tách khỏi phần timestamp, hoặc bỏ timestamp khỏi output demo.)

## Tiêu chí hoàn tất xác minh

- [ ] `dotnet test` pass 100%, đủ 8 nhóm test ở trên.
- [ ] Demo console cho đúng output 3 kịch bản.
- [ ] Chạy demo 2 lần cho output giống hệt.
- [ ] `src/Flex.Domain/Flex.Domain.csproj` không tham chiếu package runtime nào (FR-010).
