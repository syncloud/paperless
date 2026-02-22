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

# collectstatic --link creates absolute symlinks that break inside the snap.
# Re-copy the static directory dereferencing all symlinks to get real files.
rm -rf ${BUILD_DIR}/usr/src/paperless/static
cp -rL /usr/src/paperless/static ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static

cp --remove-destination -R ${DIR}/bin ${BUILD_DIR}/sbin

# Apply Syncloud customisations to upstream files
PAPERLESS_SRC=${BUILD_DIR}/usr/src/paperless/src/paperless

cp ${DIR}/adapter.py ${PAPERLESS_SRC}/adapter.py

# Patch login.html: don't redirect to signup on first install when regular login
# is disabled (OIDC mode), as the regular signup page will show "Sign Up Closed".
TEMPLATES_DIR=${BUILD_DIR}/usr/src/paperless/src/documents/templates
sed -i 's/{% if FIRST_INSTALL %}/{% if FIRST_INSTALL and not DISABLE_REGULAR_LOGIN %}/' \
    ${TEMPLATES_DIR}/account/login.html

cat >> ${PAPERLESS_SRC}/settings.py << 'EOF'

###############################################################################
# Syncloud customisations                                                     #
###############################################################################
import re

SOCIALACCOUNT_ADMIN_GROUP = os.getenv("PAPERLESS_SOCIALACCOUNT_ADMIN_GROUP", "admin")
SOCIALACCOUNT_ADMIN_GROUP_SCOPE = os.getenv("SOCIALACCOUNT_ADMIN_GROUP_SCOPE", "groups")

FILENAME_PARSE_TRANSFORMS = []
for t in json.loads(os.getenv("PAPERLESS_FILENAME_PARSE_TRANSFORMS", "[]")):
    FILENAME_PARSE_TRANSFORMS.append((re.compile(t["pattern"]), t["repl"]))
EOF

mkdir -p ${DIR}/../build/samples
wget https://github.com/paperless-ngx/paperless-ngx/raw/v2.20.7/src/documents/tests/samples/simple.pdf -O ${DIR}/../build/samples/simple.pdf
wget https://github.com/paperless-ngx/paperless-ngx/raw/v2.20.7/src/documents/tests/samples/simple.jpg -O ${DIR}/../build/samples/simple.jpg

SNAP=/snap/paperless/current
mkdir -p $SNAP
ln -s $BUILD_DIR $SNAP/paperless

LD=$(echo $SNAP/paperless/lib/*/ld-*.so*)
LIBS=$(echo $SNAP/paperless/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo $SNAP/paperless/usr/lib/*-linux-gnu*)
LIBS=$LIBS:$SNAP/paperless/usr/local/lib

ldd $BUILD_DIR/usr/bin/convert-im7.q16
patchelf --set-interpreter $LD $BUILD_DIR/usr/bin/convert-im7.q16
patchelf --set-rpath $LIBS $BUILD_DIR/usr/bin/convert-im7.q16
$SNAP/paperless/sbin/convert --version
