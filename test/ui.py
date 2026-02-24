from os.path import dirname, join
from subprocess import check_output

import pytest
from selenium.webdriver.common.by import By
from syncloudlib.integration.hosts import add_host_alias

from test import lib

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode, driver, selenium):
    def teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('cat /var/snap/platform/current/config/authelia/config.yml > {0}/authelia.config.ui.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    lib.login_2_20(selenium, device_user, device_password)


def test_upload_pdf(selenium):
    lib.upload_document_2_20(selenium, 'pdf')


def test_upload_jpg(selenium):
    selenium.open_app()
    file = selenium.find_by(By.XPATH, "//input[@type='file']")
    selenium.driver.execute_script("arguments[0].removeAttribute('class')", file)
    file.clear()
    file.send_keys(join(DIR, '..', 'build', 'samples', 'simple.jpg'))
    selenium.invisible_by(By.XPATH, "//p[contains(.,'Upload complete, waiting...')]")
    selenium.find_by(By.XPATH, "//span[contains(.,'Dismiss completed')]")
    selenium.screenshot('uploaded-jpg')
