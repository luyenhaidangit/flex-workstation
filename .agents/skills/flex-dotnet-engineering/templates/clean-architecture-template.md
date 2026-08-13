---
title: Clean Architecture service template
description: Bootstrap và quy ước bắt buộc cho ASP.NET Core service theo Clean Architecture.
---

# Clean Architecture Service Template

Template này là chuẩn bắt buộc cho service ASP.NET Core mới trong hệ sinh thái Flex. Mục tiêu là giữ `Program.cs` ngắn, dễ đọc và chỉ đóng vai trò composition root; chi tiết cấu hình phải nằm trong extension hoặc project sở hữu concern đó. Serilog concrete configuration thuộc `Api`, không thuộc `Infrastructure`.

Code scaffold dùng trực tiếp nằm tại [`clean-architecture-service/`](clean-architecture-service/). Thay các placeholder `{Company}`, `{Service}`, `{company}` và `{service}` trước khi sử dụng. File này tập trung vào nguyên tắc, giải thích và checklist review; không dùng thay cho scaffold code.

## 1. Bootstrap `Program.cs` bắt buộc

Service API **PHẢI** dùng top-level statements với lifecycle bootstrap theo mẫu dưới đây. Không đặt đăng ký controller, middleware, Serilog sink hoặc business logic trực tiếp trong `Program.cs`.

```csharp
using {Company}.{Service}.Api.Extensions;
using {Company}.{Service}.Api.Logging;
using Serilog;

var builder = WebApplication.CreateBuilder(args);
var configuration = builder.Configuration;

builder.AddAppConfigurations();

SeriLogger.Configure(builder);
Log.Information("Start {ApplicationName} up", builder.Environment.ApplicationName);

try
{
    builder.Services.AddConfigurationSettings(configuration);
    builder.Services.AddInfrastructure(configuration);

    var app = builder.Build();
    app.UseInfrastructure();

    app.Run();
}
catch (Exception ex)
{
    var type = ex.GetType().Name;
    if (type.Equals("StopTheHostException", StringComparison.Ordinal))
    {
        throw;
    }

    Log.Fatal(ex, "Unhandled exception: {Message}", ex.Message);
}
finally
{
    Log.Information("Shutdown {ApplicationName} complete", builder.Environment.ApplicationName);
    Log.CloseAndFlush();
}

// Bắt buộc khi test API dùng WebApplicationFactory<Program>.
public partial class Program;
```

Các quy tắc không được bỏ qua:

- `SeriLogger.Configure(builder)` phải chạy trước khi ghi startup log.
- Startup/shutdown phải dùng structured logging; không nội suy chuỗi bằng `$"..."`.
- `Log.Fatal` phải ghi exception trước khi process kết thúc.
- `Log.CloseAndFlush()` phải luôn chạy trong `finally`.
- `public partial class Program;` phải tồn tại khi solution có API integration test dùng `WebApplicationFactory<Program>`.

## 2. Extension bắt buộc

### `HostExtensions`

`HostExtensions` dùng namespace block-scoped theo format service Flex. `AddAppConfigurations` chịu trách nhiệm nạp `appsettings.json`, `appsettings.{Environment}.json` và environment variables. Không đọc file cấu hình trực tiếp trong `Program.cs`.

Format bắt buộc khi tạo project mới:

```csharp
namespace {Company}.{Service}.Api.Extensions
{
    public static class HostExtensions
    {
        public static void AddAppConfigurations(this WebApplicationBuilder builder)
        {
            var env = builder.Environment;

            // Adds application configurations from JSON files and environment variables.
            builder.Configuration
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true, reloadOnChange: true)
                .AddJsonFile("serilog.json", optional: false, reloadOnChange: true)
                .AddJsonFile($"serilog.{env.EnvironmentName}.json", optional: true, reloadOnChange: true)
                .AddEnvironmentVariables();
        }
    }
}
```

Namespace thực tế phải thay `{Company}.{Service}` bằng định danh service, ví dụ `Flex.Exchange.Api.Extensions`.

