var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// BUILD_VERSION and FAIL_MODE come from configuration, so appsettings.json,
// environment variables (BUILD_VERSION=1.2.3) and command-line args all work.
string Version() => app.Configuration["BUILD_VERSION"] ?? "unknown";
bool FailMode() => app.Configuration.GetValue<bool>("FAIL_MODE");

app.MapGet("/api/items", () =>
    FailMode()
        ? Results.Problem("FAIL_MODE is enabled", statusCode: StatusCodes.Status500InternalServerError)
        : Results.Ok(new[]
        {
            new Item(1, "alpha"),
            new Item(2, "beta"),
            new Item(3, "gamma"),
        }));

// TODO: check real dependencies (database, cache, ...) here.
app.MapGet("/healthz", () => Results.Ok(new { status = "healthy", version = Version() }));

app.MapGet("/version", () => Results.Ok(new { version = Version() }));

app.Run();

public record Item(int Id, string Name);

// Exposed so WebApplicationFactory<Program> can reference the entry point.
public partial class Program;
