#!/bin/bash
set -e

DOCKER_IMAGE="${1:?Usage: deploy.sh <image> <tag>}"
IMAGE_TAG="${2:-latest}"
APP_DIR="/opt/ci_cd_demo"

echo "==> Deploying $DOCKER_IMAGE:$IMAGE_TAG"

# Pull latest image
docker pull "$DOCKER_IMAGE:$IMAGE_TAG"

# Ensure app directory exists with compose file
mkdir -p "$APP_DIR"
cat > "$APP_DIR/docker-compose.yml" << EOF
version: '3.8'
services:
  app:
    image: ${DOCKER_IMAGE}:${IMAGE_TAG}
    container_name: ci_cd_demo
    restart: unless-stopped
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
EOF

# Rolling restart (pull already done above)
cd "$APP_DIR"
docker compose up -d --no-build

# Wait for health check
echo "==> Waiting for health check..."
for i in $(seq 1 12); do
  if wget -qO- http://localhost:8080/health 2>/dev/null | grep -q UP; then
    echo "==> Health check passed"
    # Prune old images
    docker image prune -f
    exit 0
  fi
  sleep 5
done

echo "==> Health check failed after 60s" >&2
exit 1
