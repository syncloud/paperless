# CI

http://ci.syncloud.org:8080/syncloud/paperless

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/paperless/builds?limit=5"
```

## CI Artifacts

Artifacts are served at `http://ci.syncloud.org:8081` (nginx file browser SPA).
Browse via API with `curl -s "http://ci.syncloud.org:8081/files/paperless/{build}-{arch}/"`.

Example for build 128, amd64:
```
curl -s "http://ci.syncloud.org:8081/files/paperless/128-amd64/bookworm/log/"
```

Directory structure:
```
{build}-{arch}/
  paperless_{build}_{arch}.snap
  bookworm/
    log/
      journalctl.log     # systemd journal from the test run
      ps.log             # process list at time of failure
      netstat.log        # open ports at time of failure
      top.log            # CPU/memory usage
      config.ls.log      # /var/snap/paperless/current/config listing
      var.snap.*.log     # snap directory listings
      data.ls.log        # /data/paperless listing
      hosts.log          # /etc/hosts
      ssl.ca.log         # curl SSL test output
      authelia.config.log
```

Download a file directly:
```
curl -O "http://ci.syncloud.org:8081/files/paperless/128-amd64/bookworm/log/journalctl.log"
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
