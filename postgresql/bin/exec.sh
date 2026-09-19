#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

BIN=$1
shift

LIBS=$(ls -d ${DIR}/lib/*linux* ${DIR}/usr/lib/*linux* 2>/dev/null | paste -sd: -)
LD=$(ls ${DIR}/lib/*/ld-linux-*.so.* ${DIR}/lib/*/ld-[0-9]*.so 2>/dev/null | head -1)

exec "${LD}" --library-path "${LIBS}" ${DIR}/usr/lib/postgresql/*/bin/${BIN} "$@"
