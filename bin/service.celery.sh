#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

exec ${DIR}/celery --app paperless worker --loglevel INFO --without-mingle --without-gossip
