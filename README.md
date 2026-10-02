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

## Run with containers

Build and start the API behind NGINX:

```powershell
docker compose up --build --detach
```

NGINX listens on `http://localhost:8081` by default. Set `NGINX_HOST_PORT` to
publish a different host port.

```powershell
$env:NGINX_HOST_PORT = "8082"
docker compose up --build --detach
```

Inspect the running services and follow their logs:

```powershell
docker compose ps
docker compose logs --follow
docker stats --no-stream
```

Both containers use `restart: unless-stopped`. Docker restarts them after an
unexpected exit, but leaves them stopped after an explicit stop. The API is
limited to 0.50 CPU, 256 MB of memory, and 100 PIDs. NGINX is limited to 0.25
CPU, 64 MB of memory, and 50 PIDs. The API memory limit is an initial measured
local-runtime limit, not a permanent production capacity guarantee; check
`docker stats` under representative load before selecting a production limit.

Container logs use Docker's `json-file` driver with three files of up to 10 MB
per container. Stop and remove the local containers and network when finished:

```powershell
docker compose down
```
