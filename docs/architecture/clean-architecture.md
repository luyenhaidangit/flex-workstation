# Clean Architecture cho ứng dụng .NET

Tài liệu này là hướng dẫn thiết kế và triển khai Clean Architecture cho các ứng dụng .NET, đặc biệt là ASP.NET Core API và worker. Đây là tài liệu nền để khởi tạo source mới, review kiến trúc và thống nhất cách đặt business rule, transaction, integration, security, observability và test.

Clean Architecture là tập hợp nguyên tắc bảo vệ nghiệp vụ khỏi chi tiết kỹ thuật dễ thay đổi. Nó không phải một template bắt buộc, không đồng nghĩa với DDD, CQRS, MediatR, microservices hoặc số lượng project cố định.

## 1. Mục tiêu và phạm vi

Kiến trúc được xem là đạt mục tiêu khi:

- business rule quan trọng có thể hiểu và kiểm thử mà không cần HTTP, database hoặc vendor SDK;
- dependency ở compile time hướng từ chi tiết kỹ thuật vào policy nghiệp vụ;
- mỗi use case có một nơi chịu trách nhiệm rõ ràng;
- transaction, consistency, authorization và failure behavior được thiết kế tường minh;
- thay đổi transport, persistence hoặc external provider không buộc phải viết lại business rule;
- hệ thống đủ đơn giản để team hiện tại vận hành, không thêm abstraction chỉ để khớp sơ đồ.

Tài liệu dùng cấu trúc tham chiếu bốn project vì nó phù hợp với nhiều hệ thống nghiệp vụ vừa và lớn. Với CRUD nhỏ, có thể gộp project nhưng vẫn giữ đúng ranh giới bằng namespace, folder và review rule.

Các đoạn code là khung minh họa có chủ đích: tên miền, error/result type, mapping và registration phụ thuộc source thực tế. Khi áp dụng, cần hoàn thiện type liên quan và kiểm chứng bằng build/test; không xem từng snippet là một ứng dụng có thể copy nguyên khối.

## 2. Từ vựng thống nhất

| Thuật ngữ | Ý nghĩa trong tài liệu |
| --- | --- |
| Policy | Quy tắc hoặc quyết định nghiệp vụ cần được bảo vệ |
| Mechanism | Cách kỹ thuật dùng để thực hiện policy, như EF Core, HTTP hoặc message broker |
| Domain | Mô hình và quy tắc của lĩnh vực nghiệp vụ |
| Use case | Một năng lực ứng dụng cung cấp cho actor, như tạo đơn hàng hoặc duyệt yêu cầu |
| Port | Contract do phía gọi sở hữu để giao tiếp qua một ranh giới |
| Adapter | Implementation nối port với database, HTTP API, broker hoặc provider cụ thể |
| Aggregate | Nhóm domain object có một root và invariant được bảo vệ trong một transaction |
| Invariant | Điều kiện phải luôn đúng đối với trạng thái nghiệp vụ hợp lệ |
| Domain event | Sự kiện mô tả một sự thật đã xảy ra bên trong domain |
| Integration event | Contract dùng để thông báo qua ranh giới module/service |
| Composition root | Nơi chọn implementation và lắp ghép dependency, thường là `Program.cs` |

## 3. Nguyên tắc cốt lõi

### 3.1 Dependency Rule

Dependency ở compile time chỉ được hướng vào trong, về phía policy ổn định hơn:

```text
Drivers                                                    Driven adapters
HTTP, gRPC, CLI, consumer                                  DB, broker, email, vendor API
        │                                                           │
        ▼                                                           ▼
┌────────────────┐     ┌────────────────────┐     ┌────────────────────────┐
│ Presentation   │ ──► │ Application        │ ──► │ Domain                 │
│ Api / Worker   │     │ Use cases + ports  │     │ Rules + model          │
└───────┬────────┘     └──────────▲─────────┘     └────────────────────────┘
        │                         │
        │ composition root        │ implements ports
        ▼                         │
┌─────────────────────────────────┴──────────────────────────────────┐
│ Infrastructure: EF Core, HTTP clients, broker, cache, files       │
└────────────────────────────────────────────────────────────────────┘
```

Luồng gọi runtime có thể đi từ `Application` ra adapter `Infrastructure` thông qua interface. Dependency source code vẫn hướng vào trong vì interface thuộc layer gọi, còn implementation thuộc layer ngoài.

### 3.2 Separation of concerns

- Presentation sở hữu giao thức và public contract.
- Application sở hữu use case và orchestration.
- Domain sở hữu invariant và business rule cốt lõi.
- Infrastructure sở hữu persistence và tích hợp kỹ thuật.
- Host sở hữu configuration, DI, middleware và lifecycle.

Một class không nên vừa map HTTP, vừa kiểm tra quyền, vừa chạy SQL, vừa thay đổi domain state và gửi email.

### 3.3 Dependency inversion

Business code không phụ thuộc trực tiếp vào volatile detail. Nó phụ thuộc vào port nhỏ, có ngôn ngữ phù hợp với caller:

```csharp
public interface IExchangeRateProvider
{
    Task<ExchangeRate> GetRateAsync(
        Currency source,
        Currency destination,
        CancellationToken cancellationToken);
}
```

Port chỉ nên xuất hiện khi có ranh giới thật: I/O, provider dễ thay đổi, policy cần test độc lập hoặc nhiều implementation có giá trị. Không tạo interface cho entity, value object hoặc service thuần chỉ để “dễ mock”.

### 3.4 Explicit boundaries

Ranh giới tốt có:

- owner và trách nhiệm rõ ràng;
- contract nhỏ hơn implementation;
- dữ liệu đi qua được map chủ động;
- failure, timeout, authorization và transaction semantics được định nghĩa;
- test chứng minh hành vi tại ranh giới.

### 3.5 Framework là công cụ, không phải domain model

Attribute HTTP, `DbContext`, `IFormFile`, `ClaimsPrincipal`, broker message và SDK vendor không đi vào Domain. Application chỉ nhận dữ liệu và identity context tối thiểu cần cho use case.

## 4. Khi nào nên dùng mức kiến trúc nào?

### 4.1 Ứng dụng đơn giản

Dùng một `Api` project và một test project nếu hệ thống chủ yếu là CRUD, ít invariant, một datastore và team nhỏ. Tổ chức theo feature, giữ endpoint mỏng và không trả EF entity ra public API.

### 4.2 Clean Architecture tiêu chuẩn

Dùng các project `Domain`, `Application`, `Infrastructure`, `Api` khi có business rule đáng kể, workflow có trạng thái, nhiều integration, yêu cầu kiểm thử cao hoặc source dự kiến sống lâu.

### 4.3 Modular monolith

Ưu tiên modular monolith khi có nhiều business capability nhưng chưa có lý do độc lập deployment. Mỗi module sở hữu API nội bộ, domain và data của mình; module khác không truy cập thẳng table hoặc internal type.

### 4.4 Microservices

Chỉ tách service khi boundary cần độc lập về ownership, deployment, scale, data isolation, availability hoặc technology. Network failure, eventual consistency, contract versioning, observability và on-call là chi phí bắt buộc, không phải chi tiết triển khai sau này.

## 5. Cấu trúc solution tham chiếu

Thay `Company.Product` bằng tên tổ chức và bounded context thực tế:

```text
Company.Product/
├── global.json
├── Directory.Build.props
├── Directory.Packages.props
├── .editorconfig
├── Company.Product.slnx
├── src/
│   ├── Company.Product.Domain/
│   ├── Company.Product.Application/
│   ├── Company.Product.Infrastructure/
│   ├── Company.Product.Api/
│   └── Company.Product.Worker/          # Chỉ thêm khi cần host riêng
└── tests/
    ├── Company.Product.Domain.Tests/
    ├── Company.Product.Application.Tests/
    ├── Company.Product.IntegrationTests/
    └── Company.Product.ArchitectureTests/
```

Project reference chuẩn:

```text
Domain          → không tham chiếu project production khác
Application     → Domain
Infrastructure  → Application, Domain nếu implementation cần domain contract
Api             → Application, Infrastructure
Worker          → Application, Infrastructure
Tests           → đúng project cần test
```

Không thêm project `Application` nếu hệ thống chưa có orchestration đủ lớn. Project boundary phải bảo vệ dependency rule hoặc deployment boundary thật; nếu không, namespace/folder là đủ.

### Tổ chức bên trong theo feature

Ưu tiên nhóm theo business capability:

```text
Company.Product.Application/
├── Abstractions/
│   ├── Data/
│   ├── Messaging/
│   └── Security/
├── Orders/
│   ├── CreateOrder/
│   │   ├── CreateOrderCommand.cs
│   │   ├── CreateOrderHandler.cs
│   │   ├── CreateOrderValidator.cs
│   │   └── CreateOrderResult.cs
│   ├── GetOrder/
│   └── CancelOrder/
└── DependencyInjection.cs
```

Tránh các folder toàn cục như `Managers`, `Helpers`, `Common` hoặc một `Services` chứa hàng trăm class không có ownership.

## 6. Domain layer

### 6.1 Trách nhiệm

Domain chứa:

- entity và aggregate root;
- value object;
- business invariant và state transition;
- domain service thuần;
- domain error;
- domain event;
- repository contract cho aggregate khi domain/application cần abstraction đó.

Domain không chứa:

- controller, endpoint, HTTP status hoặc DTO transport;
- EF Core mapping, migration hoặc SQL;
- message broker, email, cache hoặc vendor SDK;
- đọc environment/configuration;
- logging kỹ thuật cho từng method.

### 6.2 Entity và aggregate

Entity có identity và vòng đời. Aggregate root là entry point duy nhất để thay đổi graph thuộc aggregate. Setter của state quan trọng phải được giới hạn; hành vi nghiệp vụ diễn đạt bằng method có tên rõ nghĩa.

```csharp
public sealed class Order
{
    private readonly List<OrderLine> _lines = [];

    private Order(OrderId id, CustomerId customerId, DateTimeOffset createdAt)
    {
        Id = id;
        CustomerId = customerId;
        CreatedAt = createdAt;
        Status = OrderStatus.Draft;
    }

    public OrderId Id { get; }
    public CustomerId CustomerId { get; }
    public OrderStatus Status { get; private set; }
    public DateTimeOffset CreatedAt { get; }
    public IReadOnlyCollection<OrderLine> Lines => _lines;

    public static Order Create(
        OrderId id,
        CustomerId customerId,
        DateTimeOffset createdAt) => new(id, customerId, createdAt);

    public DomainResult AddLine(ProductId productId, int quantity, Money unitPrice)
    {
        if (Status != OrderStatus.Draft)
            return DomainResult.Failure(OrderErrors.NotEditable);

        if (quantity <= 0)
            return DomainResult.Failure(OrderErrors.InvalidQuantity);

        _lines.Add(new OrderLine(productId, quantity, unitPrice));
        return DomainResult.Success();
    }

    public DomainResult Submit()
    {
        if (Status != OrderStatus.Draft)
            return DomainResult.Failure(OrderErrors.InvalidState);

        if (_lines.Count == 0)
            return DomainResult.Failure(OrderErrors.EmptyOrder);

        Status = OrderStatus.Submitted;
        return DomainResult.Success();
    }
}
```

