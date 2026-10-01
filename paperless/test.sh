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

$BUILD_DIR/sbin/python -c "
import nltk
nltk.data.path = ['$SNAP/paperless/usr/share/nltk_data']
from nltk.corpus import stopwords
from nltk.stem import SnowballStemmer
from nltk.tokenize import word_tokenize
stopwords.ensure_loaded()
assert 'the' in stopwords.words('english')
print(SnowballStemmer('english').stem(word_tokenize('jumping', language='english')[0]))
"