### `ServiceExtensions`

Phải có hai entry point rõ ràng:

```csharp
IServiceCollection AddConfigurationSettings(this IServiceCollection services, IConfiguration configuration);

IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration);
```

`AddInfrastructure` đăng ký controllers, options, OpenAPI, exception handling, Infrastructure services và application services. Không đăng ký Domain policy ở API controller.

### `SwaggerConfiguration`

Mỗi API phải cấu hình Swagger trong extension riêng tại `Api/OpenApi`, tương tự convention của `flex-auth-service`. Cấu hình tối thiểu gồm document metadata, chuẩn hóa route về lowercase nhưng giữ nguyên dynamic route parameter, và nạp XML comments khi file tồn tại:

```csharp
using System.Reflection;
using Microsoft.OpenApi.Models;

namespace {Company}.{Service}.Api.OpenApi;

public static class SwaggerConfiguration
{
    public static void ConfigureSwagger(this IServiceCollection services)
    {
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "{Company}.{Service}",
                Version = "v1"
            });

            c.DocumentFilter<LowerCaseDocumentFilter>();

            var entryAssembly = Assembly.GetEntryAssembly();
            if (entryAssembly == null)
            {
                return;
            }

            var xmlFile = $"{entryAssembly.GetName().Name}.xml";
            var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);

            if (File.Exists(xmlPath))
            {
                c.IncludeXmlComments(xmlPath, includeControllerXmlComments: true);
            }
        });

    }
}
```

API project bật XML documentation để Swagger có thể đọc comment controller/action:

```xml
<GenerateDocumentationFile>true</GenerateDocumentationFile>
<NoWarn>$(NoWarn);1591</NoWarn>
```

`LowerCaseDocumentFilter` chỉ chuẩn hóa segment route; không đổi nội dung hoặc tên parameter trong `{...}`.

Implementation mẫu:

```csharp
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Text.RegularExpressions;

namespace {Company}.{Service}.Api.OpenApi;

public sealed class LowerCaseDocumentFilter : IDocumentFilter
{
    public void Apply(OpenApiDocument swaggerDoc, DocumentFilterContext context)
    {
        var paths = swaggerDoc.Paths.ToDictionary(
            path => PreserveDynamicParameters(path.Key),
            path => path.Value);

        swaggerDoc.Paths = new OpenApiPaths();
        foreach (var path in paths)
        {
            swaggerDoc.Paths.Add(path.Key, path.Value);
        }
    }

    private static string PreserveDynamicParameters(string path)
    {
        var regex = new Regex(@"\{[^/}]+}");

        return regex.Replace(path, match => match.Value)
            .Split('/')
            .Select(segment => regex.IsMatch(segment) ? segment : segment.ToLowerInvariant())
            .Aggregate((current, next) => $"{current}/{next}");
    }
}
```

### `ApplicationExtensions`

`UseInfrastructure` cấu hình pipeline theo thứ tự phù hợp:

1. Exception handling.
2. Correlation ID.
3. Request/response logging.
4. Swagger trong Development.
5. Authentication/Authorization nếu service có bảo mật.
6. Endpoint mapping.

### `SeriLogger`

`SeriLogger.Configure` phải nằm ở `Api.Logging`, vì `Api` là composition root và sở hữu cấu hình host/vendor. Đây là nơi duy nhất tạo `Log.Logger`. Sink và endpoint phải được điều khiển qua các file configuration/provider; không hardcode trạng thái bật/tắt trong `Program.cs`:

```csharp
public static void Configure(WebApplicationBuilder builder)
{
    Log.Logger = new LoggerConfiguration()
        .ReadFrom.Configuration(builder.Configuration)
        .Enrich.FromLogContext()
        .Enrich.With(new EcsLogEnricher())
        .Enrich.WithProperty("service.environment", builder.Environment.EnvironmentName.ToLowerInvariant())
        .Enrich.WithProperty("host.name", Environment.MachineName)
        .CreateLogger();

    builder.Host.UseSerilog();
}
```

