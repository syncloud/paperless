DAEMONS = ['granian', 'consumer', 'celery', 'celery-beat', 'postgresql', 'redis']


def settle(device):
    device.run_ssh('snap wait system seed.loaded', retries=100, throw=False)
    device.run_ssh('snap set system refresh.hold=2099-01-01T00:00:00Z', retries=20, throw=False)
    device.run_ssh('snap abort --last=auto-refresh', throw=False)
    device.run_ssh('snap watch --last=auto-refresh', throw=False)


def restarts(device, app):
    counts = {}
    for daemon in DAEMONS:
        out = device.run_ssh('systemctl show -p NRestarts --value snap.{0}.{1}.service'.format(app, daemon))
        counts[daemon] = out.strip()
    return counts


def assert_no_restarts(device, app):
    counts = restarts(device, app)
    restarted = {daemon: count for daemon, count in counts.items() if count != '0'}
    assert not restarted, counts
