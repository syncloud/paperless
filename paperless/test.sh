#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/paperless
#$BUILD_DIR/bin/python --version
#$BUILD_DIR/bin/python ${BUILD_DIR}/usr/local/bin/celery --version
$BUILD_DIR/sbin/tesseract --list-langs | grep eng
$BUILD_DIR/sbin/tesseract --list-langs
$BUILD_DIR/sbin/convert --version
