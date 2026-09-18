#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

LIBS=$(ls -d ${DIR}/lib/*-linux-gnu* 2>/dev/null | paste -sd: -)
LD=$(ls ${DIR}/lib/*-linux*/ld-linux-*.so.* ${DIR}/lib/*-linux*/ld-[0-9]*.so 2>/dev/null | head -1)

exec "${LD}" --library-path "${LIBS}" ${DIR}/usr/local/bin/redis-server "$@"
