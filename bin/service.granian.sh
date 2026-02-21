#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export HOME=$DIR/paperless/usr/src/paperless
cd $HOME/src
export TMPDIR=$SNAP_DATA/tmp
export PAPERLESS_CONFIGURATION_PATH=$SNAP_DATA/config/paperless.conf
$DIR/bin/wait-for-configure.sh
if [[ -f /var/snap/platform/current/CI_TEST ]]; then
  export REQUESTS_CA_BUNDLE=/var/snap/platform/current/syncloud.ca.crt
fi
exec $DIR/paperless/sbin/python -m granian --uds $SNAP_COMMON/web.socket --interface asginl --ws --loop uvloop paperless.asgi:application
