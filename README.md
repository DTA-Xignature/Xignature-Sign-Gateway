# Xignature Sign Gateway Installation Guide

This guide installs Sign Gateway using interactive scripts with:

- Docker prerequisite checks
- Docker registry login (username/password prompt)
- Runtime environment input prompts
- Image repository and version/tag input
- Automatic image pull
- Automatic container recreation

## What's new?
- Dashboard & Monitoring: Added real-time metrics visualization.
- API Documentation: Integrated Swagger/OpenAPI on /swagger-ui/index.html#/
- Multiple Sign: Added multiple signature endpoint which allows the system to sign documents in the same process with 2 different signatories.

## Scripts

- Linux/macOS shell: install.sh
- Windows PowerShell: install.ps1
- Windows CMD: install.cmd

## What The Installer Checks

Each installer validates:

- Docker CLI is installed and available in PATH
- Docker daemon is running and accessible

After checks, the installer prompts for registry credentials and performs `docker login`.

If a check fails, the script exits with an error and no deployment changes are made.

## Inputs You Will Be Prompted For

- Docker registry host
- Registry username
- Registry password
- Docker image repository
- Docker image version/tag
- Container name
- Host port (mapped to container 1303)
- API_URL
- API_KEY (required)
- ENV (runtime environment)
- Docker volume name (for SQLite persistence)
- Docker platform (default linux/amd64)

## Linux/macOS (Shell)

Run from repository root:

```bash
chmod +x scripts/install/install.sh
./scripts/install/install.sh
```

## Windows PowerShell

Run from repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install\install.ps1
```

If script execution is blocked, use the command above or configure your execution policy appropriately.

## Windows CMD

Run from repository root:

```cmd
scripts\install\install.cmd
```

## After Installation

The installer prints:

- Container ID
- Container name
- Service URL

Useful runtime commands:

```bash
docker logs -f <container_name>
docker stop <container_name>
docker start <container_name>
```

## Notes

- SQLite data persists in the Docker volume you provide (default: sign-gateway-sqlite).
- Re-running the installer with the same container name will replace the existing container.
- By default, service is exposed on host port 1303 and container port 1303.
