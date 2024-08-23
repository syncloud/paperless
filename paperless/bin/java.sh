#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
export JAVA_HOME=$(echo $DIR/usr/lib/jvm/java-17-openjdk-*)
exec ${DIR}/lib/*-linux*/ld-*.so.* --library-path $LIBS $JAVA_HOME/bin/java "$@"
