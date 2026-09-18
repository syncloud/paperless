import pytest
import requests
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest

TMP_DIR = '/tmp/syncloud'
V3_FLOOR_MIGRATION = '1075_workflowaction_order'
V3_SQUASHED_MIGRATIONS = ['0001_squashed', '0002_squashed']
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
        "snap run paperless.psql -U paperless -d paperless -t -A -c '{0}'".format(sql))


def document_count(device):
    out = psql(device, 'select count(*) from documents_document')
    for line in reversed(out.strip().split('\n')):
        line = line.strip()
        if line.isdigit():
            return int(line)
    raise AssertionError('no row count in psql output: {0}'.format(out))


def applied_migrations(device):
    out = psql(device, 'select app, name from django_migrations')
    applied = set()
    for line in out.split('\n'):
        parts = line.strip().split('|')
        if len(parts) == 2 and parts[0] == 'documents':
            applied.add(parts[1])
    return applied


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


def test_v3_precondition_met_before_upgrade():
    assert V3_FLOOR_MIGRATION in BEFORE['migrations'], (
        'v3 refuses to start unless {0} is applied. The store version must already '
        'carry it for a one step upgrade to be legal. Applied tail: {1}'.format(
            V3_FLOOR_MIGRATION, sorted(BEFORE['migrations'])[-5:]))


def test_v3_squash_applied(device):
    after = applied_migrations(device)
    squashed = [m for m in V3_SQUASHED_MIGRATIONS if m in after]
    assert squashed, (
        'no v3 squashed migration recorded, so the database never reached the v3 '
        'schema. Applied tail: {0}'.format(sorted(after)[-5:]))


def test_services_running_after_upgrade(device):
    out = device.run_ssh('snap services paperless')
    rows = [line.split() for line in out.strip().split('\n')[1:] if line.strip()]
    not_active = [row[0] for row in rows if len(row) >= 3 and row[2] != 'active']
    assert not not_active, (not_active, out)
