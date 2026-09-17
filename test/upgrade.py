import pytest
import requests
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest

TMP_DIR = '/tmp/syncloud'
V3_FLOOR_MIGRATION = '1075_workflowaction_order'
BEFORE = {}


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir):
    def module_teardown():
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/upgrade.journalctl.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), artifact_dir, throw=False)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def psql(device, sql):
    return device.run_ssh(
        'snap run paperless.psql -U paperless -d paperless -t -A -c "{0}"'.format(sql))


def document_count(device):
    return int(psql(device, 'select count(*) from documents_document').strip())


def applied_migrations(device):
    out = psql(device, "select name from django_migrations where app = 'documents'")
    return set(line.strip() for line in out.split('\n') if line.strip())


def test_start(module_setup, app, device_host, domain, device):
    add_host_alias(app, device_host, domain)
    device.activated()
    device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)


def test_record_state_before_upgrade(device):
    BEFORE['documents'] = document_count(device)
    BEFORE['migrations'] = applied_migrations(device)
    print('before upgrade: {0} documents, {1} migrations'.format(
        BEFORE['documents'], len(BEFORE['migrations'])))
    assert BEFORE['documents'] > 0, 'e2e-before-upgrade should have seeded a document'


def test_upgrade(device_host, device_password, app_archive_path, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_documents_survived(device):
    after = document_count(device)
    print('documents {0} -> {1}'.format(BEFORE['documents'], after))
    assert after == BEFORE['documents'], (BEFORE['documents'], after)


def test_migrations_only_moved_forward(device):
    after = applied_migrations(device)
    lost = BEFORE['migrations'] - after
    assert not lost, 'migrations disappeared across the upgrade: {0}'.format(sorted(lost))


def test_v3_floor_migration_applied(device):
    after = applied_migrations(device)
    assert V3_FLOOR_MIGRATION in after, (
        'paperless-ngx v3 refuses to start unless {0} is applied; this release exists to '
        'establish that floor. Applied tail: {1}'.format(
            V3_FLOOR_MIGRATION, sorted(after)[-5:]))


def test_no_errors_in_log(device):
    log = device.run_ssh('journalctl --no-pager | tail -3000')
    for marker in ['Traceback (most recent call last)', 'django.db.utils']:
        assert marker not in log, [l for l in log.split('\n') if marker in l][:5]
