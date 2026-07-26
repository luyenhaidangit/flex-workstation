# Mô hình dữ liệu: Chuyển cấu hình danh sách market và schedule từ hardcode JSON sang CSDL

**Feature**: `000021-market-database-config`  
**Ngày**: 2026-07-26  

---

## 1. Cơ sở dữ liệu (`flex-database`)

### Migration Script: `001-create-exchange-markets.sql`
Vị trí: `flex-database/hnx/changelog/releases/1.0.0.1/001-create-exchange-markets.sql`

```sql
-- Tạo bảng quản lý danh sách thị trường và lịch phiên giao dịch
CREATE TABLE IF NOT EXISTS exchange_markets (
    market_code VARCHAR(20) PRIMARY KEY,
    market_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    description TEXT NULL,
    has_ato BOOLEAN NOT NULL DEFAULT true,
    has_plo BOOLEAN NOT NULL DEFAULT false,
    pre_open_duration_seconds INT NOT NULL DEFAULT 5,
    ato_duration_seconds INT NOT NULL DEFAULT 10,
    continuous_duration_seconds INT NOT NULL DEFAULT 30,
    intermission_duration_seconds INT NOT NULL DEFAULT 5,
    continuous2_duration_seconds INT NOT NULL DEFAULT 30,
    atc_duration_seconds INT NOT NULL DEFAULT 10,
    plo_duration_seconds INT NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index tra cứu thị trường active
CREATE INDEX IF NOT EXISTS idx_exchange_markets_status ON exchange_markets(status);

-- Seed dữ liệu ban đầu cho 4 thị trường
INSERT INTO exchange_markets (
    market_code, market_name, status, has_ato, has_plo, 
    pre_open_duration_seconds, ato_duration_seconds, continuous_duration_seconds, 
    intermission_duration_seconds, continuous2_duration_seconds, atc_duration_seconds, plo_duration_seconds
) VALUES 
('HOSE', 'Sở Giao dịch Chứng khoán TP.HCM', 'active', true, false, 5, 10, 30, 5, 30, 10, 0),
('HNX', 'Sở Giao dịch Chứng khoán Hà Nội', 'active', false, true, 5, 0, 30, 5, 30, 10, 5),
('UPCOM', 'Thị trường Công ty Đại chúng chưa niêm yết', 'active', false, false, 5, 0, 30, 5, 30, 10, 0),
('DERIVATIVES', 'Thị trường Chứng khoán Phái sinh', 'active', true, false, 2, 10, 30, 5, 30, 10, 0)
ON CONFLICT (market_code) DO NOTHING;
```

---

## 2. C# DTO & Entity Model (`flex-exchange-service`)

### Entity Model: `MarketEntity.cs`
Vị trí: `Flex.Exchange.Api/Models/MarketEntity.cs`

```csharp
namespace Flex.Exchange.Api.Models;

public sealed record MarketEntity(
    string MarketCode,
    string MarketName,
    string Status,
    string? Description,
    bool HasAto,
    bool HasPlo,
    int PreOpenDurationSeconds,
    int AtoDurationSeconds,
    int ContinuousDurationSeconds,
    int IntermissionDurationSeconds,
    int Continuous2DurationSeconds,
    int AtcDurationSeconds,
    int PloDurationSeconds,
    DateTime CreatedAt,
    DateTime UpdatedAt
);
```

### View DTO: `MarketView.cs`
Vị trí: `Flex.Exchange.Api/Models/MarketView.cs`

```csharp
namespace Flex.Exchange.Api.Models;

public sealed record MarketView(
    string MarketCode,
    string MarketName,
    string Status,
    bool HasAto,
    bool HasPlo
);
```