Đừng load graph khổng lồ chỉ vì object có liên quan. Aggregate khác nên được tham chiếu bằng identity. Aggregate boundary thường là transaction boundary; nếu hai object không cần nhất quán tức thời, cân nhắc event và eventual consistency.

### 6.3 Value Object

Value Object không có identity riêng; equality dựa trên giá trị. Dùng nó khi primitive dễ bị dùng sai hoặc có invariant riêng.

```csharp
public readonly record struct Money(decimal Amount, Currency Currency)
{
    public Money Add(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException("Currencies must match.");

        return new Money(Amount + other.Amount, Currency);
    }
}
```

Các ứng viên thường gặp: `Money`, `EmailAddress`, `DateRange`, `TenantId`, `OrderId`. Không bọc mọi `string`/`Guid`; chỉ tạo type khi nó bổ sung meaning, validation hoặc compile-time safety.

### 6.4 Invariant và validation

Phân biệt ba loại kiểm tra:

| Loại | Ví dụ | Nơi đặt |
| --- | --- | --- |
| Transport/input validation | JSON thiếu field, page size quá lớn | Endpoint/filter/validator ở boundary |
| Use-case rule | Actor không được duyệt chính yêu cầu của mình | Application |
| Domain invariant | Order đã hủy không thể submit | Aggregate/domain service |

Client validation chỉ hỗ trợ trải nghiệm; server vẫn phải kiểm tra. Database constraint cần bảo vệ invariant chịu race condition như uniqueness hoặc foreign key.

### 6.5 Domain service

Dùng domain service khi rule thuộc domain nhưng không tự nhiên thuộc một entity/value object. Domain service phải thuần: nhận domain value, trả domain value/result, không I/O.

### 6.6 Error model

Dùng explicit outcome cho failure nghiệp vụ dự kiến; dùng exception cho lỗi bất thường hoặc programmer error. Không dùng một `Result<T>` toàn năng để che database timeout, bug và cancellation.

```csharp
public sealed record DomainError(string Code, string Description);

public readonly record struct DomainResult(bool IsSuccess, DomainError? Error)
{
    public static DomainResult Success() => new(true, null);
    public static DomainResult Failure(DomainError error) => new(false, error);
}
```

Không đưa HTTP status vào `DomainError`. Presentation chịu trách nhiệm map error code sang protocol response.

### 6.7 Thời gian, ID và randomness

- Dùng `DateTimeOffset` hoặc UTC instant nhất quán cho thời điểm.
- Inject `TimeProvider` vào use case/domain service khi thời gian ảnh hưởng hành vi.
- Chuyển timezone tại boundary, không dùng local time làm sự thật lưu trữ.
- Inject generator khi ID/randomness cần deterministic test hoặc có semantic riêng.
- Dùng cryptographic randomness cho token/secret.

## 7. Application layer

### 7.1 Trách nhiệm

Application hiện thực use case:

- kiểm tra application-level authorization và precondition;
- điều phối aggregate, repository và external port;
- xác định transaction boundary;
- map input use-case thành domain operation;
- trả outcome độc lập với HTTP;
- phát integration intent sau khi đã thiết kế tính bền vững.

Handler không nên chứa công thức hoặc state transition thuộc domain. Ngược lại, entity không nên tự gọi database, gửi email hoặc publish broker message.

### 7.2 Command và Query

Command thay đổi state; query đọc state. Tách command/query giúp rõ intent nhưng không bắt buộc hai database, event sourcing hoặc mediator.

```csharp
public sealed record CreateOrderCommand(
    CustomerId CustomerId,
    IReadOnlyList<CreateOrderLine> Lines,
    ActorContext Actor);

public sealed record CreateOrderResult(OrderId OrderId);
```

Query nên project đúng response cần thiết, không hydrate aggregate chỉ để đọc. Có thể dùng EF Core projection trực tiếp hoặc Dapper khi có bằng chứng nó phù hợp hơn.

### 7.3 Có cần MediatR không?

Không bắt buộc. Inject trực tiếp use-case service/handler là lựa chọn đơn giản và rõ ràng. Dùng mediator khi:

- có nhiều cross-cutting pipeline behavior nhất quán;
- team đã có convention và giá trị observability/validation/transaction rõ ràng;
- decoupling in-process thực sự cải thiện module boundary.

Không dùng mediator chỉ để thay một lời gọi method bằng `Send`. Business contract không nên phụ thuộc package mediator nếu không cần.

### 7.4 Port

Port do caller sở hữu và có contract tối thiểu:

```csharp
public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(OrderId id, CancellationToken cancellationToken);
    void Add(Order order);
}

public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken);
}
```

Repository nên tập trung vào aggregate hoặc query policy có ý nghĩa. Tránh `IGenericRepository<TEntity>` với `GetAll`, `Find`, `Update`, `Delete` cho mọi entity; nó thường làm mất semantics của EF Core, query shape, transaction và aggregate.

Nếu Application chấp nhận phụ thuộc EF Core cho một hệ thống đơn giản, có thể inject một application-owned data context abstraction hoặc dùng `DbContext` trong cohesive handler. Clean Architecture bảo vệ policy quan trọng, không yêu cầu bọc mọi framework bằng interface.