Các cấu hình Serilog phải nằm riêng trong `serilog.json`; có thể override theo môi trường bằng `serilog.{Environment}.json`. `HostExtensions` phải nạp các file này trước environment variables:

```json
{
  "Serilog": {
    "Using": [
      "Serilog.Sinks.Console",
      "Serilog.Sinks.Async",
      "Serilog.Sinks.File",
      "Serilog.Sinks.Http"
    ],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft.AspNetCore": "Warning"
      }
    },
    "Enrich": ["FromLogContext"],
    "Properties": {
      "service.name": "exchange-service"
    },
    "WriteTo": [
      {
        "Name": "Async",
        "Args": {
          "bufferSize": 5000,
          "configure": [
            {
              "Name": "Console",
              "Args": {
                "outputTemplate": "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext}{NewLine}{Message:lj}{NewLine}{Exception}{NewLine}"
              }
            },
            {
              "Name": "File",
              "Args": {
                "path": "logs/log-.json",
                "rollingInterval": "Day",
                "fileSizeLimitBytes": 10000000,
                "rollOnFileSizeLimit": true,
                "retainedFileCountLimit": 7,
                "shared": true,
                "formatter": {
                  "type": "Serilog.Formatting.Json.JsonFormatter, Serilog",
                  "renderMessage": true
                }
              }
            }
          ]
        }
      },
      {
        "Name": "Async",
        "Args": {
          "bufferSize": 10000,
          "configure": [
            {
              "Name": "Http",
              "Args": {
                "requestUri": "http://logstash:5000",
                "queueLimitBytes": 10000000,
                "logEventsInBatchLimit": 100,
                "period": "00:00:05",
                "textFormatter": {
                  "type": "Serilog.Formatting.Json.JsonFormatter, Serilog",
                  "renderMessage": true
                }
              }
            }
          ]
        }
      }
    ]
  }
}
```

Pipeline logging chuẩn kế thừa từ `flex-auth-service` gồm hai queue độc lập:

- `Async(bufferSize: 5000)` cho Console và File.
- `Async(bufferSize: 10000)` cho Logstash HTTP.

File phải giữ JSON formatter, rolling theo ngày, giới hạn 10 MB, `rollOnFileSizeLimit`, tối đa 7 file và `shared: true`. `JsonFormatter` có thể truyền `renderMessage: true` bằng object configuration với `type` và tham số constructor. Logstash phải cấu hình `requestUri`, `queueLimitBytes`, `logEventsInBatchLimit`, `period` và `textFormatter` trong `WriteTo`. URI mẫu `http://logstash:5000` chỉ là placeholder; mỗi môi trường phải thay bằng endpoint thực tế qua file môi trường hoặc configuration provider, không commit credential/token.

Nếu cần bật/tắt sink theo môi trường, thay đổi danh sách `WriteTo` trong `serilog.{Environment}.json` hoặc provider cấu hình tương ứng; không đưa các `if` kiểm tra sink vào `Program.cs`. Package `Serilog.AspNetCore`, `Serilog.Sinks.Async`, `Serilog.Sinks.File` và `Serilog.Sinks.Http` phải được khai báo ở project `Api`.

### `.gitignore` baseline

Mỗi service mới phải bỏ qua các artifact build, IDE, runtime log và file cấu hình cục bộ. Baseline này kế thừa phần cần thiết từ `flex-auth-service`, không copy các rule đặc thù Oracle/Terraform nếu service không sử dụng:

```gitignore
# .NET build output
[Bb]in/
[Oo]bj/
artifacts/

# IDE
.vs/
.idea/
.vscode/*
!.vscode/settings.json
*.user
*.suo

# Runtime logs and generated log files
[Ll]og/
[Ll]ogs/
*.log

# Local configuration and secrets
.env
.env.*
**/secrets/*
!**/secrets/README.md

# Packages and local tooling
*.nupkg
*.snupkg
.codex/skills/
```

