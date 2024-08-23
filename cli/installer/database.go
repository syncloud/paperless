package installer

import (
	"errors"
	"fmt"
	cp "github.com/otiai10/copy"
	"go.uber.org/zap"
	"os"
	"os/exec"
	"path"
)

type Database struct {
	appDir      string
	dataDir     string
	configPath  string
	user        string
	backupFile  string
	databaseDir string
	executor    *Executor
	logger      *zap.Logger
}

func NewDatabase(
	appDir string,
	dataDir string,
	configPath string,
	user string,
	executor *Executor,
	logger *zap.Logger,
) *Database {
	return &Database{
		appDir:      appDir,
		dataDir:     dataDir,
		configPath:  configPath,
		user:        user,
		backupFile:  path.Join(dataDir, "database.dump"),
		databaseDir: path.Join(dataDir, "database"),
		executor:    executor,
		logger:      logger,
	}
}

func (d *Database) DatabaseDir() string {
	return d.databaseDir
}

func (d *Database) Remove() error {
	if _, err := os.Stat(d.backupFile); errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("backup file does not exist: %s", d.backupFile)
	}
	_ = os.RemoveAll(d.databaseDir)
	return nil
}

func (d *Database) Init() error {
	cmd := exec.Command(fmt.Sprintf("%s/bin/initdb.sh", d.appDir), d.databaseDir)
	out, err := cmd.CombinedOutput()
	d.logger.Info(cmd.String(), zap.ByteString("output", out))
	if err != nil {
		d.logger.Error(cmd.String(), zap.String("error", "failed to init database"))
	}
	return err
}

func (d *Database) InitConfig() error {
	return cp.Copy(
		path.Join(d.configPath, "postgresql.conf"),
		path.Join(d.databaseDir, "postgresql.conf"),
	)
}

func (d *Database) Execute(database string, sql string) error {
	return d.executor.Run("snap",
		"run", "paperless.psql",
		"-U", d.user,
		"-d", database,
		"-c", sql,
	)
}

func (d *Database) Restore() error {
	return d.executor.Run("snap",
		"run", "paperless.psql",
		"-f", d.backupFile,
		"postgres",
	)
}

func (d *Database) Backup() error {
	return d.executor.Run("snap",
		"run", "paperless.pgdumpall",
		"-f", d.backupFile,
	)
}

func (d *Database) createDbIfMissing(db string) error {
	err := d.Execute(db, "select 1")
	if err != nil {
		d.logger.Info("database does not exist, will try to create", zap.String("db", db))
		err = d.Execute(
			"postgres",
			fmt.Sprintf("CREATE DATABASE %s OWNER %s TEMPLATE template0 ENCODING 'UTF8'", db, d.user),
		)
		if err != nil {
			d.logger.Error("error creating db", zap.Error(err))
			return err
		}
	}
	d.logger.Info("database already exists", zap.String("db", db))
	return nil
}
