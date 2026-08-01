# Kiến trúc Mạng & Topology: Windows Host vs WSL2 / Docker

Tài liệu này mô tả chi tiết sơ đồ mạng, ranh giới giao tiếp và cách giải quyết xung đột kết nối giữa **Windows Host** và **WSL2 / Docker Container**.

---

## 1. Sơ đồ Topology Chi tiết (3 Tầng Mạng)

```mermaid
flowchart TB
    subgraph WindowsHost ["Windows Host (Máy vật lý của người dùng)"]
        Browser["Trình duyệt Web / Client\nhttps://api.flex.internal/api/v1/agents"]
        AgentService["flex-agent-service (.NET 9.0)\nhttp://localhost:59338\n(Microservice C# nghiệp vụ)"]
        WinFirewall["Windows Firewall (Kiểm soát cổng Inbound 59338)"]
    end

    subgraph WSL2 ["WSL2 Linux Virtual Machine / Docker Network (flex_net)"]
        HAProxy["1️⃣ HAProxy (Edge Reverse Proxy / SSL Termination)\nCổng 80/443 (bắt domain api.flex.internal)"]
        Gateway["2️⃣ flex-api-gateway (YARP / Application Gateway)\nCổng 8080 (Định tuyến / Auth / Rate Limit)"]
    end

    %% Luồng đi
    Browser -->|"Tầng 1: Đăng nhập HTTPS Port 443"| HAProxy
    HAProxy -->|"Forward internal (flex_net)"| Gateway
    Gateway -->|"Tầng 2: YARP Routing sang host.docker.internal:59338"| WinFirewall
    WinFirewall -->|"Tầng 3: Nhận HTTP Request"| AgentService

    classDef hostStyle fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef wslStyle fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;

    class WindowsHost hostStyle;
    class WSL2 wslStyle;
```

---

## 2. Giải thích lý do xảy ra lỗi `502 Bad Gateway (Timeout)`

### 🔴 Bản chất vấn đề 1: Phân tách Loopback (`127.0.0.1`)
- **Trong Windows**: `localhost` (`127.0.0.1`) là giao diện mạng nội bộ của Windows.
- **Trong WSL2**: WSL2 là một máy ảo Linux (Hyper-V / WSL2 Lightweight VM) có dải IP ảo riêng. `localhost` trong WSL2 là của Linux, **KHÔNG PHẢI** `localhost` của Windows.

### 🔴 Bản chất vấn đề 2: Kestrel Binding trên Windows
- Khi chạy `flex-agent-service` trên Windows với cấu hình mặc định `"applicationUrl": "http://localhost:59338"`, Kestrel C# chỉ lắng nghe duy nhất cổng `127.0.0.1:59338`.
- Khi `flex-api-gateway` chạy trong WSL2 trỏ tới IP của Windows (ví dụ `192.168.1.44` hoặc `host.docker.internal`), gói tin mạng xuất phát từ WSL2 đi vào card mạng Windows với IP nguồn dạng `172.x.x.x` hoặc `192.168.x.x`.
- Vì Kestrel chỉ nhận packet tới `127.0.0.1`, nó lập tức từ chối/bỏ qua packet đến từ WSL2 $\rightarrow$ Sinh lỗi **Connection Timed Out / 502 Bad Gateway**.

### 🔴 Bản chất vấn đề 3: Windows Firewall
- Tường lửa Windows (Windows Defender Firewall) mặc định chặn các kết nối đến từ adapter mạng ảo WSL2 vào các port chưa được mở (inbound rule).

### 🔴 Bản chất vấn đề 4: `host.docker.internal` sai nghĩa khi KHÔNG dùng Docker Desktop
Môi trường thực tế của `flex-environment` chạy **dockerd native bên trong distro Ubuntu của WSL2** (distro `docker-desktop` không được dùng/đang Stopped), kết hợp `.wslconfig` có `networkingMode=mirrored`.

