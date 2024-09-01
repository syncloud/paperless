#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export HOME=$DIR/paperless/usr/src/paperless
cd $HOME/src
export PAPERLESS_CONFIGURATION_PATH=$SNAP_DATA/config/paperless.conf
export PATH=$DIR/paperless/sbin:$PATH
$DIR/paperless/sbin/python manage.py migrate --skip-checks --no-input
$DIR/paperless/sbin/python manage.py check
$DIR/paperless/sbin/python manage.py document_index reindex --no-progress-bar
