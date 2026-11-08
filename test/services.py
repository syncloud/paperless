SERVICES = ['granian', 'consumer', 'celery', 'celery-beat', 'postgresql', 'redis']


def restarts(device, app):
    result = {}
    for service in SERVICES:
        out = device.run_ssh('systemctl show -p NRestarts --value snap.{0}.{1}.service'.format(app, service))
        result[service] = out.strip()
    return result


def assert_no_restarts(device, app):
    counts = restarts(device, app)
    restarted = {k: v for k, v in counts.items() if v != '0'}
    assert not restarted, restarted
