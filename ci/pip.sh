#!/bin/bash -e

for i in $(seq 1 10); do
    if pip install "$@"; then
        exit 0
    fi
    echo "retry pip"
    sleep 10
done
echo "pip failed"
exit 1
