# CI

http://ci.syncloud.org:8080/syncloud/paperless

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/paperless/builds?limit=5"
```

## Checking which step failed

```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/paperless/builds/{build}" | python3 -c "import json,sys; b=json.load(sys.stdin); [print(f'{s[\"name\"]}: {s[\"status\"]}') for s in b.get('stages',[]) for s in s.get('steps',[])]"
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
2. Creates a Docker network and starts the `syncloud/platform-<distro>:<platform>` device container
3. Runs every build and per-distro binary test step with plain `docker run`, using the same
   images and scripts as `.drone.jsonnet` (version and platform pins are read from it)
4. Packages the snap and runs `./ci/test.sh test.py <distro> paperless` against the device container
5. Logs output to `test-local.log`

`DISTRO=buster bash test-local.sh` runs against buster; `BUILD=<n>` sets the build number.
