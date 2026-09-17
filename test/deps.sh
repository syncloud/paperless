#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

${DIR}/../ci/apt.sh sshpass openssh-client
pip install -r ${DIR}/requirements.txt
