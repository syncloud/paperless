#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export HOME=$DIR/paperless/usr/src/paperless
cd $HOME/src
export PAPERLESS_CONFIGURATION_PATH=$SNAP_DATA/config/paperless.conf
$DIR/bin/wait-for-configure.sh
exec $DIR/paperless/sbin/python ${DIR}/paperless/usr/local/bin/gunicorn -c $DIR/paperless/usr/src/paperless/gunicorn.conf.py paperless.asgi:application
