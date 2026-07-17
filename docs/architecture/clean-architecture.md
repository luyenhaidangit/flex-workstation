# Clean Architecture: hướng dẫn thực hành từ dự án Bookify

> Tài liệu này phân tích `C:\Workspace\Personal\flex-workstation\Pragmatic-Clean-Arquitecture-Course`, một ứng dụng đặt chỗ căn hộ tên `Bookify` viết bằng ASP.NET Core / .NET 9. Mục tiêu là giải thích các quyết định kiến trúc rút ra từ source, không phải sao chép nguyên xi mọi chi tiết triển khai của dự án mẫu.

## 1. Clean Architecture giải quyết điều gì?

Clean Architecture tổ chức hệ thống quanh **nghiệp vụ** thay vì quanh framework, database hay giao thức HTTP. Quy tắc cốt lõi là *Dependency Rule*:

> Mã ở vòng ngoài có thể phụ thuộc vào mã ở vòng trong; mã ở vòng trong không được biết chi tiết ở vòng ngoài.

Nhờ vậy, quy tắc đặt chỗ vẫn hoạt động và được kiểm thử khi thay PostgreSQL bằng database khác, thay REST bằng message consumer, hoặc thay Keycloak bằng nhà cung cấp định danh khác. Đây không phải mục tiêu để làm mọi ứng dụng “trừu tượng hơn”; nó có giá trị khi nghiệp vụ đủ quan trọng, thay đổi thường xuyên, hoặc hạ tầng có khả năng thay thế.

### Bốn vùng trách nhiệm trong Bookify

```text
HTTP / ASP.NET Core / Swagger / Middleware / DI composition root
                         │
                         ▼
                       Api
                         │ tham chiếu
                         ▼
                   Application ──────────────► Domain
                         ▲                       ▲
                         │ triển khai interface  │ định nghĩa model và contract nghiệp vụ
                         │                       │
                  Infrastructure ──────────────┘
      EF Core, PostgreSQL, Dapper, Keycloak, Quartz, email, Outbox
```

Quan hệ project thực tế là:

| Project | Được phép tham chiếu | Vai trò |
| --- | --- | --- |
| `Bookify.Domain` | Không có project nội bộ nào | Mô hình và quy tắc nghiệp vụ thuần |
| `Bookify.Application` | `Bookify.Domain` | Use case, orchestration, contract cho hạ tầng |
| `Bookify.Infrastructure` | `Bookify.Application` (và gián tiếp `Domain`) | Chi tiết kỹ thuật, triển khai interface |
| `Bookify.Api` | `Bookify.Application`, `Bookify.Infrastructure` | HTTP adapter và composition root |

`Api` được phép biết cả `Application` lẫn `Infrastructure` vì nó là điểm lắp ghép của ứng dụng. Điều đó không có nghĩa controller được dùng trực tiếp `ApplicationDbContext`: controller trong mẫu chỉ gửi request qua `ISender`.

## 2. Cấu trúc source và ranh giới layer

```text
src/
├── Bookify.Api/
│   ├── Controllers/               # REST controllers và minimal endpoints
│   ├── Middleware/                # Chuyển exception thành HTTP response
│   ├── Extensions/                # Swagger, migration, seed data
│   └── Program.cs                 # Composition root
├── Bookify.Application/
│   ├── Abstractions/              # Ports: clock, SQL, email, authentication, messaging
│   ├── Apartments/ Bookings/ Users/ # Mỗi use case gồm command/query, handler, DTO, validator
│   ├── Exceptions/
│   └── DependencyInjection.cs
├── Bookify.Domain/
│   ├── Abstractions/              # Entity, Result, Error, domain-event, Unit of Work
│   ├── Apartments/ Bookings/ Users/ Reviews/
│   └── Shared/ValueObjects/
└── Bookify.Infrastructure/
    ├── Configurations/            # EF Core mappings
    ├── Repositories/              # Repository implementations
    ├── Authentication/ Email/ Clock/ Data/
    ├── Outbox/
    ├── Migrations/
    └── ApplicationDbContext.cs
```

