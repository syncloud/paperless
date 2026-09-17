local name = 'paperless';
local version = '2.20.15';

local go = '1.25';
local nginx = '1.29.3-alpine3.22';
local postgresql = '15-bookworm';
local redis = '7.0.15';
local debian = 'bookworm-slim';
local python = '3.12-slim-bookworm';
local platform = '26.08.01';
local playwright = 'mcr.microsoft.com/playwright:v1.48.2-jammy';
local store_publisher = 'stable-346';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];

local platform_image(distro) =
  'syncloud/platform-' + distro + ':' + platform;

local snapd_hold = "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init";

local build(arch, test_ui) = [{
  kind: 'pipeline',
  type: 'docker',
  name: arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'redis',
      image: 'redis:' + redis,
      commands: ['./redis/build.sh'],
    },
  ] + [
    {
      name: 'redis test ' + distro,
      image: platform_image(distro),
      commands: ['./redis/test.sh'],
    }
    for distro in distros
  ] + [
    {
      name: 'postgresql',
      image: 'postgres:' + postgresql,
      commands: ['./postgresql/build.sh'],
    },
  ] + [
    {
      name: 'postgresql test ' + distro,
      image: platform_image(distro),
      commands: ['./postgresql/test.sh'],
    }
    for distro in distros
  ] + [
    {
      name: 'paperless',
      image: 'ghcr.io/paperless-ngx/paperless-ngx:' + version,
      commands: ['./paperless/build.sh ' + version],
    },
  ] + [
    {
      name: 'paperless test ' + distro,
      image: platform_image(distro),
      commands: ['./paperless/test.sh'],
    }
    for distro in distros
  ] + [
    {
      name: 'cli',
      image: 'golang:' + go,
      commands: ['./cli/build.sh'],
    },
  ] + [
    {
      name: 'cli test ' + distro,
      image: platform_image(distro),
      commands: ['./cli/test.sh'],
    }
    for distro in distros
  ] + [
    {
      name: 'package',
      image: 'debian:' + debian,
      commands: ['./package.sh ' + name + ' $DRONE_BUILD_NUMBER'],
    },
  ] + [
    {
      name: 'test ' + distro,
      image: 'python:' + python,
      commands: ['./ci/test.sh test.py ' + distro + ' ' + name],
    }
    for distro in distros
  ] + (if test_ui then [
         {
           name: 'e2e',
           image: playwright,
           commands: ['./test/e2e/run.sh e2e specs/01-smoke.spec.ts'],
         },
         {
           name: 'test-upgrade-prev',
           image: 'python:' + python,
           commands: ['./ci/test.sh upgrade_prev.py ' + distro_default + ' ' + name],
         },
         {
           name: 'e2e-before-upgrade',
           image: playwright,
           commands: ['./test/e2e/run.sh e2e-before-upgrade specs/02-pre-upgrade.spec.ts'],
         },
         {
           name: 'test-upgrade',
           image: 'python:' + python,
           commands: ['./ci/test.sh upgrade.py ' + distro_default + ' ' + name],
         },
         {
           name: 'e2e-after-upgrade',
           image: playwright,
           commands: ['./test/e2e/run.sh e2e-after-upgrade specs/03-post-upgrade.spec.ts'],
         },
       ] else []) + [
    {
      name: 'publish',
      image: 'syncloud/store-publisher:' + store_publisher,
      environment: {
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      command: ['snap', '-c', '${DRONE_BRANCH}'],
      when: {
        branch: ['stable'],
        event: ['push'],
      },
    },
    {
      name: 'artifact',
      image: 'appleboy/drone-scp:1.6.4',
      settings: {
        host: { from_secret: 'artifact_host' },
        username: 'artifact',
        key: { from_secret: 'artifact_key' },
        timeout: '2m',
        command_timeout: '2m',
        target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
        source: 'artifact/*',
        strip_components: 1,
      },
      when: {
        status: ['failure', 'success'],
      },
    },
  ],
  trigger: {
    event: ['push'],
  },
  services: [
    {
      name: name + '.' + distro + '.com',
      image: platform_image(distro),
      privileged: true,
      entrypoint: ['/bin/sh', '-c', snapd_hold],
      volumes: [
        { name: 'dbus', path: '/var/run/dbus' },
        { name: 'dev', path: '/dev' },
      ],
    }
    for distro in distros
  ],
  volumes: [
    { name: 'dbus', host: { path: '/var/run/dbus' } },
    { name: 'dev', host: { path: '/dev' } },
    { name: 'shm', temp: {} },
  ],
}];

build('amd64', true) +
build('arm64', false)
