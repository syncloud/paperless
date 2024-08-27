#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

exec $DIR/bin/python ${DIR}/usr/local/bin/celery --app paperless worker --loglevel INFO --without-mingle --without-gossip