Đây là cách chia theo layer ở cấp project và chia theo feature ở bên trong `Application`/`Domain`. Ví dụ use case đặt chỗ nằm gọn trong `Application/Bookings/ReserveBooking`; không có thư mục `Services` chung trở thành nơi chứa mọi logic.

## 3. Domain: nơi giữ sự thật nghiệp vụ

`Bookify.Domain` chứa những khái niệm mà người làm nghiệp vụ nhận ra: `Apartment`, `Booking`, `User`, `Review`, `Money`, `DateRange`, trạng thái booking và các lỗi miền. Layer này không chứa `DbContext`, SQL, `HttpContext`, controller, configuration hay package của ASP.NET Core.

### Entity, identity và Value Object

- Entity có danh tính riêng và vòng đời: `Booking : Entity<BookingId>`, `Apartment : Entity<ApartmentId>`, `User : Entity<UserId>`.
- Identity là type riêng thay vì truyền `Guid` khắp nơi. Điều này ngăn nhầm `BookingId` với `UserId` ngay từ compile time.
- Value Object biểu diễn giá trị có ý nghĩa: `Money`, `Currency`, `DateRange`, `Address`, `Email`, `Name`. Chúng nên bất biến hoặc giới hạn setter để invariant không bị phá vỡ từ bên ngoài.
- Enum như `BookingStatus` phù hợp khi tập giá trị đóng; nếu hành vi trạng thái lớn dần, có thể cân nhắc state object, nhưng không cần làm sớm.

Trong `Booking`, các setter là `private`, nên trạng thái chỉ thay đổi qua hành vi `Confirm`, `Reject`, `Complete`, `Cancel`. Ví dụ `Cancel` kiểm tra booking đã được xác nhận và ngày hiện tại chưa vượt quá ngày bắt đầu trước khi thay đổi trạng thái. Đây là điểm quan trọng: controller hay handler không được tự gán `booking.Status = ...`.

### Aggregate và transaction boundary

Trong phạm vi mẫu, `Booking` là aggregate trung tâm cho vòng đời đặt chỗ. `Booking.Reserve(...)` tạo booking, tính giá, cập nhật `Apartment.LastBookedOnUtc` và phát `BookingReserverdDomainEvent`. `ReserveBookingCommandHandler` phối hợp nhiều aggregate/repository rồi gọi một lần `IUnitOfWork.SaveChangesAsync`.

Khi thiết kế aggregate, cần trả lời:

1. Invariant nào phải luôn đúng trong một transaction?
2. Object nào được phép thay đổi trực tiếp cùng lúc?
3. Thao tác nào có thể chấp nhận eventual consistency qua domain event?

Đừng coi mọi entity liên quan là một aggregate lớn: aggregate quá lớn làm contention cao và khó mở rộng. Ngược lại, tách quá nhỏ có thể làm invariant quan trọng chỉ còn là quy ước trong handler.

### Domain service

`PricingService.CalculatePrice(Apartment, DateRange)` tính giá theo số ngày, phí vệ sinh và phụ phí tiện ích. Nó được đặt ở `Domain` vì công thức là quy tắc nghiệp vụ, không thuộc một entity tự nhiên nào và không cần I/O. Một domain service tốt:

- nhận và trả về khái niệm domain;
- không gọi database, HTTP hay gửi email;
- không biết request/response DTO;
- có thể unit test hoàn toàn không cần framework.

Không phải mọi class tên `Service` đều là domain service. Một class gọi repository và điều phối use case là application service/handler; class gửi email là infrastructure service.

### Result và lỗi nghiệp vụ

`Result`/`Result<T>` đóng gói thành công hoặc `Error`. Handler trả `BookingErrors.Overlap`, `UserErrors.NotFound` thay vì dùng exception cho điều kiện nghiệp vụ được dự liệu. API adapter sau đó chuyển failure thành `BadRequest`, `NotFound` hoặc response thích hợp.

Nguyên tắc hữu ích là:

- dùng `Result` cho nhánh nghiệp vụ bình thường mà caller phải xử lý;
- dùng exception cho lỗi kỹ thuật hoặc vi phạm không thể tiếp tục (lỗi persistence, bug, timeout);
- chuẩn hóa cách map `Error` sang HTTP ở một chỗ để các endpoint không tự diễn giải khác nhau.

