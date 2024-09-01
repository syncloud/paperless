package installer

import (
	"fmt"
	"github.com/google/uuid"
	cp "github.com/otiai10/copy"
	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"

	"os"
	"path"
)

const (
	App       = "paperless"
	AppDir    = "/snap/paperless/current"
	DataDir   = "/var/snap/paperless/current"
	CommonDir = "/var/snap/paperless/common"
)

type Variables struct {
	Domain      string
	Secret      string
	DatabaseDir string
	DataDir     string
	AppDir      string
	CommonDir   string
	Url         string
	OIDCConfig  string
}

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	configDir          string
	platformClient     *platform.Client
	database           *Database
	installFile        string
	executor           *Executor
	logger             *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	configDir := path.Join(DataDir, "config")

	executor := NewExecutor(logger)
	return &Installer{
		newVersionFile:     path.Join(AppDir, "version"),
		currentVersionFile: path.Join(DataDir, "version"),
		configDir:          configDir,
		platformClient:     platform.New(),
		database:           NewDatabase(AppDir, DataDir, configDir, App, executor, logger),
		installFile:        path.Join(CommonDir, "installed"),
		executor:           executor,
		logger:             logger,
	}
}

func (i *Installer) Install() error {

	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.database.Init()
	if err != nil {
		return err
	}
	err = i.database.InitConfig()
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) Configure() error {
	if i.IsInstalled() {
		err := i.Upgrade()
		if err != nil {
			return err
		}
	} else {
		err := i.Initialize()
		if err != nil {
			return err
		}
	}

	err := linux.CreateMissingDirs(
		path.Join(DataDir, "tmp"),
	)
	if err != nil {
		return err
	}

	err = i.executor.Run(fmt.Sprint(AppDir, "/bin/configure.sh"))
	if err != nil {
		return err
	}

	return i.UpdateVersion()
}

func (i *Installer) IsInstalled() bool {
	_, err := os.Stat(i.installFile)
	return os.IsExist(err)
}

func (i *Installer) Initialize() error {
	err := i.StorageChange()
	if err != nil {
		return err
	}

	err = i.database.Execute(
		"postgres",
		fmt.Sprintf("ALTER USER %s WITH PASSWORD '%s'", App, App),
	)
	if err != nil {
		return err
	}
	err = i.database.createDbIfMissing(App)
	if err != nil {
		return err
	}
	err = i.database.Execute("postgres", fmt.Sprintf("GRANT CREATE ON SCHEMA public TO %s", App))
	if err != nil {
		return err
	}
	err = os.WriteFile(i.installFile, []byte("installed"), 0644)
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) Upgrade() error {
	err := i.database.Restore()
	if err != nil {
		return err
	}
	err = i.StorageChange()
	if err != nil {
		return err
	}
	err = i.database.createDbIfMissing(App)
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) PreRefresh() error {
	return i.database.Backup()
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}
	err = i.database.Remove()
	if err != nil {
		return err
	}
	err = i.database.Init()
	if err != nil {
		return err
	}
	err = i.database.InitConfig()
	if err != nil {
		return err
	}

	err = i.ClearVersion()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}
	return nil

}
func (i *Installer) AccessChange() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) StorageChange() error {
	storageDir, err := i.platformClient.InitStorage(App, App)
	if err != nil {
		return err
	}
	err = linux.CreateMissingDirs(
		path.Join(storageDir, "data/log"),
		path.Join(storageDir, "consume"),
		path.Join(storageDir, "media"),
		path.Join(storageDir, "static"),
		path.Join(storageDir, "trash"),
	)
	if err != nil {
		return err
	}
	err = linux.Chown(storageDir, App)
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) UpdateVersion() error {
	return cp.Copy(i.newVersionFile, i.currentVersionFile)
}

func (i *Installer) UpdateConfigs() error {
	err := linux.CreateUser(App)
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}

	domain, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}

	url, err := i.platformClient.GetAppUrl(App)
	if err != nil {
		return err
	}

	secret, err := getOrCreateUuid(path.Join(DataDir, "paperless.secret"))
	if err != nil {
		return err
	}

	authUrl, err := i.platformClient.GetAppUrl("auth")
	if err != nil {
		return err
	}

	password, err := i.platformClient.RegisterOIDCClient(App, "/accounts/authelia/login/callback/", false, "client_secret_basic")
	if err != nil {
		return err
	}

	oidcConfig, err := OpenIDConfig(authUrl, App, password)
	if err != nil {
		return err
	}

	variables := Variables{
		Domain:      domain,
		Secret:      secret,
		DatabaseDir: i.database.DatabaseDir(),
		DataDir:     DataDir,
		AppDir:      AppDir,
		CommonDir:   CommonDir,
		Url:         url,
		OIDCConfig:  oidcConfig,
	}

	err = config.Generate(
		path.Join(AppDir, "config"),
		path.Join(DataDir, "config"),
		variables,
	)
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	return nil

}

func (i *Installer) FixPermissions() error {
	err := linux.Chown(DataDir, App)
	if err != nil {
		return err
	}
	err = linux.Chown(CommonDir, App)
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) BackupPreStop() error {
	return i.PreRefresh()
}

func (i *Installer) RestorePreStart() error {
	return i.PostRefresh()
}

func (i *Installer) RestorePostStart() error {
	return i.Configure()
}

func getOrCreateUuid(file string) (string, error) {
	_, err := os.Stat(file)
	if os.IsNotExist(err) {
		secret := uuid.New().String()
		err = os.WriteFile(file, []byte(secret), 0644)
		return secret, err
	}
	content, err := os.ReadFile(file)
	if err != nil {
		return "", err
	}
	return string(content), nil
}
