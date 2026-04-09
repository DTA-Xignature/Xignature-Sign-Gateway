$ErrorActionPreference = "Stop"

$rootDir = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $rootDir

$defaultImageRepo = "registry.xignature.co.id/xignature/public-sign-gateway"

function Read-DefaultValue {
    param(
        [string]$Prompt,
        [string]$Default
    )

    $value = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value.Trim()
}

function Read-RequiredValue {
    param([string]$Prompt)

    while ($true) {
        $value = Read-Host "$Prompt"
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }

        Write-Host "Value is required." -ForegroundColor Yellow
    }
}

Write-Host "== Sign Gateway Docker Installer (PowerShell) =="

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not available in PATH."
}

try {
    docker info | Out-Null
} catch {
    Write-Error "Docker daemon is not running or not accessible."
}

$dockerOsType = (docker info --format "{{.OSType}}" 2>$null).Trim()
if ($dockerOsType -ne "linux") {
    Write-Error "Docker is running in Windows container mode. Switch Docker Desktop to Linux containers and try again."
}

Write-Host "Docker prerequisites check passed." -ForegroundColor Green

$registryHost = Read-DefaultValue "Docker registry host" "registry.xignature.co.id"
$registryUsername = Read-RequiredValue "Registry username"
$secureRegistryPassword = Read-Host "Registry password" -AsSecureString
$registryPasswordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureRegistryPassword)
$registryPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($registryPasswordPtr)
try {
    $registryPassword | docker login $registryHost --username $registryUsername --password-stdin
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($registryPasswordPtr)
}

$imageRepo = Read-DefaultValue "Docker image repository" $defaultImageRepo
$imageTag = Read-DefaultValue "Docker image version/tag" "latest"
$imageName = "$imageRepo`:$imageTag"

Write-Host "Pulling image $imageName..."
docker pull $imageName

$containerName = Read-DefaultValue "Container name" "sign-gateway"
$hostPort = Read-DefaultValue "Host port" "1303"
$apiUrl = Read-DefaultValue "API_URL" "https://api.xignature.dev"
$apiKey = Read-RequiredValue "API_KEY"
$password = Read-RequiredValue "PASSWORD (basic auth admin)"
$runtimeEnv = Read-DefaultValue "ENV" "STAGING"
$volumeName = Read-DefaultValue "Docker volume for SQLite" "sign-gateway-sqlite"
$platform = Read-DefaultValue "Docker platform" "linux/amd64"

Write-Host "Preparing container and volume..."
docker volume create $volumeName | Out-Null

docker rm -f $containerName | Out-Null 2>$null

$containerId = docker run -d `
  --name $containerName `
  --platform $platform `
  -e API_URL=$apiUrl `
  -e API_KEY=$apiKey `
    -e PASSWORD=$password `
  -e ENV=$runtimeEnv `
  -v "${volumeName}:/data" `
    -p "${hostPort}:1303" `
  $imageName

Write-Host "Install complete." -ForegroundColor Green
Write-Host "Container ID: $containerId"
Write-Host "Container name: $containerName"
Write-Host "Service URL: http://localhost:$hostPort"
Write-Host ""
Write-Host "Useful commands:"
Write-Host "  docker logs -f $containerName"
Write-Host "  docker stop $containerName"
Write-Host "  docker start $containerName"
