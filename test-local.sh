#!/bin/bash
set -eo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

LOG=${DIR}/test-local.log
NAME=paperless
BUILD=${BUILD:-1}
DISTRO=${DISTRO:-bookworm}
pin() {
  sed -n "s/^local $1 = '\(.*\)';/\1/p" .drone.jsonnet
}
VERSION=$(pin version)
PLATFORM=$(pin platform)
PLATFORM_IMAGE=syncloud/platform-${DISTRO}:${PLATFORM}
DEVICE=${NAME}.${DISTRO}.com
NETWORK=${NAME}-local

cleanup() {
  docker rm -f ${DEVICE} 2>/dev/null || true
  docker network rm ${NETWORK} 2>/dev/null || true
}
trap cleanup EXIT

step() {
  local image=$1
  shift
  echo "=== ${image} $*"
  docker run --rm --entrypoint "" --network ${NETWORK} -e DRONE_BUILD_NUMBER=${BUILD} \
    -v ${DIR}:/drone/src -w /drone/src ${image} "$@"
}

docker run --rm -v ${DIR}:/src alpine sh -c "rm -rf /src/build /src/artifact /src/*.snap /src/version /src/package.name"
docker network create ${NETWORK}
docker run -d --name ${DEVICE} --network ${NETWORK} --privileged \
  -v /var/run/dbus:/var/run/dbus -v /dev:/dev ${PLATFORM_IMAGE}

{
  step redis:$(pin redis) ./redis/build.sh
  step ${PLATFORM_IMAGE} ./redis/test.sh
  step postgres:$(pin postgresql) ./postgresql/build.sh
  step ${PLATFORM_IMAGE} ./postgresql/test.sh
  step ghcr.io/paperless-ngx/paperless-ngx:${VERSION} ./paperless/build.sh
  step ${PLATFORM_IMAGE} ./paperless/test.sh
  step golang:$(pin go) ./cli/build.sh
  step ${PLATFORM_IMAGE} ./cli/test.sh
  step debian:$(pin debian) ./package.sh ${NAME} ${BUILD}
  step python:$(pin python) ./ci/test.sh test.py ${DISTRO} ${NAME}
} 2>&1 | tee ${LOG}
