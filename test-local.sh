#!/bin/bash
set -e

LOG=test-local.log

# Clean previous build output (Docker runs as root, so use docker to remove)
[ -d build ] && docker run --rm -v "$(pwd)/build:/build" alpine sh -c "rm -rf /build/*"

# Generate .drone.yml properly (stderr goes to terminal, not into the file)
drone jsonnet --stdout --stream > .drone.yml

# Run amd64 pipeline with paperless build and test steps, saving full log
drone exec --pipeline amd64 --trusted \
  --include version \
  --include paperless \
  --include "paperless test" \
  .drone.yml 2>&1 | tee "$LOG"
