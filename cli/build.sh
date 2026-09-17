#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILD_DIR=${DIR}/../build/snap

cd ${DIR}

mkdir -p ${BUILD_DIR}/meta/hooks ${BUILD_DIR}/bin

for hook in install configure pre-refresh post-refresh; do
    CGO_ENABLED=0 go build -buildvcs=false -o ${BUILD_DIR}/meta/hooks/${hook} ./cmd/${hook}
done

CGO_ENABLED=0 go build -buildvcs=false -o ${BUILD_DIR}/bin/cli ./cmd/cli
