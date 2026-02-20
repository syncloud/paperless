# CI

http://ci.syncloud.org:8080/syncloud/paperless

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/paperless/builds?limit=5"
```

# Running Drone builds locally

Generate `.drone.yml` from jsonnet (run from project root):
```
drone jsonnet --stdout --stream > .drone.yml
```

Run a specific pipeline with selected steps (e.g. amd64 up to `test bookworm`):
```
drone exec --pipeline amd64 --trusted \
  --include version \
  --include redis \
  --include "redis test" \
  --include postgresql \
  --include "postgresql test" \
  --include paperless \
  --include "paperless test" \
  --include cli \
  --include package \
  --include "test bookworm" \
  .drone.yml
```

Notes:
- `--trusted` is required for privileged/volume steps
- `--include` selects only listed steps (in pipeline order); omit to run all steps
- `drone jsonnet --stdout --stream` sends stderr to stderr (proto warnings are harmless)
