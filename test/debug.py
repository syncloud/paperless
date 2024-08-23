from os.path import dirname, join

from selenium import webdriver
from syncloudlib.integration.selenium_wrapper import SeleniumWrapper

from test.ui import test_publish_video, test_login

DIR = dirname(__file__)


def test_chrome():
    # sudo docker run -d --name chrome --network ip6net -p 4444:4444 -p 5900:5900 -p 7900:7900 --shm-size="2g" selenium/standalone-chrome:4.21.0-20240517
    # firefox http://localhost:7900
    # password: secret

    options = webdriver.ChromeOptions()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.set_capability('goog:loggingPrefs', {'performance': 'ALL'})
    options.set_capability('acceptInsecureCerts', True)
    driver = webdriver.Remote(options=options)
    driver.maximize_window()
    selenium = SeleniumWrapper(
        driver,
        "desktop",
        join(DIR, "artifact"),
        "example.com",
        100,
        "chrome"
    )

    try:
        test_login(selenium, "test", "test1234")
        test_publish_video(selenium)
    finally:
        print()
        selenium.log()
        driver.quit()
