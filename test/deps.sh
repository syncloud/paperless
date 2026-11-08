#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

${DIR}/../ci/apt.sh sshpass openssh-client
${DIR}/../ci/pip.sh -r ${DIR}/requirements.txt