Không commit file log, token, password, connection string hoặc secret phát sinh trong quá trình chạy local. Nếu một thư mục `logs/` đã được tạo trong `Api`, phải thêm rule tương ứng vào `.gitignore` của repository service.

### ELK integration

Khi service gửi log qua `Serilog.Sinks.Http`, Logstash phải chuẩn hóa dữ liệu trước khi ghi vào Elasticsearch:

- `Timestamp` → `@timestamp` theo ISO 8601.
- `RenderedMessage` → `message` nếu `message` chưa tồn tại.
- `Level` → `log.level` và chuyển về lowercase.
- Các key dotted trong `Properties` phải được mở thành object ECS, ví dụ `service.name` → `[service][name]`.
- Metadata HTTP của Logstash nếu có `[http][method]` phải chuẩn hóa thành `[http][request][method]`.
- `EventId.Id` và `EventId.Name` lần lượt chuẩn hóa thành `event.id` và `event.action` khi field đích chưa tồn tại.

Kibana Discover nên giữ cùng thứ tự đọc cho các saved search: `@timestamp`, `service.name`, `message`, sau đó là `log.level` và các field chuyên biệt của view (`http.*`, `event.*`, `trace.*`, `error.*`). Chỉ thay đổi thứ tự cột, không tự ý thêm hoặc xóa field khỏi saved search nếu chưa có yêu cầu nghiệp vụ.

`url.path` và các field HTTP có thể mô tả request gửi tới Logstash thay vì request nghiệp vụ của service; cần xác nhận nguồn field trong pipeline trước khi dùng chúng làm chỉ số API.

Các ECS field constants và custom enricher đặt cùng logging concern:

```text
Api/Logging/
├── LogFields.cs
├── EcsLogEnricher.cs
└── SeriLogger.cs
```

Application chỉ được phụ thuộc `Microsoft.Extensions.Logging.Abstractions` khi cần ghi business log; Domain và Infrastructure không được phụ thuộc Serilog hoặc ASP.NET Core logging vendor.

## 3. Response Envelope bắt buộc

Mọi HTTP response từ controller (thành công lẫn lỗi) **PHẢI** bọc trong `Result` — không trả entity/DTO trần hoặc `ProblemDetails` mặc định của ASP.NET Core. Quy ước kế thừa từ `flex-auth-service`.

`Result` sống ở `Infrastructure/Responses` (không phụ thuộc HTTP/ASP.NET Core, chỉ dùng `System.Text.Json`):

```csharp
namespace {Company}.{Service}.Infrastructure.Responses;

public class Result
{
    public bool IsSuccess { get; set; }
    public string? ErrorCode { get; set; }
    public string? Message { get; set; }
    public object? Data { get; set; }
    public object? Errors { get; set; }

    public static Result Success(object? data = default, string? message = null, string? errorCode = null);
    public static Result Failure(object? errors = default, string? message = null, string? errorCode = null);
}
```

Scaffold đầy đủ (`Result.cs.template`, `ResponseCode.cs.template`, `ErrorInfo.cs.template`) nằm tại `clean-architecture-service/src/{Company}.{Service}.Infrastructure/Responses/`.

Quy tắc dùng trong controller:

- Response thành công: `return Ok(Result.Success(data));` — không trả `Ok(data)` trần.
- Response lỗi có body đính kèm ngay tại action (`Conflict(session)`, `CreatedAtAction(..., session)`): phải tự bọc `Result.Failure(...)`/`Result.Success(...)` thủ công, vì middleware không sửa được response đã ghi body.
- Response lỗi không có body (`NotFound()`, `Forbid()`, `Conflict()` không tham số): `ExceptionEnvelopeMiddleware` tự động bọc thành `Result.Failure` sau khi pipeline chạy xong, không cần controller tự làm.

