# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/ServiceHub.Api/ServiceHub.Api.csproj src/ServiceHub.Api/
RUN dotnet restore src/ServiceHub.Api/ServiceHub.Api.csproj

COPY src/ServiceHub.Api/ src/ServiceHub.Api/
RUN dotnet publish src/ServiceHub.Api/ServiceHub.Api.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

USER $APP_UID
EXPOSE 8080

ENTRYPOINT ["dotnet", "ServiceHub.Api.dll"]
