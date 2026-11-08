#!/bin/bash -e

for i in $(seq 1 10); do
    if uv pip install --no-cache --system --no-python-downloads --python-preference system "$@"; then
        exit 0
    fi
    echo "retry pip install"
    sleep 10
done
echo "pip install failed"
exit 1
