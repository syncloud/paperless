import os
from os.path import dirname, join
from subprocess import check_output
import json

import pytest
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from syncloudlib.http import wait_for_rest
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
import time

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, device, app_dir, artifact_dir):
    def module_teardown():
        device.run_ssh('ls -la /var/snap/paperless/current/config > {0}/config.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/paperless/current/config/webui.yaml {0}/webui.yaml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/paperless/current/config/authelia/config.yml {0}/authelia.config.yml.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/paperless/current/config/authelia/authrequest.conf {0}/authelia.authrequest.conf.log'.format(TMP_DIR), throw=False)
        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl | tail -1000 > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap/paperless > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap > {0}/var.snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/paperless > {0}/var.snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/paperless/current/ > {0}/var.snap.current.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /var/snap/paperless/common > {0}/var.snap.common.ls.log'.format(TMP_DIR),
                       throw=False)
        device.run_ssh('ls -la /data > {0}/data.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /data/paperless > {0}/data.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cat /etc/hosts > {0}/hosts.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cat /var/snap/platform/current/config/authelia/config.yml > {0}/authelia.config.log'.format(TMP_DIR), throw=False)

        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('/var/snap/paperless/common/log/*.log', app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, device_host, app, domain):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100)
    device.run_ssh('mkdir {0}'.format(TMP_DIR))
  

def test_activate_device(device):
    device.run_ssh('snap refresh platform --channel=master')
    device.run_ssh('snap set system refresh.hold=$(date -d "+90 days" -u +%Y-%m-%dT%H:%M:%SZ)')
    response = retry(device.activate_custom)
    assert response.status_code == 200, response.text
    

def test_ca_cert(device, app_domain):
    device.run_ssh('CURL_CA_BUNDLE=/var/snap/platform/current/syncloud.ca.crt curl -v https://{0} 2>&1 > {1}/ssl.ca.log'.format(app_domain, TMP_DIR))


def test_install(app_archive_path, device_host, device_password, device):
    device.run_ssh('touch /var/snap/platform/current/CI_TEST')
    local_install(device_host, device_password, app_archive_path)


def test_index(app_domain):
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def __log_data_dir(device):
    device.run_ssh('ls -la /data')
    device.run_ssh('mount')
    device.run_ssh('ls -la /data/')
    device.run_ssh('ls -la /data/paperless')


def test_consume_pdf(device):
    device.scp_to_device(join(DIR, '..', 'build', 'samples', 'simple.pdf'), '/tmp/simple.pdf')
    device.run_ssh('cp /tmp/simple.pdf /data/paperless/consume/')
    retry(lambda: __check_consumed(device, 'simple'), retries=30)


def test_consume_jpg(device):
    device.scp_to_device(join(DIR, '..', 'build', 'samples', 'simple.jpg'), '/tmp/simple.jpg')
    device.run_ssh('cp /tmp/simple.jpg /data/paperless/consume/')
    retry(lambda: __check_consumed(device, 'simple', expected=2), retries=30)


def __check_consumed(device, name, expected=1):
    result = device.run_ssh("ls /data/paperless/media/documents/originals/", throw=False)
    files = [f for f in result.splitlines() if name in f]
    count = len(files)
    assert count >= expected, 'expected at least {0} documents, got {1}'.format(expected, count)


def test_storage_change_event(device):
    device.run_ssh('snap run paperless.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_access_change_event(device):
    device.run_ssh('snap run paperless.access-change > {0}/access-change.log'.format(TMP_DIR))


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_upgrade(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_index_after_upgrade(app_domain):
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def test_access_change(device, artifact_dir):
    device.run_ssh("snap run paperless.access-change")


def test_backup(device, artifact_dir):
    device.run_ssh("snap run platform.cli backup create paperless")
    response = device.run_ssh("snap run platform.cli backup list")
    open('{0}/cli.backup.list.json'.format(artifact_dir), 'w').write(response)
    print(response)
    backup = json.loads(response)[0]
    device.run_ssh('tar tvf {0}/{1}'.format(backup['path'], backup['file']))
    device.run_ssh("snap run platform.cli backup restore {0}".format(backup['file']))


#def test_sql_plugin(device, artifact_dir):
#    device.run_ssh("snap run paperless.psql -U paperless -d paperless -c 'select * from plugin'", retries=10)


def retry(method, retries=10):
    attempt = 0
    exception = None
    while attempt < retries:
        try:
            return method()
        except Exception as e:
            exception = e
            print('error (attempt {0}/{1}): {2}'.format(attempt + 1, retries, str(e)))
            time.sleep(5)
        attempt += 1
    raise exception

