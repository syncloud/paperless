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
$BUILD_DIR/sbin/gs --version
$BUILD_DIR/sbin/gpg --version
$BUILD_DIR/sbin/pdftotext -v
$BUILD_DIR/sbin/pdftoppm -v
$BUILD_DIR/sbin/pdfinfo -v
$BUILD_DIR/sbin/qpdf --version
$BUILD_DIR/sbin/unpaper --version

$BUILD_DIR/sbin/python -c "
import tantivy
analyzer = tantivy.TextAnalyzerBuilder(tantivy.Tokenizer.regex(r'\w+')).filter(tantivy.Filter.lowercase()).filter(tantivy.Filter.stemmer('english')).build()
assert analyzer.analyze('Jumping') == ['jump'], analyzer.analyze('Jumping')
"

FONT=$SNAP/paperless/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf
test -f $FONT
$BUILD_DIR/sbin/python -c "
from PIL import ImageFont
font = ImageFont.truetype(font='$FONT', size=20, layout_engine=ImageFont.Layout.BASIC)
print(font.getname())
"
