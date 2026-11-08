#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/paperless
mkdir -p ${BUILD_DIR}
${DIR}/../ci/apt.sh wget tesseract-ocr-all patchelf

PSYCOPG_VERSION=$(python3 -c "import importlib.metadata as m; print(m.version('psycopg'))")
${DIR}/../ci/pip.sh psycopg-binary==${PSYCOPG_VERSION}

cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}

rm -rf ${BUILD_DIR}/usr/src/paperless/static
cp -rL /usr/src/paperless/static ${BUILD_DIR}/usr/src/paperless/static
ls -la ${BUILD_DIR}/usr/src/paperless/static

cp --remove-destination -R ${DIR}/bin ${BUILD_DIR}/sbin

mkdir -p ${DIR}/../build/samples
SAMPLES=https://github.com/paperless-ngx/paperless-ngx/raw/v3.1.3/src/documents/tests/samples
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

patchelf --set-interpreter $LD $BUILD_DIR/usr/local/bin/python3
patchelf --force-rpath --set-rpath $LIBS $BUILD_DIR/usr/local/bin/python3
for lib in $BUILD_DIR/usr/local/lib/libpython*.so*; do
    patchelf --force-rpath --set-rpath $LIBS $lib
done
$SNAP/paperless/usr/local/bin/python3 --version