## 4. Application: hiện thực từng use case

`Application` định nghĩa application boundary: các actor có thể làm gì với hệ thống. Nó biết domain và các interface cần thiết, nhưng không biết interface đó được triển khai bằng EF Core, Dapper, SMTP hay Keycloak.

### CQRS theo use case, không phải theo database

Mẫu dùng MediatR với các abstraction:

```csharp
ICommand<TResponse> : IRequest<Result<TResponse>>
IQuery<TResponse>   : IRequest<Result<TResponse>>
ICommandHandler<TCommand, TResponse>
IQueryHandler<TQuery, TResponse>
```

Command thay đổi trạng thái, ví dụ `ReserveBookingCommand`. Query chỉ đọc và trả DTO như `BookingResponse`. Việc tách này cho phép dùng đường đọc tối ưu mà không cần hydrate aggregate: `GetBookingQueryHandler` dùng `ISqlConnectionFactory` + Dapper để chạy SQL và ánh xạ thẳng vào response.

CQRS ở đây không đồng nghĩa với hai database hay event sourcing. Đây là sự tách biệt trách nhiệm đọc/ghi ở mức code. Chỉ dùng hai datastore khi lợi ích thực sự lớn hơn chi phí đồng bộ và vận hành.

### Luồng `ReserveBooking` từ HTTP đến database

```text
POST /api/bookings
  → endpoint/controller chuyển request DTO thành ReserveBookingCommand
  → ISender.Send(command)
  → LoggingBehavior → ValidationBehavior → ReserveBookingCommandHandler
  → lấy User và Apartment qua domain repository interface
  → kiểm tra DateRange và booking chồng lấn
  → Booking.Reserve(...): tính giá, áp invariant, thêm domain event
  → IBookingRepository.Add(booking)
  → IUnitOfWork.SaveChangesAsync()
  → EF Core ghi aggregate và Outbox message trong cùng transaction
  → Result<Guid> → API map thành 201 Created hoặc lỗi HTTP
```

Handler là orchestration, không phải nơi để giấu quy tắc cốt lõi. Trong mẫu, handler xác thực sự tồn tại user/apartment, kiểm tra overlap qua repository, gọi factory method của aggregate rồi commit. Quy tắc chuyển trạng thái và cách tính giá vẫn nằm trong `Domain`.

### Ports: dependency inversion trong thực tế

Các interface ở `Application/Abstractions` là ports do code bên trong sở hữu:

| Port | Adapter ở Infrastructure | Lý do |
| --- | --- | --- |
| `IDateTimeProvider` | `DateTimeProvider` | Test được thời gian, tránh gọi `DateTime.UtcNow` rải rác |
| `ISqlConnectionFactory` | `SqlConnectionFactory` | Query handler không phụ thuộc Npgsql cụ thể |
| `IEmailService` | `EmailService` | Use case/event handler không biết SMTP hay provider |
| `IAuthenticationService`, `IJwtService` | adapter Keycloak/JWT | Nhà cung cấp identity là chi tiết thay thế được |
| Repository interfaces và `IUnitOfWork` | EF Core repositories, `ApplicationDbContext` | Domain/use case không phụ thuộc ORM |

Không cần tạo interface cho mọi class. Port chỉ có ích tại ranh giới I/O, khi cần test fake, hoặc khi implementation có khả năng thay đổi. Với một domain service thuần như `PricingService`, interface là thừa.

### Pipeline behaviors

`DependencyInjection.AddApplication()` đăng ký MediatR, validators và hai open behavior:

1. `LoggingBehavior` ghi log trước, sau và khi command lỗi.
2. `ValidationBehavior` chạy FluentValidation trước handler; nếu lỗi thì ném `ValidationException`.

Đây là cross-cutting concern: validation request, logging, authorization, caching hoặc transaction policy có thể áp dụng nhất quán mà không lặp trong từng handler. Thứ tự đăng ký là hành vi hệ thống, cần được xem xét và test. Trong source có chú thích “Order matters”; ví dụ validation trước logging có thể tránh log request không hợp lệ, còn logging trước validation giúp truy vết mọi attempt.

