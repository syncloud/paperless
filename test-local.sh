#!/bin/bash
set -eo pipefail

LOG=test-local.log
PLATFORM_CONTAINER=paperless.bookworm.com
NETWORK=paperless-local

cleanup() {
  echo "--- cleanup ---"
  docker rm -f "$PLATFORM_CONTAINER" 2>/dev/null || true
  docker network rm "$NETWORK" 2>/dev/null || true
}
trap cleanup EXIT

# Clean previous build output and artifacts (Docker runs as root, so use docker to remove)
docker run --rm -v "$(pwd):/src" alpine sh -c "rm -rf /src/build/* /src/artifact /src/*.snap"

# Generate .drone.yml properly (stderr goes to terminal, not into the file)
drone jsonnet --stdout --stream > .drone.yml

# Create network and start platform service (drone exec does not start services)
docker network create "$NETWORK"
docker run -d \
  --name "$PLATFORM_CONTAINER" \
  --network "$NETWORK" \
  --privileged \
  -v /var/run/dbus:/var/run/dbus \
  -v /dev:/dev \
  syncloud/platform-bookworm-amd64:26.03.1

# Run all build steps (none require the platform service)
drone exec --pipeline amd64 --trusted \
  --include version \
  --include redis \
  --include "redis test" \
  --include postgresql \
  --include "postgresql test" \
  --include paperless \
  --include "paperless test" \
  --include cli \
  --include package \
  .drone.yml 2>&1 | tee "$LOG"

# Run test bookworm manually so it can reach the platform service container
BUILD_NUMBER=$(cat version)
docker run --rm \
  --network "$NETWORK" \
  -v "$(pwd):/drone/src" \
  -w /drone/src \
  python:3.12-slim-bookworm \
  bash -c "mkdir -p artifact/bookworm && cd test && ./deps.sh && py.test -x -s test.py --distro=bookworm --ver=$BUILD_NUMBER --app=paperless" \
  2>&1 | tee -a "$LOG"
