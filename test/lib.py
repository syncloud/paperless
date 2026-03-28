from os.path import dirname, join
from selenium.webdriver.common.by import By

DIR = dirname(__file__)


def login_2_20(selenium, device_user, device_password, new_user=True):
    if not new_user:
        selenium.driver.delete_all_cookies()
    selenium.open_app()
    selenium.find_by(By.ID, "username-textfield").send_keys(device_user)
    password = selenium.find_by(By.ID, "password-textfield")
    password.send_keys(device_password)
    selenium.screenshot('login')
    selenium.find_by(By.ID, "sign-in-button").click()
    if new_user:
        selenium.find_by(By.XPATH, "//button[contains(.,'Sign up')]").click()
    selenium.find_by(By.XPATH, "//h4[contains(.,'Paperless-ngx is running!')]")
    selenium.screenshot('main')


def upload_document_2_20(selenium, mode):
    selenium.open_app()
    file = selenium.find_by(By.XPATH, "//input[@type='file']")
    selenium.driver.execute_script("arguments[0].removeAttribute('class')", file)
    file.clear()
    file.send_keys(join(DIR, '..', 'build', 'samples', 'simple.pdf'))
    selenium.invisible_by(By.XPATH, "//p[contains(.,'Upload complete, waiting...')]")
    selenium.find_by(By.XPATH, "//span[contains(.,'Dismiss completed')]")
    selenium.screenshot('uploaded-{0}'.format(mode))


def check_document_list_2_20(selenium, mode):
    selenium.find_by(By.XPATH, "//a[@href='/documents']").click()
    selenium.find_by(By.XPATH, "//pngx-document-card-small")
    selenium.screenshot('documents-{0}'.format(mode))