- Trên **Docker Desktop**, `host.docker.internal` được vpnkit bắc cầu thật sang Windows host — đây là cơ chế mà tài liệu này (bản trước) ngầm giả định.
- Trên **dockerd native trong WSL2** (như ở đây), `extra_hosts: ["host.docker.internal:host-gateway"]` chỉ resolve về **gateway của bridge `docker0` bên trong chính VM WSL2** (ví dụ `172.17.0.1`) — đây là địa chỉ nội bộ của VM, **không hề định tuyến ra Windows**.
- Vì `networkingMode=mirrored`, việc gọi `http://localhost:59338` **từ shell của VM WSL2** (`wsl <cmd>`) thành công (mirrored mode có cơ chế forward loopback đặc biệt cho `127.0.0.1`/`localhost`). Nhưng một **container** có network namespace riêng (`flex_net` bridge) — `localhost` bên trong container là chính nó, không kế thừa cơ chế mirrored loopback của VM, và `host.docker.internal` cũng không được vpnkit xử lý vì không có Docker Desktop.
- **Kết luận**: với setup này, cách duy nhất để container chạm được service trên Windows là gọi thẳng vào **IP LAN thật của máy Windows** (địa chỉ mà `ipconfig` trên Windows và `ip addr` trong WSL2 VM cùng chia sẻ do mirrored mode), chứ không phải qua tên `host.docker.internal` mặc định.

---

## 3. Các Phương án Xử lý (Solution Options)

### 🟢 Phương án A: Cho phép `flex-agent-service` lắng nghe từ WSL2 (Khuyên dùng khi chạy hybrid)

#### Bước 1: Sửa Kestrel binding trong `launchSettings.json`
Thay đổi `applicationUrl` từ `localhost` thành `0.0.0.0` (nghe tất cả card mạng):

```json
{
  "profiles": {
    "Flex.Agent": {
      "commandName": "Project",
      "launchBrowser": false,
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      },
      "applicationUrl": "http://0.0.0.0:59338"
    }
  }
}
```

#### Bước 2: Thêm Inbound Rule cho Windows Firewall
Mở PowerShell (Run as Administrator) trên Windows và chạy lệnh cho phép cổng `59338`:

```powershell
New-NetFirewallRule -DisplayName "Allow Agent Service for WSL" -Direction Inbound -LocalPort 59338 -Protocol TCP -Action Allow
```

> Bước này bắt buộc phải do người dùng tự chạy (thay đổi cấu hình bảo mật hệ thống) — AI agent không tự thực hiện.

#### Bước 3: Trỏ đúng địa chỉ đích trong cấu hình YARP (bắt buộc khi KHÔNG dùng Docker Desktop)
Với dockerd native trong WSL2 + `networkingMode=mirrored` (xem mục 2, vấn đề 4), `host.docker.internal` **không** trỏ về Windows. Phải override resolve của tên này về IP LAN thật của Windows trong `docker-compose.app.yml`:

```yaml
services:
  flex-api-gateway:
    extra_hosts:
      - "host.docker.internal:192.168.28.241"   # IP LAN thật của Windows host (mirrored mode) — xem `ipconfig` nếu đổi
```

Giữ nguyên tên `host.docker.internal` trong `yarp.json` (destination `agent-service`) để dễ đọc; chỉ cần sửa nơi resolve tên này ở compose. IP này do DHCP cấp nên **có thể đổi** khi đổi mạng/router cấp lại lease — nếu gateway báo lỗi kết nối agent-service trở lại, kiểm tra lại `ipconfig` trên Windows và cập nhật IP tại đây (cân nhắc đặt DHCP reservation cho máy Windows để cố định IP).

---

### 🟢 Phương án B: Chạy `flex-agent-service` trực tiếp trong WSL2 hoặc Docker Container (Đồng bộ 100% môi trường)

Nếu đưa `flex-agent-service` vào cùng mạng Docker/WSL2 với API Gateway:
- Cả hai service cùng thuộc mạng `flex_net`.
- API Gateway gọi trực tiếp tới `http://flex-agent-service:8080/` qua DNS nội bộ của Docker.
- Không bị vướng ranh giới Windows/WSL2 Firewall.

---

## 4. Sơ đồ luồng giao tiếp sau khi khắc phục

```mermaid
sequenceDiagram
    autonumber
    actor User as Trình duyệt (Windows)
    participant Gateway as flex-api-gateway (WSL2/Docker)
    participant Agent as flex-agent-service (Windows Host)
    participant DB as PostgreSQL agentdb (Docker)

    User->>Gateway: GET https://api.flex.internal/api/v1/agents (Bearer Token)
    Note over Gateway: YARP match route /api/v1/agents/*<br/>Forward sang http://host.docker.internal:59338
    Gateway->>Agent: HTTP GET http://host.docker.internal:59338/api/v1/agents
    Note over Agent: Kestrel 0.0.0.0:59338 tiếp nhận request<br/>Xác thực JWT Token
    Agent->>DB: Query SELECT * FROM agents
    DB-->>Agent: Trả về danh sách Agent
    Agent-->>Gateway: HTTP 200 OK (JSON List Agents)
    Gateway-->>User: HTTP 200 OK (Hiển thị UI Angular)
```
