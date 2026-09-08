using Microsoft.AspNetCore.Mvc;

namespace ServiceHub.Api.Controllers;

[ApiController]
[Route("api/status")]
public class StatusController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            service = "servicehub-api",
            status = "ok",
            timestamp = DateTimeOffset.UtcNow
        });
    }
}