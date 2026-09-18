#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

SPEC=$1
DISTRO=$2
APP=$3

cd ${DIR}/test
./deps.sh
py.test -x -s ${SPEC} --distro=${DISTRO} --ver=${DRONE_BUILD_NUMBER} --app=${APP}
