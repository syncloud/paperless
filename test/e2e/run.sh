#!/bin/bash -e
# usage: run.sh <artifact-subdir> <spec>
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

ARTIFACT_SUBDIR=$1
SPEC=$2

export PLAYWRIGHT_FULL_DOMAIN=${PLAYWRIGHT_FULL_DOMAIN:-bookworm.com}
export PLAYWRIGHT_APP_DOMAIN=${PLAYWRIGHT_APP_DOMAIN:-paperless.${PLAYWRIGHT_FULL_DOMAIN}}
export PLAYWRIGHT_DEVICE_HOST=${PLAYWRIGHT_DEVICE_HOST:-${PLAYWRIGHT_APP_DOMAIN}}
export PLAYWRIGHT_DEVICE_USER=${PLAYWRIGHT_DEVICE_USER:-user}
export PLAYWRIGHT_DEVICE_PASSWORD=${PLAYWRIGHT_DEVICE_PASSWORD:-Password1}
export PLAYWRIGHT_SSH_USER=${PLAYWRIGHT_SSH_USER:-root}
export PLAYWRIGHT_SSH_PASSWORD=${PLAYWRIGHT_SSH_PASSWORD:-Password1}
export PLAYWRIGHT_PROJECT=${PLAYWRIGHT_PROJECT:-desktop}
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/${ARTIFACT_SUBDIR}
export PLAYWRIGHT_SAMPLES=${PLAYWRIGHT_SAMPLES:-${DIR}/../../build/samples}

"${DIR}/../../ci/apt.sh" sshpass openssh-client curl
getent hosts "${PLAYWRIGHT_APP_DOMAIN}" | sed "s/${PLAYWRIGHT_APP_DOMAIN}/auth.${PLAYWRIGHT_FULL_DOMAIN}/g" | tee -a /etc/hosts
"${DIR}/wait-app.sh" "${PLAYWRIGHT_APP_DOMAIN}"
"${DIR}/../../ci/npm.sh"
npx playwright test --project=desktop "$SPEC"