### 7.5 Một use case hoàn chỉnh

```csharp
internal sealed class CreateOrderHandler
{
    private readonly ICustomerReader _customers;
    private readonly IOrderRepository _orders;
    private readonly IUnitOfWork _unitOfWork;
    private readonly TimeProvider _timeProvider;

    public CreateOrderHandler(
        ICustomerReader customers,
        IOrderRepository orders,
        IUnitOfWork unitOfWork,
        TimeProvider timeProvider)
    {
        _customers = customers;
        _orders = orders;
        _unitOfWork = unitOfWork;
        _timeProvider = timeProvider;
    }

    public async Task<ApplicationResult<CreateOrderResult>> HandleAsync(
        CreateOrderCommand command,
        CancellationToken cancellationToken)
    {
        if (!command.Actor.CanCreateOrderFor(command.CustomerId))
            return ApplicationResult<CreateOrderResult>.Forbidden();

        if (!await _customers.ExistsAsync(command.CustomerId, cancellationToken))
            return ApplicationResult<CreateOrderResult>.NotFound("customer.not_found");

        var order = Order.Create(
            OrderId.New(),
            command.CustomerId,
            _timeProvider.GetUtcNow());

        foreach (var line in command.Lines)
        {
            var addResult = order.AddLine(line.ProductId, line.Quantity, line.UnitPrice);
            if (!addResult.IsSuccess)
                return ApplicationResult<CreateOrderResult>.Invalid(addResult.Error!);
        }

        var submitResult = order.Submit();
        if (!submitResult.IsSuccess)
            return ApplicationResult<CreateOrderResult>.Invalid(submitResult.Error!);

        _orders.Add(order);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return ApplicationResult<CreateOrderResult>.Success(new(order.Id));
    }
}
```

Điểm cần giữ: authorization trước khi đọc/ghi dữ liệu nhạy cảm, cancellation được truyền hết I/O, aggregate bảo vệ invariant, commit thuộc use case và không có HTTP concern.

### 7.6 Cross-cutting behavior

Validation, logging, tracing, authorization, transaction và idempotency có thể được thực hiện bằng decorator, filter, pipeline behavior hoặc middleware tùy boundary. Thứ tự phải rõ và được test. Không log cùng một exception ở mọi layer; thường chỉ log một lần tại handling boundary.

## 8. Infrastructure layer

Infrastructure triển khai port và chứa volatile detail:

- EF Core, SQL, migrations và repositories;
- typed/named `HttpClient`;
- message broker, outbox/inbox;
- file/object storage;
- email/SMS provider;
- cache;
- clock/ID provider nếu cần adapter;
- authentication provider integration.

Infrastructure được phép phụ thuộc Application/Domain. Application/Domain không được tham chiếu ngược Infrastructure.

### 8.1 EF Core và `DbContext`

- Đăng ký `DbContext` scoped cho request/unit of work.
- Không chia sẻ một context giữa nhiều thread.
- Background job tạo scope hoặc dùng `IDbContextFactory<TContext>` cho từng unit of work.
- Không nhúng secret/connection string trong `OnConfiguring`.
- Mapping persistence ở Infrastructure, tránh làm domain model phụ thuộc data annotation của ORM.

```csharp
internal sealed class AppDbContext(
    DbContextOptions<AppDbContext> options)
    : DbContext(options), IUnitOfWork
{
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
        => modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
}
```

### 8.2 Query

Thiết kế từ dữ liệu response cần dùng:

```csharp
var result = await dbContext.Orders
    .AsNoTracking()
    .Where(x => x.CustomerId == customerId)
    .OrderByDescending(x => x.CreatedAt)
    .ThenByDescending(x => x.Id)
    .Select(x => new OrderSummary(x.Id, x.Status, x.CreatedAt))
    .Take(pageSize)
    .ToListAsync(cancellationToken);
```

Luôn có ordering xác định trước pagination. Giới hạn page size. Kiểm tra generated SQL, execution plan và index bằng data thực tế. Tránh N+1, lazy loading không kiểm soát và load graph lớn chỉ để map DTO.

### 8.3 Transaction

Một `SaveChanges` trên relational provider được transaction hóa theo mặc định. Dùng explicit transaction khi nhiều lần save hoặc nhiều operation tương thích cần atomic. Transaction phải ngắn; không giữ database transaction trong lúc gọi HTTP API chậm.

Application check rồi insert không đủ chống race. Dùng unique/check constraint, optimistic concurrency token hoặc atomic conditional update theo invariant.

Khi concurrency conflict xảy ra, chọn rõ chiến lược:

- reject với conflict;
- reload và yêu cầu caller thử lại;
- merge theo business rule;
- retry toàn transaction nếu operation an toàn và số lần retry có giới hạn.

### 8.4 Migration

Review migration như production code. Kiểm tra data loss, default/backfill, lock, index build và rollback/roll-forward. Với rolling deployment, dùng expand-and-contract:

1. Thêm schema tương thích ngược.
2. Deploy code đọc/ghi được cả shape cũ và mới nếu cần.
3. Backfill theo batch có quan sát.
4. Chuyển read path và xác minh.
5. Xóa shape cũ ở release sau.

Không để mọi replica tự tranh chạy migration khi startup production. Dùng controlled migrator/job trong deployment pipeline.

### 8.5 Outbound HTTP

Dùng `IHttpClientFactory` với typed/named client. Định nghĩa base address, authentication, serialization, total timeout budget và telemetry theo external system. Retry chỉ transient failure và chỉ khi operation idempotent hoặc có deduplication. Giới hạn retry, thêm jitter và tránh retry chồng nhiều layer.

