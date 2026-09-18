#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$1" ]]; then
    echo "usage $0 version"
    exit 1
fi

VERSION=$1
BUILD_DIR=${DIR}/../build/snap/paperless
mkdir -p ${BUILD_DIR}
${DIR}/../ci/apt.sh wget tesseract-ocr-all patchelf

# psycopg resolves libpq through ctypes.util.find_library, which shells out to
# ldconfig and so reads the host's libraries rather than the ones inside the
# snap. psycopg-binary carries its own libpq and needs no lookup at all.
PSYCOPG_VERSION=$(python3 -c "import importlib.metadata as m; print(m.version('psycopg'))")
uv pip install --no-cache --system --no-python-downloads --python-preference system \
    psycopg-binary==${PSYCOPG_VERSION}

cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}

# collectstatic --link creates absolute symlinks that break inside the snap.
# Re-copy the static directory dereferencing all symlinks to get real files.
rm -rf ${BUILD_DIR}/usr/src/paperless/static
cp -rL /usr/src/paperless/static ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static

cp --remove-destination -R ${DIR}/bin ${BUILD_DIR}/sbin

# Patch login.html: don't redirect to signup on first install when regular login
# is disabled (OIDC mode), as the regular signup page will show "Sign Up Closed".
TEMPLATES_DIR=${BUILD_DIR}/usr/src/paperless/src/documents/templates
sed -i 's/{% if FIRST_INSTALL %}/{% if FIRST_INSTALL and not DISABLE_REGULAR_LOGIN %}/' \
    ${TEMPLATES_DIR}/account/login.html


mkdir -p ${DIR}/../build/samples
SAMPLES=https://github.com/paperless-ngx/paperless-ngx/raw/v${VERSION}/src/documents/tests/samples
${DIR}/../ci/download.sh ${SAMPLES}/simple.pdf ${DIR}/../build/samples/simple.pdf
${DIR}/../ci/download.sh ${SAMPLES}/simple.jpg ${DIR}/../build/samples/simple.jpg

SNAP=/snap/paperless/current
mkdir -p $SNAP
ln -s $BUILD_DIR $SNAP/paperless

LD=$(ls $SNAP/paperless/lib/*/ld-linux-*.so.* $SNAP/paperless/lib/*/ld-[0-9]*.so 2>/dev/null | head -1)
if [ -z "${LD}" ]; then
    echo "no glibc loader found under $SNAP/paperless/lib/*/" >&2
    exit 1
fi
LIBS=$(echo $SNAP/paperless/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo $SNAP/paperless/usr/lib/*-linux-gnu*)
LIBS=$LIBS:$SNAP/paperless/usr/local/lib

ldd $BUILD_DIR/usr/bin/convert-im7.q16
patchelf --set-interpreter $LD $BUILD_DIR/usr/bin/convert-im7.q16
patchelf --set-rpath $LIBS $BUILD_DIR/usr/bin/convert-im7.q16
$SNAP/paperless/sbin/convert --version
