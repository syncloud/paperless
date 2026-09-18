#!/bin/bash -xe

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/postgresql
cd ${BUILD_DIR}

PGBIN=$(echo usr/lib/postgresql/*/bin)

./bin/initdb.sh --version
./bin/psql.sh --version
./bin/pg_ctl.sh --version
./bin/pg_dumpall.sh --version

${PGBIN}/postgres -V
${PGBIN}/pg_dump --version
