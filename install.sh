#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

prompt_default() {
  local message="$1"
  local default_value="$2"
  local input

  read -r -p "$message [$default_value]: " input
  if [[ -z "${input}" ]]; then
    echo "$default_value"
  else
    echo "$input"
  fi
}

prompt_required() {
  local message="$1"
  local input
  while true; do
    read -r -p "$message: " input
    if [[ -n "${input}" ]]; then
      echo "$input"
      return
    fi
    echo "Value is required."
  done
}

echo "== Sign Gateway Docker Installer (Linux/macOS shell) =="

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker is not installed or not on PATH."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon is not running or not accessible."
  exit 1
fi

echo "Docker prerequisites check passed."

REGISTRY_HOST="$(prompt_default "Docker registry host" "registry.xignature.co.id")"
REGISTRY_USERNAME="$(prompt_required "Registry username")"
read -r -s -p "Registry password: " REGISTRY_PASSWORD
echo ""

echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_HOST" --username "$REGISTRY_USERNAME" --password-stdin
unset REGISTRY_PASSWORD

IMAGE_REPO="$(prompt_default "Docker image repository" "registry.xignature.co.id/xignature/public-sign-gateway")"
IMAGE_TAG="$(prompt_default "Docker image version/tag" "latest")"
IMAGE_NAME="${IMAGE_REPO}:${IMAGE_TAG}"

echo "Pulling image $IMAGE_NAME..."
docker pull "$IMAGE_NAME"

CONTAINER_NAME="$(prompt_default "Container name" "sign-gateway")"
HOST_PORT="$(prompt_default "Host port" "1303")"
API_URL="$(prompt_default "API_URL" "https://api.xignature.dev")"
API_KEY="$(prompt_required "API_KEY")"
PASSWORD="$(prompt_required "PASSWORD (basic auth admin)")"
RUNTIME_ENV="$(prompt_default "ENV" "STAGING")"
VOLUME_NAME="$(prompt_default "Docker volume for SQLite" "sign-gateway-sqlite")"
PLATFORM="$(prompt_default "Docker platform" "linux/amd64")"

echo "Preparing container and volume..."
docker volume create "$VOLUME_NAME" >/dev/null

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

CONTAINER_ID="$(docker run -d \
  --name "$CONTAINER_NAME" \
  --platform "$PLATFORM" \
  -e API_URL="$API_URL" \
  -e API_KEY="$API_KEY" \
  -e PASSWORD="$PASSWORD" \
  -e ENV="$RUNTIME_ENV" \
  -v "$VOLUME_NAME:/data" \
  -p "$HOST_PORT:1303" \
  "$IMAGE_NAME")"

echo "Install complete."
echo "Container ID: $CONTAINER_ID"
echo "Container name: $CONTAINER_NAME"
echo "Service URL: http://localhost:$HOST_PORT"
echo ""
echo "Useful commands:"
echo "  docker logs -f $CONTAINER_NAME"
echo "  docker stop $CONTAINER_NAME"
echo "  docker start $CONTAINER_NAME"
