#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export HOME=$DIR/paperless/usr/src/paperless
cd $HOME/src
export PAPERLESS_CONFIGURATION_PATH=$SNAP_DATA/config/paperless.conf
export PATH=$DIR/paperless/sbin:$PATH
exec $DIR/paperless/bin/python ${DIR}/paperless/usr/local/bin/celery --app paperless beat --loglevel INFO
