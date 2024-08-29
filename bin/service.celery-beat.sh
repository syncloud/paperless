#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export HOME=$DIR/usr/src/paperless
exec $DIR/paperless/bin/python ${DIR}/paperless/usr/local/bin/celery --app paperless beat --loglevel INFO