`ExceptionEnvelopeMiddleware` (`Api/ExceptionHandling`) thay thế `IExceptionHandler`/`AddProblemDetails` mặc định của ASP.NET Core — bắt exception chưa xử lý và tự viết `Result.Failure` cho các status code lỗi (401/403/404/409/422/429/5xx) chưa có body. Đăng ký bằng `app.UseMiddleware<ExceptionEnvelopeMiddleware>()` trong `ApplicationExtensions.UseInfrastructure`, đặt ở vị trí "Exception handling" (bước 1 trong pipeline, xem mục `ApplicationExtensions` bên trên).

Frontend (Angular) khi tiêu thụ service theo Envelope này: KHÔNG unwrap `.data` ngầm trong service layer. Trả về nguyên `Observable<ApiResponse<T>>` từ service, để component tự kiểm `response?.isSuccess` và đọc `response.data`/`response.message` tại nơi subscribe — đúng pattern đã dùng ở `flex-auth-service`'s `login.component.ts`.

## 4. Quy tắc Clean Architecture

```text
Api → Application → Domain
  ↘ Infrastructure → Domain
```

- `Domain`: entity, value object, invariant, domain service, domain event; không phụ thuộc HTTP, Serilog, EF Core, broker hoặc framework adapter.
- `Application`: use case, command/result, orchestration, transaction/concurrency boundary và port tới Infrastructure.
- `Infrastructure`: configuration binding, persistence, messaging, external adapters và dependency injection; không sở hữu cấu hình Serilog concrete của host.
- `Api`: request/response DTO, controller, middleware, composition root và public HTTP contract.

Mọi dependency phải hướng vào trong. Không để controller gọi trực tiếp `DbContext`, matching engine hoặc vendor SDK.

## 5. Kiểm thử và `Program`

- Domain behavior phải có unit test ở mức rẻ nhất.
- API contract phải có integration test qua `WebApplicationFactory<Program>` khi service có HTTP surface.
- `public partial class Program;` là một phần của testability contract, không phải business code.
- Nếu service không có API integration test, có thể bỏ khai báo này nhưng phải ghi rõ lý do trong plan/review; không tự ý bỏ khỏi service đang có `WebApplicationFactory<Program>`.

## 6. Checklist review

- [ ] `Program.cs` chỉ chứa bootstrap/lifecycle theo mẫu.
- [ ] Controller trả `Result.Success(data)`/`Result.Failure(...)`, không trả entity/DTO trần hoặc `ProblemDetails` mặc định.
- [ ] `ExceptionEnvelopeMiddleware` đăng ký qua `app.UseMiddleware<ExceptionEnvelopeMiddleware>()`, không dùng `app.UseExceptionHandler()`/`AddProblemDetails()`.
- [ ] FE (nếu có) không unwrap `.data` trong service layer; component tự kiểm `isSuccess` khi subscribe.
- [ ] Có `AddAppConfigurations`, `AddConfigurationSettings`, `AddInfrastructure`, `UseInfrastructure`.
- [ ] Có `SeriLogger.Configure` tại `Api.Logging`.
- [ ] `HostExtensions` nạp `serilog.json` và `serilog.{Environment}.json` trước environment variables.
- [ ] Console/File và Logstash dùng queue `Async` riêng khi service bật cả hai pipeline.
- [ ] File logging có rolling, giới hạn kích thước, retention và formatter JSON.
- [ ] Logstash mapping chuẩn hóa `@timestamp`, `message`, `log.level` và ECS fields.
- [ ] Kibana saved search giữ `@timestamp`, `service.name`, `message` ở đầu danh sách cột.
- [ ] Có `LogFields` và custom enricher tại `Api.Logging` nếu service dùng ECS fields.
- [ ] Startup/shutdown/unhandled exception được log và flush đúng cách.
- [ ] Correlation ID xuất hiện trong structured log.
- [ ] Domain không tham chiếu ASP.NET Core hoặc Serilog.
- [ ] `public partial class Program;` tồn tại nếu có `WebApplicationFactory<Program>`.
- [ ] `dotnet build`, `dotnet test` và `git diff --check` đều đạt.
