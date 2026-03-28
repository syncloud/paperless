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


def test_check_pdf(selenium):
    lib.check_document_list_2_20(selenium, 'pdf')


def test_check_jpg(selenium):
    lib.check_document_list_2_20(selenium, 'jpg')


def test_regular_user_login(device, selenium, app, domain, device_host):
    device.activated()
    device.run_ssh('snap run platform.cli user add regularuser --password=regularpass123')
    selenium.driver.delete_all_cookies()
    selenium.open_app()
    selenium.find_by(By.ID, "username-textfield").send_keys("regularuser")
    selenium.find_by(By.ID, "password-textfield").send_keys("regularpass123")
    selenium.find_by(By.ID, "sign-in-button").click()
    selenium.find_by(By.XPATH, "//button[contains(.,'Sign up')]").click()
    selenium.find_by(By.XPATH, "//h4[contains(.,'Paperless-ngx is running!')]")
    selenium.screenshot('regular-user-dashboard')