## 9. Presentation và ASP.NET Core host

### 9.1 Trách nhiệm endpoint

Endpoint/controller sở hữu:

- route, binding, header, status code và public DTO;
- authentication context và endpoint authorization;
- map request thành application command/query;
- map application outcome thành response/Problem Details.

Endpoint không sở hữu SQL, transaction, pricing formula hoặc domain state transition.

### 9.2 Minimal APIs hay Controllers?

| Chọn | Khi phù hợp |
| --- | --- |
| Minimal APIs | API nhỏ/vừa, route group rõ, cần low ceremony và typed results |
| Controllers | Cần `[ApiController]`, filters, formatters, conventions hoặc codebase đã chuẩn hóa MVC |

Không trộn cả hai trong cùng feature nếu không có lý do. Cả hai đều có thể tuân thủ Clean Architecture.

### 9.3 Public contract

Request/response DTO tách khỏi persistence entity và domain object. Chủ động định nghĩa JSON name, nullability, enum, precision, timestamp và pagination. Thay đổi serialized contract là thay đổi tương thích, không chỉ là refactor nội bộ.

```csharp
public sealed record CreateOrderRequest(
    Guid CustomerId,
    IReadOnlyList<CreateOrderLineRequest> Lines);

public sealed record CreateOrderResponse(Guid OrderId);
```

Không tin identity, tenant, owner, price hoặc role do client gửi. Lấy trusted context từ token/host/server-side mapping và authoritative data.

### 9.4 HTTP semantics và Problem Details

Map outcome nhất quán:

| Tình huống | HTTP status thường dùng |
| --- | --- |
| Thành công có representation | `200 OK` |
| Tạo resource có địa chỉ | `201 Created` + `Location` |
| Thành công không cần body | `204 No Content` |
| Binding/validation lỗi | `400 Bad Request` |
| Chưa xác thực | `401 Unauthorized` |
| Không có quyền | `403 Forbidden` |
| Không tìm thấy | `404 Not Found` |
| Conflict/concurrency/idempotency | `409 Conflict` |
| Precondition lỗi | `412 Precondition Failed` |
| Quá giới hạn | `429 Too Many Requests` |
| Lỗi ngoài dự kiến | `500 Internal Server Error` |

Error response dùng Problem Details khi phù hợp, có machine-readable code ổn định, safe detail, field errors và trace identifier. Không trả stack trace, SQL, hostname hoặc raw provider exception.

### 9.5 Endpoint mẫu

```csharp
public static class CreateOrderEndpoint
{
    public static IEndpointRouteBuilder MapCreateOrder(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost("/orders", HandleAsync)
            .RequireAuthorization("orders:create")
            .Produces<CreateOrderResponse>(StatusCodes.Status201Created)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status403Forbidden)
            .ProducesProblem(StatusCodes.Status409Conflict);

        return endpoints;
    }

    private static async Task<IResult> HandleAsync(
        CreateOrderRequest request,
        ICurrentActor currentActor,
        CreateOrderHandler handler,
        CancellationToken cancellationToken)
    {
        var command = request.ToCommand(currentActor.Context);
        var result = await handler.HandleAsync(command, cancellationToken);

        return result.Match<IResult>(
            value => TypedResults.Created(
                $"/orders/{value.OrderId.Value}",
                new CreateOrderResponse(value.OrderId.Value)),
            failure => failure.ToProblem());
    }
}
```

### 9.6 Composition root

`Program.cs` phải đọc được như bản mô tả host. Đưa registration theo module vào extension method, nhưng không che giấu thứ tự middleware quan trọng.

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddApplication()
    .AddInfrastructure(builder.Configuration);

builder.Services.AddProblemDetails();
builder.Services.AddAuthentication().AddJwtBearer();
builder.Services.AddAuthorization();
builder.Services.AddHealthChecks();

var app = builder.Build();

app.UseExceptionHandler();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapOrderEndpoints();
app.MapHealthChecks("/health/live");

app.Run();

public partial class Program;
```

Thứ tự cụ thể còn tùy proxy, CORS, rate limiting và routing, nhưng `UseAuthentication()` phải đứng trước `UseAuthorization()`. Forwarded headers phải được xử lý đúng trước logic phụ thuộc scheme/host/client IP và chỉ tin proxy đã cấu hình.

### 9.7 DI lifetime

| Lifetime | Dùng cho | Cảnh báo |
| --- | --- | --- |
| Singleton | Service thread-safe, process-wide | Không capture scoped dependency hoặc request state |
| Scoped | `DbContext`, unit of work, request context | Background worker phải tự tạo scope |
| Transient | Service stateless nhẹ | Tránh tạo object đắt tiền vô hạn |

Không gọi `BuildServiceProvider()` lần hai khi registration. Không dùng service locator để che dependency. Constructor quá nhiều dependency thường báo hiệu class thiếu cohesion.

### 9.8 Configuration và secrets

Bind configuration thành options có type, validate ở startup và fail fast nếu thiếu cấu hình bắt buộc:

```csharp
services.AddOptions<PaymentOptions>()
    .BindConfiguration(PaymentOptions.SectionName)
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

Dùng Secret Manager cho development và secret store/workload identity được phê duyệt cho production. Không commit token, private key, production connection string hoặc dữ liệu khách hàng thật.

## 10. Luồng end-to-end chuẩn

