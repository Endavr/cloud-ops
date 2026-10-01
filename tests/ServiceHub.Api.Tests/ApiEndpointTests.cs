using System.Globalization;
using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace ServiceHub.Api.Tests;

public sealed class ApiEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ApiEndpointTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Health_ReturnsHealthyResponse()
    {
        using var client = _factory.CreateClient();

        using var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/plain", response.Content.Headers.ContentType?.MediaType);

        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal("Healthy", body);
    }

    [Fact]
    public async Task Status_ReturnsServiceStatusAsJson()
    {
        using var client = _factory.CreateClient();

        using var response = await client.GetAsync("/api/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);

        using var payload = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync());
        var root = payload.RootElement;

        Assert.Equal("servicehub-api", root.GetProperty("service").GetString());
        Assert.Equal("ok", root.GetProperty("status").GetString());

        var timestamp = root.GetProperty("timestamp").GetString();
        Assert.True(DateTimeOffset.TryParse(timestamp, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedTimestamp));
        Assert.Equal(TimeSpan.Zero, parsedTimestamp.Offset);
    }

    [Fact]
    public async Task UnknownRoute_ReturnsNotFound()
    {
        using var client = _factory.CreateClient();

        using var response = await client.GetAsync("/route-that-does-not-exist");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