## 5. Infrastructure: chi tiết thay thế được

`Infrastructure` là nơi framework và dịch vụ bên ngoài được phép xuất hiện: EF Core, Npgsql/PostgreSQL, Dapper, Quartz, Keycloak, JWT, HTTP client và email. Nó phụ thuộc vào abstraction bên trong để triển khai chúng, không đảo chiều dependency.

### Persistence: EF Core cho write, Dapper cho read

`ApplicationDbContext` là `DbContext` đồng thời triển khai `IUnitOfWork`. Repository EF Core như `BookingRepository` triển khai `IBookingRepository`; cấu hình mapping được tách vào `Configurations/*Configuration.cs` thay vì gắn attribute persistence vào entity domain.

Chiến lược kết hợp trong mẫu:

- **Write model / aggregate**: EF Core tracking và repositories giữ được hành vi domain, transaction và mapping nhất quán.
- **Read model**: Dapper SQL trong query handler, chỉ lấy cột cần thiết vào DTO, tránh tải cả graph entity.

Đây là pragmatic CQRS, không bắt buộc. Nếu query đơn giản, EF Core projection `Select` có thể đủ; nếu write model đơn giản, một ORM duy nhất thường dễ bảo trì hơn.

### Composition root và Dependency Injection

`Program.cs` là nơi duy nhất lắp ghép application:

```csharp
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
```

`AddApplication` đăng ký use-case infrastructure (MediatR, validators, domain services). `AddInfrastructure` đọc configuration và đăng ký concrete adapter: `DbContext`, Dapper connection factory, repositories, authentication, Quartz worker. Các class bên trong không dùng service locator; dependency được đưa qua constructor.

Một quy tắc thực hành: chỉ `Api`/worker host nên tham chiếu cả `Application` và `Infrastructure`. Test có thể tham chiếu layer cần test, nhưng code production ở `Application` không được tham chiếu ngược `Infrastructure`.

### Authentication và external service

Infrastructure cấu hình JWT bearer, options và `HttpClient` để gọi Keycloak. Controller chỉ nhận identity đã được middleware xác thực (`ClaimsPrincipal`) và tạo command; handler làm việc qua `IAuthenticationService` hoặc `IJwtService` khi cần. Secrets, connection string và token không được hard-code vào source hay tài liệu; dùng secret store/configuration theo môi trường.

## 6. Domain events và Transactional Outbox

Khi một booking được reserve, aggregate gọi `RaiseDomainEvent`. `ApplicationDbContext.SaveChangesAsync` lấy domain events từ entities đang track, chuyển chúng thành `OutboxMessage`, rồi ghi entity và outbox trong cùng database transaction.

```text
Aggregate thay đổi + RaiseDomainEvent
              │
              ▼
SaveChangesAsync
  ├─ serialize event thành outbox_messages
  └─ commit dữ liệu nghiệp vụ và outbox cùng transaction
              │
              ▼
Quartz ProcessOutboxMessagesJob
  ├─ đọc message chưa xử lý, khóa các row đã chọn
  ├─ deserialize và IPublisher.Publish(event)
  └─ đánh dấu processed_on_utc hoặc lưu error
```

Vấn đề Outbox giải quyết là dual write: nếu vừa commit booking vừa gửi email/message trực tiếp, một bước có thể thành công còn bước kia thất bại. Với outbox, trạng thái cần phát đi được lưu bền cùng transaction; worker sẽ thử xử lý sau.

Các yêu cầu production vẫn cần bổ sung quanh cơ chế này:

- Consumer/event handler phải idempotent vì delivery thường là *at-least-once*.
- Cần retry policy, backoff, dead-letter/alert và retention/cleanup cho message lỗi.
- Batch và locking cần phù hợp khi có nhiều worker/instance.
- Payload event cần versioning; tránh serialize type metadata không đáng tin cậy từ nguồn bên ngoài.
- Quan sát được độ trễ outbox, số message lỗi và tuổi message cũ nhất.

