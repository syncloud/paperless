#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/paperless
mkdir -p ${BUILD_DIR}
apt update
apt install -y wget tesseract-ocr-all patchelf

cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp --remove-destination -R ${BUILD_DIR}/usr/src/paperless/src/documents/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.12/site-packages/django/contrib/admin/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/admin/css

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.12/site-packages/django_extensions/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/django_extensions/css

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.12/site-packages/guardian/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/guardian/img

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.12/site-packages/rest_framework/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/rest_framework/img

cp --remove-destination -R ${BUILD_DIR}/usr/src/paperless/src/paperless/static/* ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static/paperless/img

cp --remove-destination -R ${DIR}/bin ${BUILD_DIR}/sbin

cd ${DIR}/../build
wget https://github.com/cyberb/paperless-ngx/archive/refs/heads/dev.tar.gz
tar xf dev.tar.gz
cp paperless-ngx-dev/src/paperless/adapter.py ${BUILD_DIR}/usr/src/paperless/src/paperless
cp paperless-ngx-dev/src/paperless/settings.py ${BUILD_DIR}/usr/src/paperless/src/paperless

#sed -i 's#return \["openid", "profile", "email"\]#return \["openid", "profile", "email", "groups"\]#g' ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py
#grep profile ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py

#sed -i 's#username=data.get("preferred_username"),#username=data.get("preferred_username"), groups=data.get("groups"),#g' ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py
#grep groups ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py

cp -r paperless-ngx-dev/src/documents/tests/samples/* ${DIR}/../build/samples

SNAP=/snap/paperless/current
mkdir -p $SNAP
ln -s $BUILD_DIR $SNAP/paperless

LD=$(echo $SNAP/paperless/lib/*/ld-*.so*)
LIBS=$(echo $SNAP/paperless/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo $SNAP/paperless/usr/lib/*-linux-gnu*)
LIBS=$LIBS:$SNAP/paperless/usr/local/lib

ldd $BUILD_DIR/usr/bin/convert-im6.q16
patchelf --set-interpreter $LD $BUILD_DIR/usr/bin/convert-im6.q16
patchelf --set-rpath $LIBS $BUILD_DIR/usr/bin/convert-im6.q16
$SNAP/paperless/sbin/convert --version
