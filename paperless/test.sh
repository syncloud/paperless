#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/paperless

SNAP=/snap/paperless/current
mkdir -p $SNAP
ln -s $BUILD_DIR $SNAP/paperless

$BUILD_DIR/sbin/python --version
$SNAP/paperless/usr/local/bin/python3 --version
$SNAP/paperless/usr/local/bin/python3 -c "from psycopg import pq; assert pq.__impl__ == 'binary', pq.__impl__; print('psycopg pq impl:', pq.__impl__)"
$BUILD_DIR/sbin/python ${BUILD_DIR}/usr/local/bin/celery --version
$BUILD_DIR/sbin/python ${BUILD_DIR}/usr/local/bin/granian --version
$BUILD_DIR/sbin/tesseract --list-langs | grep eng
$BUILD_DIR/sbin/convert --version
$BUILD_DIR/sbin/gs --version
$BUILD_DIR/sbin/gpg --version
$BUILD_DIR/sbin/pdftotext -v
$BUILD_DIR/sbin/unpaper --version
