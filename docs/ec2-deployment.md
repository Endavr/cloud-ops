# EC2 container deployment contract

The EC2 runtime uses `deploy/compose.production.yaml` as a standalone Compose
file. It never builds application source on the host. The API image must already
exist in ECR and must be supplied through `SERVICEHUB_IMAGE` with a Git commit
SHA tag:

```text
<account-id>.dkr.ecr.<region>.amazonaws.com/<repository>:<40-character-git-sha>
```

Use the full commit SHA that produced the image. Do not deploy moving tags such
as `latest`. Compose exits with a clear error if `SERVICEHUB_IMAGE` is unset.

The commands below are a future manual runbook. Replace every placeholder before
use. The example account ID is intentionally invalid and is not a credential.

## Select an immutable image

```powershell
$env:AWS_REGION = "<aws-region>"
$env:ECR_REGISTRY = "000000000000.dkr.ecr.<aws-region>.amazonaws.com"
$env:ECR_REPOSITORY = "<ecr-repository>"
$env:IMAGE_TAG = "<40-character-git-commit-sha>"
$env:SERVICEHUB_IMAGE = "$env:ECR_REGISTRY/$env:ECR_REPOSITORY`:$env:IMAGE_TAG"
```

## Log in to ECR

Use the EC2 instance role or another approved AWS credential source. Do not put
credentials in this file, environment files, Compose configuration, or shell
history.

```powershell
aws ecr get-login-password --region $env:AWS_REGION |
  docker login --username AWS --password-stdin $env:ECR_REGISTRY
```

## Pull and start

```powershell
docker compose -f deploy/compose.production.yaml pull
docker compose -f deploy/compose.production.yaml up --detach --no-build
docker compose -f deploy/compose.production.yaml ps
```

Only NGINX is published on host port 80 by default. The API listens on port 8080
inside the Compose network and is not published on the EC2 host. Set
`NGINX_HOST_PORT` only when a different host port is intentionally required.

## Verify health

```powershell
curl.exe --fail --show-error http://127.0.0.1/health
curl.exe --fail --show-error http://127.0.0.1/api/status
docker compose -f deploy/compose.production.yaml ps
```

## Inspect logs

```powershell
docker compose -f deploy/compose.production.yaml logs --tail 200
docker compose -f deploy/compose.production.yaml logs --follow servicehub nginx
```

Both services retain the local runtime safeguards: `restart: unless-stopped`,
CPU, memory, and PID limits, and `json-file` rotation with three 10 MB files.
The API's 256 MB memory limit remains an initial measured limit rather than a
permanent production capacity guarantee.

## Roll back

Select the full Git commit SHA for the previous known-good image, pull it, and
recreate only the containers whose image changed:

```powershell
$env:IMAGE_TAG = "<previous-40-character-git-commit-sha>"
$env:SERVICEHUB_IMAGE = "$env:ECR_REGISTRY/$env:ECR_REPOSITORY`:$env:IMAGE_TAG"
docker compose -f deploy/compose.production.yaml pull
docker compose -f deploy/compose.production.yaml up --detach --no-build
curl.exe --fail --show-error http://127.0.0.1/health
curl.exe --fail --show-error http://127.0.0.1/api/status
```

## Tear down

```powershell
docker compose -f deploy/compose.production.yaml down
```

This removes the containers and Compose network. It does not delete ECR images
or other AWS resources.
