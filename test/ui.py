import time
from os.path import dirname, join
from subprocess import check_output

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from syncloudlib.integration.hosts import add_host_alias

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
        selenium.log()

    request.addfinalizer(teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    selenium.open_app()
    #selenium.find_by(By.XPATH, "//button[contains(.,'Syncloud')]").click()
    #selenium.find_by(By.XPATH, "//a[contains(.,'My Syncloud')]").click()
    selenium.find_by(By.ID, "username-textfield").send_keys(device_user)
    password = selenium.find_by(By.ID, "password-textfield")
    password.send_keys(device_password)
    selenium.screenshot('login')
    #password.send_keys(Keys.RETURN)
    selenium.find_by(By.ID, "sign-in-button").click()
    selenium.find_by(By.ID, "accept-button").click()
    selenium.find_by(By.XPATH, "//button[contains(.,'Sign up')]").click()
    selenium.find_by(By.XPATH, "//h4[contains(.,'Paperless-ngx is running!')]")
    selenium.screenshot('main')

def test_upload(selenium):
    file = selenium.find_by(By.XPATH, "//input[@type='file']")
    selenium.driver.execute_script("arguments[0].removeAttribute('class')", file)
    file.send_keys(join(DIR, '..', 'paperless', 'sample.pdf'))
    assert not selenium.exist_by(By.XPATH, "//p[contains(.,'not supported')]")
    selenium.screenshot('uploaded')
