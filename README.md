# CloudOps ServiceHub

CloudOps ServiceHub is a small ASP.NET Core API used as the application layer for a DevOps and cloud operations learning project.

## Prerequisites

- .NET SDK 10

## Build and test

From the repository root:

```powershell
dotnet restore
dotnet build
dotnet test
```

## Run locally

```powershell
dotnet run --project .\src\ServiceHub.Api\ServiceHub.Api.csproj --urls http://localhost:8080
```

In another terminal, verify the API:

```powershell
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/api/status
```

Available endpoints:

- `GET /health` returns the application health status.
- `GET /api/status` returns basic service status information as JSON.
