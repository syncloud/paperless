#!/bin/bash -e

for i in $(seq 1 10); do
    if npm ci --no-audit --no-fund --fetch-retries=5 --fetch-retry-maxtimeout=60000; then
        exit 0
    fi
    echo "retry npm ci"
    sleep 10
done
echo "npm ci failed"
exit 1
