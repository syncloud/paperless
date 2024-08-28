#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/paperless
mkdir -p ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
sed -i 's#bind.*=.*#bind="unix:/var/snap/paperless/common/web.socket"' ${BUILD_DIR}/usr/src/paperless/gunicorn.conf.py
grep bind ${BUILD_DIR}/usr/src/paperless/gunicorn.conf.py
cp --remove-destination ${DIR}/bin/* ${BUILD_DIR}/bin