`BookingReservedDomainEventHandler` trong mẫu gửi email sau khi Quartz publish event. Đây là ví dụ rõ việc side effect được tách khỏi transaction request.

## 7. API là adapter mỏng

`BookingsController`, `UsersController` và `BookingsEndpoints` làm bốn việc: nhận HTTP DTO, lấy claim/context cần thiết, tạo command/query, rồi map `Result` về HTTP. Chúng không chứa SQL, business rule hay gọi `DbContext`.

`ExceptionHandlingMiddleware` chuyển `ValidationException` thành `ProblemDetails` HTTP 400 và log exception. Đây là nơi phù hợp để chuẩn hóa lỗi kỹ thuật/input; mapping `Result.Error` nghiệp vụ cũng nên được tập trung hóa khi API lớn lên.

Giữ API DTO (`ReserveBookingRequest`) tách với command/domain model. Request HTTP có thể đổi tên JSON, thêm field trình bày hoặc có validation transport mà không làm đổi aggregate. Tương tự, query response là read DTO, không trả trực tiếp entity EF/domain qua wire.

## 8. Kiểm thử: bảo vệ cả hành vi lẫn ranh giới

Dự án có ba loại test project:

| Test | Đối tượng | Ví dụ |
| --- | --- | --- |
| `Bookify.Domain.UnitTests` | Quy tắc entity/value object/domain service | Hủy booking sai trạng thái phải trả lỗi |
| `Bookify.Application.UnitTests` | Handler với mock/fake ports | Không tìm thấy user thì `ReserveBooking` thất bại |
| `Bookify.ArchitectureTests` | Quy tắc dependency/structure | Domain không tham chiếu Application hay Infrastructure |

Architecture test bằng `NetArchTest.Rules` biến nguyên tắc thành hàng rào build. Khi thêm package hoặc reference mới, CI sẽ báo ngay nếu `Domain` bắt đầu phụ thuộc layer ngoài. Đó là lợi ích lớn hơn một sơ đồ kiến trúc chỉ tồn tại trong tài liệu.

Nên giữ thêm integration test cho các ranh giới dễ sai: EF mapping/migration, unique constraint chống overlap, authentication, Outbox và HTTP contract. Unit test không thể chứng minh SQL Dapper đúng với schema thật.

## 9. Những điểm cần cân nhắc khi kế thừa source mẫu

Source là tài liệu học tốt, nhưng cần review kỹ trước production:

- `DateRange.Create` đang ném `ApplicationException` khi `start > end`. Vì đây là input/domain validation được dự liệu, trả `Result<DateRange>` hoặc domain-specific exception nhất quán sẽ dễ map lỗi hơn.
- Controller/minimal endpoint dùng `Guid.Parse(userId!)`; claim thiếu hoặc không hợp lệ sẽ thành lỗi 500. Cần yêu cầu authorization, kiểm tra claim và trả 401/403 phù hợp.
- Endpoint đang map các lỗi nghiệp vụ về `BadRequest` khá thô. `NotFound`, overlap/conflict và validation nên có status/`ProblemDetails` chuẩn hóa riêng.
- `ProcessOutboxMessagesJob` lưu lỗi nhưng vẫn đánh dấu `processed_on_utc`; cần quyết định rõ retry/dead-letter thay vì vô tình bỏ qua message lỗi.
- Trong `LayerTests.cs`, test có tên kiểm tra Domain không phụ thuộc Infrastructure nhưng source hiện kiểm tra `ApplicationAssembly` lần nữa. Cần sửa assertion thành `InfrastructureAssembly` để hàng rào có hiệu lực.
- `IdentityModelEventSource.ShowPII = true` không nên bật ngoài môi trường phát triển vì có thể ghi thông tin nhạy cảm vào log.
- Chống booking overlap không chỉ dựa vào kiểm tra trước khi insert: mẫu đã bắt `ConcurrencyException`, nhưng production cần constraint/transaction isolation phù hợp tại database để chịu được request đồng thời.

