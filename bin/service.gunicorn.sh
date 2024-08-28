#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export HOME=$DIR/usr/src/paperless
exec $DIR/bin/python ${DIR}/usr/local/bin/gunicorn -c $DIR/usr/src/paperless/gunicorn.conf.py paperless.asgi:application