```text
1. HTTP request
   ↓ binding, authentication, endpoint authorization, input validation
2. Endpoint
   ↓ map public DTO + trusted actor/tenant → command/query
3. Application use case
   ↓ authorization theo resource, load state, orchestration
4. Domain
   ↓ kiểm tra invariant, thay state, ghi nhận domain event
5. Infrastructure
   ↓ persist aggregate + outbox trong local transaction
6. Application outcome
   ↓ success / invalid / not-found / forbidden / conflict
7. Endpoint
   ↓ map outcome → HTTP response hoặc Problem Details
8. Outbox dispatcher (nếu có)
   ↓ publish integration event; consumer xử lý idempotent
```

Mỗi bước chỉ làm trách nhiệm của boundary đó. Trace/correlation phải cho phép theo dõi toàn bộ luồng mà không log dữ liệu nhạy cảm.

## 11. Domain event, integration event và Outbox

### 11.1 Phân biệt event

- Domain event diễn đạt sự thật trong domain, ví dụ `OrderSubmitted`.
- Integration event là public contract cho module/service khác; payload ổn định và version được quản lý.
- Không serialize nguyên EF entity hoặc domain object graph thành integration event.

Domain event không mặc nhiên phải bất đồng bộ. Handler in-process cũng cần cẩn thận về transaction và failure semantics.

### 11.2 Khi nào cần Transactional Outbox?

Dùng Outbox khi database state và message gửi ra ngoài không được phép lệch nhau:

```text
Local transaction:
  business changes + outbox record
                 ↓ commit
Outbox dispatcher:
  read unpublished → publish → mark published
```

Outbox không tạo exactly-once end-to-end. Consumer phải giả định at-least-once và idempotent. Với side effect quan trọng, dùng inbox/deduplication record hoặc idempotency key có unique constraint.

Outbox production cần:

- stable message ID, type/version, occurred time, correlation/causation và tenant context an toàn;
- bounded batch, lease/locking và graceful shutdown;
- retry classification, backoff, dead-letter/quarantine;
- cleanup/retention;
- metric về outbox age/count, attempts, failure và duplicate;
- contract evolution và replay procedure.

### 11.3 Saga/process manager

Dùng saga cho workflow dài qua nhiều transaction/service, có timeout, retry và compensation. Compensation là nghiệp vụ bù trừ, không phải rollback kỹ thuật. Persist state của workflow trước khi gửi command tiếp theo và hiển thị trạng thái `Pending` trung thực cho caller.

## 12. Background jobs và consumers

- Không dùng fire-and-forget từ HTTP cho công việc phải hoàn tất.
- Persist durable work hoặc enqueue trước khi trả success.
- `BackgroundService` tạo scope cho từng message/job hoặc bounded batch.
- Tôn trọng cancellation và shutdown budget.
- Giới hạn concurrency, prefetch, batch size và memory.
- Handler phải idempotent; xác định poison-message/dead-letter behavior.
- Không đánh dấu hoàn tất trước khi durable effect commit.
- In-memory timer không đủ cho business-critical once-only execution trên nhiều replica.

## 13. Authentication, authorization và multi-tenancy

Authentication trả lời “caller là ai”; authorization trả lời “caller được làm gì với resource này”.

- Dùng framework-supported handler/library; validate signature, issuer, audience, lifetime và algorithm.
- Deny by default; bảo vệ mọi HTTP, message, job và admin entry point.
- Ưu tiên policy/resource-based authorization; role string không thay thế ownership/state/tenant check.
- Không tiết lộ resource existence qua khác biệt 403/404 nếu threat model yêu cầu che giấu.
- CORS không phải authorization. Cookie-based browser flow phải xử lý CSRF, secure cookie và data-protection key.

Với multi-tenancy:

- resolve tenant từ trusted source và từ chối input mâu thuẫn;
- propagate tenant vào query/write, cache key, idempotency key, message, object path, audit và rate limit;
- shared-table phải có tenant key trong constraint/index liên quan;
- global query filter chỉ là defense in depth, không thay explicit enforcement;
- test ít nhất hai tenant và các đường đọc/ghi/cache/job chéo tenant;
- không giữ tenant context trong static mutable state.

## 14. Reliability, performance và caching

### 14.1 Async và cancellation

- Giữ I/O async end-to-end; không dùng `.Result`, `.Wait()` hoặc `Task.Run` để che blocking I/O.
- Truyền `CancellationToken` đến database, HTTP, broker và stream.
- Không biến requested cancellation thành lỗi 500.
- Chỉ dùng `Task.WhenAll` khi operation độc lập và concurrency đã giới hạn.

### 14.2 Timeout, retry và backpressure

- Có end-to-end deadline rồi chia timeout budget cho dependency.
- Retry transient failure, có giới hạn và jitter; operation phải idempotent/deduplicated.
- Không retry validation, authorization, deterministic not-found hoặc permanent failure.
- Không nhân retry ở proxy, SDK, HTTP client và application cùng lúc.
- Mọi queue, cache, batch, payload và fan-out phải có giới hạn.
- Khi quá tải, chọn rõ: đợi trong deadline, reject, shed, persist hoặc degrade an toàn.

### 14.3 Cache

Trước khi thêm cache, định nghĩa:

- source of truth và owner;
- key bao gồm tenant/user/authorization variation cần thiết;
- TTL, size limit, eviction và invalidation;
- freshness/consistency chấp nhận được;
- hành vi khi miss hoặc cache outage;
- stampede protection và metric hit/miss/latency.

Không cache authorization decision hoặc dữ liệu nhạy cảm nếu chưa có revocation và scope đúng. Cache không sửa query/schema kém; đo bottleneck trước.

