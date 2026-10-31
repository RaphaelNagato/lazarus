using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace Lazarus.Api.Tests;

public class ApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ApiTests(WebApplicationFactory<Program> factory) => _factory = factory;

    private HttpClient CreateClient(string? version = null, string? failMode = null) =>
        _factory.WithWebHostBuilder(b => b.ConfigureAppConfiguration((_, cfg) =>
        {
            var overrides = new Dictionary<string, string?>();
            if (version is not null) overrides["BUILD_VERSION"] = version;
            if (failMode is not null) overrides["FAIL_MODE"] = failMode;
            cfg.AddInMemoryCollection(overrides);
        })).CreateClient();

    private record Health(string Status, string Version);
    private record VersionInfo(string Version);
    private record ItemDto(int Id, string Name);

    [Fact]
    public async Task Healthz_ReturnsOkWithBuildVersion()
    {
        var client = CreateClient(version: "1.2.3");

        var response = await client.GetAsync("/healthz");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Health>();
        Assert.Equal("healthy", body!.Status);
        Assert.Equal("1.2.3", body.Version);
    }

    [Fact]
    public async Task Version_ReturnsConfiguredBuildVersion()
    {
        var client = CreateClient(version: "2024.10.31-abc123");

        var body = await client.GetFromJsonAsync<VersionInfo>("/version");

        Assert.Equal("2024.10.31-abc123", body!.Version);
    }

    [Fact]
    public async Task Items_ReturnsItems_WhenFailModeOff()
    {
        var client = CreateClient(failMode: "false");

        var items = await client.GetFromJsonAsync<List<ItemDto>>("/api/items");

        Assert.NotEmpty(items!);
    }

    [Fact]
    public async Task Items_Returns500_WhenFailModeOn()
    {
        var client = CreateClient(failMode: "true");

        var response = await client.GetAsync("/api/items");

        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
    }

    [Fact]
    public async Task Healthz_StaysHealthy_WhenFailModeOn()
    {
        var client = CreateClient(failMode: "true");

        var response = await client.GetAsync("/healthz");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
