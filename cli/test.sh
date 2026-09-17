#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILD_DIR=${DIR}/../build/snap

for hook in install configure pre-refresh post-refresh; do
    ${BUILD_DIR}/meta/hooks/${hook} --help > /dev/null
done

${BUILD_DIR}/bin/cli --help > /dev/null