### 14.4 Đo trước khi tối ưu

Định nghĩa workload, p50/p95/p99, throughput, error/timeout, CPU/memory/connection và cost budget. Ưu tiên giảm round trip, query thừa và payload trước micro-optimization như pooling, `Span<T>`, `ValueTask` hoặc compiled query.

## 15. Observability và vận hành

Dùng ba tín hiệu bổ trợ:

- `ILogger` cho structured event;
- `ActivitySource`/distributed traces cho request và dependency flow;
- `Meter` cho rate, duration, error, queue depth và saturation.

Propagate W3C trace context qua HTTP/message. Log một exception tại handling boundary. Không log password, token, cookie, authorization header, private key, connection string hoặc raw sensitive payload.

Metric quan trọng thường gồm:

- request rate, duration, error, active requests;
- dependency latency/error/retry/circuit state;
- database connection/command/lock signal;
- queue depth, age, processing duration, duplicate và dead letter;
- business outcome như order submitted/payment failed;
- outbox lag và workflow stuck age.

Phân biệt health check:

- liveness: process có cần restart hay không; rẻ và không phụ thuộc mọi downstream;
- readiness: instance có an toàn để nhận traffic hay không.

Health response public chỉ trả thông tin tối thiểu. Alert dựa trên user-visible symptom hoặc saturation và phải có owner/runbook.

## 16. Chiến lược kiểm thử

Không có một loại test chứng minh toàn bộ hệ thống:

| Loại test | Chứng minh tốt | Không chứng minh được |
| --- | --- | --- |
| Domain unit | Invariant, calculation, state transition | SQL, serialization, DI |
| Application/component | Orchestration và port interaction | Provider/database semantics thật |
| Integration | ASP.NET pipeline, EF provider, auth, broker | Toàn journey ngoài process |
| Contract | HTTP/message compatibility | Business behavior nội bộ đầy đủ |
| End-to-end | Critical journey qua nhiều boundary | Mọi edge case với chi phí thấp |
| Architecture | Dependency/naming/module rule | Runtime correctness |
| Load/resilience/security | Rủi ro phi chức năng cụ thể | Functional coverage tổng quát |

### 16.1 Quy tắc test

- Test behavior và observable outcome, không khóa implementation detail vô ích.
- Inject time, ID và randomness cho deterministic test.
- Dùng database/provider thật cho query translation, constraint, transaction, collation và concurrency.
- Không mock sâu `DbSet`, EF query internals, HTTP stack hoặc broker protocol.
- ASP.NET integration test dùng `WebApplicationFactory<Program>` để chạy routing, binding, middleware, auth và Problem Details.
- Test duplicate/out-of-order/crash quanh commit/ack đối với messaging.
- Test unauthorized, forbidden, not-found, conflict, cancellation và unexpected failure.
- Coverage là tín hiệu tìm nhánh rủi ro chưa test, không phải mục tiêu tự thân.

### 16.2 Architecture tests

Compiler/project reference đã bảo vệ nhiều rule. Chỉ thêm architecture test cho rule chưa được compiler bảo vệ, ví dụ:

- Domain không tham chiếu ASP.NET Core, EF Core hoặc Infrastructure;
- module khác không dùng internal implementation;
- endpoint không tham chiếu `DbContext` trực tiếp theo convention của hệ thống;
- handler và validator tuân thủ namespace/visibility đã thống nhất.

Rule phải ít, có giá trị và có assertion đúng target assembly.

## 17. CI/CD và production readiness

Baseline pipeline cho source mới:

```text
restore
→ build Release + analyzers + nullable
→ unit tests
→ integration/contract/migration tests
→ dependency vulnerability/policy checks
→ publish/container build
→ startup smoke test
→ deploy có guardrail
```

Giữ local command và CI tương đồng:

```powershell
dotnet restore
dotnet build --configuration Release --no-restore
dotnet test --configuration Release --no-build
dotnet publish src/Company.Product.Api --configuration Release --no-build
```

Production checklist:

- runtime còn support và dependency đã patch;
- artifact build một lần rồi promote qua môi trường;
- configuration validate và secrets được provision an toàn;
- migration được review, backup/recovery và controlled rollout;
- authorization, tenant isolation và negative tests đạt;
- timeout, retry, rate, queue, cache, batch, payload đều bounded;
- liveness/readiness và graceful shutdown đúng;
- dashboard, alert, audit và ownership có sẵn;
- có rollback hoặc roll-forward thực tế.

## 18. Quy trình triển khai một source mới

### Bước 1: Xác định system forces

Viết ngắn gọn business capabilities, invariant, actor, integrations, data ownership, traffic, availability, compliance, team ownership và deployment constraints. Chưa chọn pattern/package ở bước này.

### Bước 2: Chọn deployment shape tối giản

Chọn single deployable hoặc modular monolith trước. Chỉ chọn microservices khi có bằng chứng cho independent boundary.

### Bước 3: Xác định module và use case

Đặt tên theo ngôn ngữ nghiệp vụ. Liệt kê command/query, actor, input, outcome, authorization, transaction và side effect. Tránh bắt đầu từ bảng database.

### Bước 4: Model rule quan trọng

Chọn transaction script cho CRUD thẳng; chọn entity/value object/aggregate khi có invariant và state transition thật. Viết domain unit test cho rule rủi ro cao.

### Bước 5: Định nghĩa application boundary

Tạo command/query và handler/use-case service. Chỉ thêm port tại I/O boundary hoặc dependency cần đảo. Quy định result/error taxonomy độc lập HTTP.

