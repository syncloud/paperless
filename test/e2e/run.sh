#!/bin/bash -e

DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

SPEC=${1:?usage: run.sh <spec>}

export CI=true
export PLAYWRIGHT_FULL_DOMAIN=bookworm.com
export PLAYWRIGHT_APP_DOMAIN=paperless.bookworm.com
export PLAYWRIGHT_DEVICE_USER=user
export PLAYWRIGHT_DEVICE_PASSWORD=Password1
export PLAYWRIGHT_PROJECT=desktop
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/screenshots
export PLAYWRIGHT_SAMPLES=${DIR}/../../build/samples

${DIR}/../../ci/apt.sh curl
getent hosts ${PLAYWRIGHT_APP_DOMAIN} | sed "s/${PLAYWRIGHT_APP_DOMAIN}/auth.${PLAYWRIGHT_FULL_DOMAIN}/g" | tee -a /etc/hosts
${DIR}/wait-app.sh ${PLAYWRIGHT_APP_DOMAIN}
${DIR}/../../ci/npm.sh
npx playwright test --project=${PLAYWRIGHT_PROJECT} "$SPEC"
