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
    selenium.find_by(By.CLASS_NAME, "publish-button-label")
    selenium.screenshot('main')


def test_publish_video(selenium):
    selenium.find_by(By.XPATH, "//input[@type='button' and @value='Remind me later']").click()
    selenium.find_by(By.XPATH, "//a[contains(.,'Administration')]")
    selenium.find_by(By.CLASS_NAME, "publish-button-label").click()
    file = selenium.find_by(By.ID, 'videofile')
    selenium.driver.execute_script("Object.values(arguments[0].attributes).filter(({name}) => name.startsWith('_ngcontent')).forEach(({name}) => arguments[0].removeAttribute(name))", file)
    selenium.screenshot('file')
    file.send_keys(join(DIR, 'videos', 'test.mp4'))
    name = selenium.find_by(By.ID, "name")
    name.clear()
    name.send_keys('test video')
    selenium.find_by(By.XPATH, "//div[@class='progress-bar' and contains(.,'100%')]")

    name = selenium.find_by(By.ID, "description")
    name.send_keys('description')

    publish = ".orange-button.action-button"
    selenium.present_by(By.CSS_SELECTOR, publish)
    selenium.clickable_by(By.CSS_SELECTOR, publish)
    # selenium.find_by(By.CSS_SELECTOR, publish).click()
    # selenium.driver.find_element(By.CSS_SELECTOR, 'body').send_keys(Keys.CONTROL + Keys.END)
    selenium.driver.execute_script("document.querySelector('.orange-button.action-button').click()")
    selenium.find_by(By.XPATH, "//h1[contains(.,'test video')]")
    selenium.find_by(By.XPATH, "//div[contains(.,'The video is being transcoded')]")
    selenium.find_by(By.XPATH, "//span[contains(.,'Subscribe')]")
    selenium.screenshot('publish-video')