### Bước 6: Thêm adapter

Triển khai persistence, external HTTP hoặc broker. Thiết kế schema, constraint, index, timeout và retry cùng use case. Không chỉ làm happy path.

### Bước 7: Thêm transport

Tạo API contract, binding/validation, auth policy và outcome mapping. Sinh OpenAPI/contract test. Không expose domain/persistence model.

### Bước 8: Lắp composition root

Đăng ký module, options, lifetimes, middleware, health checks và observability. Validate configuration ở startup.

### Bước 9: Hoàn thiện reliability

Thiết kế concurrency, idempotency, Outbox/inbox, background execution, graceful shutdown và recovery theo failure mode thực tế.

### Bước 10: Chốt quality gates

Chạy build Release, unit/integration/architecture tests, migration validation và startup smoke test. Ghi lại ADR cho quyết định system-wide như module boundary, tenancy, deployment shape hoặc integration style.

## 19. Definition of Done cho một vertical slice

- [ ] Use case có actor, input, output và business outcome rõ ràng.
- [ ] Trusted identity/tenant không lấy trực tiếp từ payload không tin cậy.
- [ ] Input validation, application rule và domain invariant đặt đúng boundary.
- [ ] Domain state chỉ thay đổi qua hành vi hợp lệ.
- [ ] Transaction boundary và concurrency behavior được xác định.
- [ ] Cancellation truyền qua mọi I/O.
- [ ] External call có timeout và retry/idempotency phù hợp.
- [ ] Public DTO tách khỏi entity; HTTP/error semantics nhất quán.
- [ ] Log/trace/metric đủ chẩn đoán và không lộ dữ liệu nhạy cảm.
- [ ] Unit test rule quan trọng; integration test boundary mà fake không chứng minh được.
- [ ] Migration/index/constraint được review khi có thay đổi data.
- [ ] Không thêm abstraction/package không giải quyết nhu cầu cụ thể.

## 20. Anti-pattern thường gặp

| Anti-pattern | Hậu quả | Hướng sửa |
| --- | --- | --- |
| Controller gọi `DbContext` và chứa business rule | HTTP, persistence và policy dính nhau | Di chuyển use case/orchestration ra Application; invariant vào Domain |
| Anemic domain cho workflow phức tạp | Rule phân tán trong handler/service | Đưa state transition về aggregate/value object |
| Rich domain cho CRUD thuần | Ceremony không có giá trị | Dùng transaction script/feature handler đơn giản |
| Generic repository bọc EF Core | Mất query/transaction semantics | Dùng EF trực tiếp hoặc repository theo aggregate/use case |
| Interface cho mọi class | Indirection và mock-heavy tests | Chỉ tạo port tại boundary có variation/I/O thật |
| MediatR như mục tiêu kiến trúc | Thêm layer gọi mà không thêm policy | Inject handler trực tiếp hoặc nêu rõ pipeline value |
| Domain event dùng như integration contract | Coupling internal model ra ngoài | Map sang integration event versioned |
| Gửi message/email trước commit | Dual-write inconsistency | Commit durable intent; dùng Outbox khi cần |
| Check-then-insert không có constraint | Race condition | Unique constraint/atomic update/concurrency control |
| Fire-and-forget trong HTTP | Mất việc khi process restart | Durable queue/job hoặc Outbox |
| Retry mọi exception | Duplicate side effect, retry storm | Classify transient + idempotency + bounded retry |
| Trả exception raw cho client | Rò rỉ nội bộ/secret | Central Problem Details mapping |
| Cache không scope tenant/identity | Rò rỉ dữ liệu | Thiết kế key, authorization variation và negative tests |
| Auto-migrate ở mọi replica | Race/lock khi deploy | Controlled migrator trong pipeline |
| Chia microservices quá sớm | Distributed complexity không cần thiết | Modular monolith với module/data ownership |

## 21. Quy tắc ra quyết định nhanh

Trước khi thêm một layer, project, interface, package hoặc pattern, trả lời:

1. Boundary hoặc rủi ro cụ thể nào được bảo vệ?
2. Ai sở hữu contract?
3. Failure và transaction semantics là gì?
4. Test nào chứng minh quyết định hoạt động?
5. Cách đơn giản hơn có đáp ứng yêu cầu không?
6. Điều kiện nào khiến quyết định này cần được xem lại?

Nếu không trả lời được, chưa nên thêm abstraction.

## 22. Tài liệu chính thức tham khảo

- [.NET architectural principles](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/architectural-principles)
- [Common web application architectures](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [ASP.NET Core fundamentals](https://learn.microsoft.com/aspnet/core/fundamentals/)
- [ASP.NET Core APIs](https://learn.microsoft.com/aspnet/core/web-api/)
- [ASP.NET Core error handling](https://learn.microsoft.com/aspnet/core/fundamentals/error-handling-api)
- [ASP.NET Core security](https://learn.microsoft.com/aspnet/core/security/)
- [EF Core transactions](https://learn.microsoft.com/ef/core/saving/transactions)
- [EF Core efficient querying](https://learn.microsoft.com/ef/core/performance/efficient-querying)
- [.NET observability with OpenTelemetry](https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel)
- [.NET testing](https://learn.microsoft.com/dotnet/core/testing/)
- [.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core)

Tài liệu này cố ý không khóa vào package hoặc framework version cụ thể. Khi khởi tạo source, chọn .NET release còn được support và kiểm tra API theo target framework thực tế; preview chỉ dùng khi có yêu cầu và chấp nhận rủi ro rõ ràng.
