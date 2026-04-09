@echo off
setlocal enabledelayedexpansion

set ROOT_DIR=%~dp0\..\..
pushd "%ROOT_DIR%" >nul

set DEFAULT_IMAGE_REPO=registry.xignature.co.id/xignature/public-sign-gateway

echo == Sign Gateway Docker Installer (Windows CMD) ==

where docker >nul 2>nul
if errorlevel 1 (
  echo Error: Docker is not installed or not on PATH.
  popd >nul
  exit /b 1
)

docker info >nul 2>nul
if errorlevel 1 (
  echo Error: Docker daemon is not running or not accessible.
  popd >nul
  exit /b 1
)

echo Docker prerequisites check passed.

set /p REGISTRY_HOST=Docker registry host [registry.xignature.co.id]: 
if "%REGISTRY_HOST%"=="" set REGISTRY_HOST=registry.xignature.co.id

set /p REGISTRY_USERNAME=Registry username: 
if "%REGISTRY_USERNAME%"=="" (
  echo Value is required.
  popd >nul
  exit /b 1
)

set /p REGISTRY_PASSWORD=Registry password: 
if "%REGISTRY_PASSWORD%"=="" (
  echo Value is required.
  popd >nul
  exit /b 1
)

echo %REGISTRY_PASSWORD%| docker login %REGISTRY_HOST% --username %REGISTRY_USERNAME% --password-stdin
if errorlevel 1 (
  echo Error: Docker login failed.
  popd >nul
  exit /b 1
)
set REGISTRY_PASSWORD=

set /p IMAGE_REPO=Docker image repository [%DEFAULT_IMAGE_REPO%]: 
if "%IMAGE_REPO%"=="" set IMAGE_REPO=%DEFAULT_IMAGE_REPO%

set /p IMAGE_TAG=Docker image version/tag [latest]: 
if "%IMAGE_TAG%"=="" set IMAGE_TAG=latest

set IMAGE_NAME=%IMAGE_REPO%:%IMAGE_TAG%

echo Pulling image %IMAGE_NAME%...
docker pull %IMAGE_NAME%

set /p CONTAINER_NAME=Container name [sign-gateway]: 
if "%CONTAINER_NAME%"=="" set CONTAINER_NAME=sign-gateway

set /p HOST_PORT=Host port [1303]: 
if "%HOST_PORT%"=="" set HOST_PORT=1303

set /p API_URL=API_URL [https://api.xignature.dev]: 
if "%API_URL%"=="" set API_URL=https://api.xignature.dev

:read_api_key
set /p API_KEY=API_KEY: 
if "%API_KEY%"=="" (
  echo Value is required.
  goto read_api_key
)

:read_password
set /p PASSWORD=PASSWORD (basic auth admin): 
if "%PASSWORD%"=="" (
  echo Value is required.
  goto read_password
)

set /p RUNTIME_ENV=ENV [STAGING]: 
if "%RUNTIME_ENV%"=="" set RUNTIME_ENV=STAGING

set /p VOLUME_NAME=Docker volume for SQLite [sign-gateway-sqlite]: 
if "%VOLUME_NAME%"=="" set VOLUME_NAME=sign-gateway-sqlite

set /p PLATFORM=Docker platform [linux/amd64]: 
if "%PLATFORM%"=="" set PLATFORM=linux/amd64

echo Preparing container and volume...
docker volume create %VOLUME_NAME% >nul

docker rm -f %CONTAINER_NAME% >nul 2>nul

for /f %%i in ('docker run -d --name %CONTAINER_NAME% --platform %PLATFORM% -e API_URL=%API_URL% -e API_KEY=%API_KEY% -e PASSWORD=%PASSWORD% -e ENV=%RUNTIME_ENV% -v %VOLUME_NAME%:/data -p %HOST_PORT%:1303 %IMAGE_NAME%') do set CONTAINER_ID=%%i

echo Install complete.
echo Container ID: %CONTAINER_ID%
echo Container name: %CONTAINER_NAME%
echo Service URL: http://localhost:%HOST_PORT%
echo.
echo Useful commands:
echo   docker logs -f %CONTAINER_NAME%
echo   docker stop %CONTAINER_NAME%
echo   docker start %CONTAINER_NAME%

popd >nul
exit /b 0