Các điểm trên không phủ nhận kiến trúc; chúng minh họa rằng Clean Architecture bảo vệ hướng phụ thuộc, còn tính đúng đắn vận hành vẫn cần thiết kế persistence, security, observability và error contract.

## 10. Quy trình thêm một use case mới

Ví dụ thêm “hủy booking”:

1. **Domain**: bổ sung/chỉnh hành vi `Booking.Cancel(utcNow)` và `BookingCancelledDomainEvent` nếu có side effect nghiệp vụ. Đặt invariant ở đây.
2. **Application**: tạo `Bookings/CancelBooking/CancelBookingCommand`, validator và handler. Handler load aggregate qua `IBookingRepository`, gọi `Cancel`, rồi `IUnitOfWork.SaveChangesAsync`.
3. **Infrastructure**: chỉ thêm code khi port/adapter thực sự thiếu; EF repository hiện có có thể đã đủ. Không kéo `DbContext` vào handler.
4. **Api**: thêm endpoint request/route, lấy actor từ claim, gửi command và map result.
5. **Tests**: domain unit test các trạng thái hợp lệ/không hợp lệ; application unit test orchestration; integration test nếu có query/migration/authorization mới; architecture test vẫn xanh.

Tiêu chí thiết kế nhanh: nếu bỏ ASP.NET Core, PostgreSQL và Keycloak mà use case không còn diễn tả được quy tắc nghiệp vụ, code đó đang ở sai layer.

## 11. Khi nào nên và không nên dùng cách tổ chức này

Nên cân nhắc khi ứng dụng có domain đáng kể, nhiều use case, team cần làm việc song song, yêu cầu test cao, hoặc có tích hợp/persistence dễ thay đổi. Nó đặc biệt phù hợp với workflow có trạng thái, authorization phức tạp, tính tiền, inventory, booking hoặc nghiệp vụ tài chính.

Không cần khởi đầu với đầy đủ repository, CQRS, domain event và Outbox cho CRUD nhỏ, ít thay đổi, không có invariant đáng kể. Có thể bắt đầu bằng module/feature rõ ràng và tách domain logic khỏi controller; chỉ thêm abstraction khi có I/O boundary hoặc nhu cầu test/thay thế cụ thể. Clean Architecture tốt nhất là mức kỷ luật vừa đủ để bảo vệ nghiệp vụ, không phải số lượng project hoặc interface.

## 12. Checklist review

- [ ] Dependency chỉ hướng vào trong; `Domain` không biết framework/hạ tầng.
- [ ] Entity bảo vệ invariant qua method/factory, không có setter public cho state quan trọng.
- [ ] Command, query và API DTO được tách theo use case; handler không trở thành “god service”.
- [ ] Interface chỉ xuất hiện ở ranh giới đáng thay thế/test; concrete adapter được đăng ký ở composition root.
- [ ] Validation input, logging, exception mapping và authorization được đặt nhất quán ở boundary/pipeline.
- [ ] Write transaction, concurrency constraint và idempotency đã được thiết kế cùng nhau.
- [ ] Side effect bất đồng bộ có Outbox/retry/monitoring khi cần độ tin cậy.
- [ ] Unit, integration và architecture tests cùng bảo vệ hành vi và ranh giới.
- [ ] Secrets/PII không nằm trong source hoặc log production.

## Tham chiếu source đã phân tích

- `src/Bookify.Api/Program.cs`, `Controllers/Bookings/BookingsEndpoints.cs`, `Middleware/ExceptionHandlingMiddleware.cs`
- `src/Bookify.Application/DependencyInjection.cs`, `Abstractions/`, `Bookings/ReserveBooking/`, `Bookings/GetBooking/`
- `src/Bookify.Domain/Abstractions/`, `Bookings/Booking.cs`, `Bookings/PricingService.cs`, `Bookings/ValueObjects/DateRange.cs`
- `src/Bookify.Infrastructure/ApplicationDbContext.cs`, `DependencyInjection.cs`, `Outbox/ProcessOutboxMessagesJob.cs`, `Configurations/`, `Repositories/`
- `test/Bookify.ArchitectureTests/LayerTests.cs` cùng các unit-test project
