import pytest
from subprocess import check_output, run
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest
import requests
from test import lib

TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir):
    def module_teardown():
        device.run_ssh('journalctl > {0}/upgrade.journalctl.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), artifact_dir)
        run('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, device_host, domain, device):
    add_host_alias(app, device_host, domain)
    device.activated()
    device.run_ssh('rm -rf {0}'.format(TMP_DIR), throw=False)
    device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)


def test_install_from_store(device, app_domain):
    device.run_ssh('snap remove paperless')
    device.run_ssh('snap install paperless', retries=10)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_login_pre_upgrade(selenium, device_user, device_password):
    lib.login_2_20(selenium, device_user, device_password)


def test_upgrade(device_host, device_password, app_archive_path, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_login_post_upgrade(selenium, device_user, device_password):
    lib.login_2_20(selenium, device_user, device_password, new_user=False)


def test_check_post_upgrade_data(selenium):
    lib.check_document_list_2_20(selenium, 'post-check')


def test_upload_post_upgrade(selenium):
    lib.upload_document_2_20(selenium, 'post')
