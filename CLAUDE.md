# CI

http://ci.syncloud.org:8080/syncloud/paperless

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/paperless/builds?limit=5"
```

# Running tests locally

Use the provided shell script (run from project root):
```
bash test-local.sh
```

This script:
1. Cleans previous build output (uses Docker to remove root-owned files)
2. Generates `.drone.yml` from jsonnet
3. Creates a Docker network and starts the platform service container
4. Runs all build/test steps via `drone exec --pipeline amd64 --trusted`
5. Runs the `test bookworm` step manually against the platform container
6. Logs output to `test-local.log`

Notes:
- `--trusted` is required for privileged/volume steps
- `drone jsonnet --stdout --stream` sends stderr to stderr (proto warnings are harmless)
