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

docker run --rm -v "$(pwd):/src" alpine sh -c "rm -rf /src/build/* /src/artifact /src/*.snap"

drone jsonnet --stdout --stream > .drone.yml

docker network create "$NETWORK"
docker run -d \
  --name "$PLATFORM_CONTAINER" \
  --network "$NETWORK" \
  --privileged \
  -v /var/run/dbus:/var/run/dbus \
  -v /dev:/dev \
  --entrypoint /bin/sh \
  syncloud/platform-bookworm:26.10.02 \
  -c "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"

drone exec --pipeline amd64 --trusted \
  --include redis \
  --include "redis test bookworm" \
  --include postgresql \
  --include "postgresql test bookworm" \
  --include paperless \
  --include "paperless test bookworm" \
  --include cli \
  --include "cli test bookworm" \
  --include package \
  .drone.yml 2>&1 | tee "$LOG"

BUILD_NUMBER=$(cat version)
docker run --rm \
  --network "$NETWORK" \
  -v "$(pwd):/drone/src" \
  -w /drone/src \
  python:3.12-slim-bookworm \
  bash -c "mkdir -p artifact/bookworm && cd test && ./deps.sh && py.test -x -s test.py --distro=bookworm --ver=$BUILD_NUMBER --app=paperless" \
  2>&1 | tee -a "$LOG"
