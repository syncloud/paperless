#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/paperless
mkdir -p ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
sed -i 's#bind.*=.*#bind="unix:/var/snap/paperless/common/web.socket"#g' ${BUILD_DIR}/usr/src/paperless/gunicorn.conf.py
grep bind ${BUILD_DIR}/usr/src/paperless/gunicorn.conf.py

cp --remove-destination -R ${BUILD_DIR}/usr/src/paperless/src/documents/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/django/contrib/admin/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/admin/css

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/django_extensions/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/django_extensions/css

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/guardian/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/guardian/img

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/rest_framework/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/rest_framework/img

cp --remove-destination -R ${BUILD_DIR}/usr/src/paperless/src/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/paperless/img

cp --remove-destination -R ${DIR}/bin ${BUILD_DIR}/sbin
