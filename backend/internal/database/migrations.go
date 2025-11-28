package database

import (
	"database/sql"
	"embed"
	"io/fs"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

func RunMigrations(db *sql.DB) error {
	migrations, err := fs.ReadDir(migrationsFS, "migrations")
	if err != nil {
		return err
	}

	for _, migration := range migrations {
		if migration.IsDir() {
			continue
		}

		content, err := migrationsFS.ReadFile("migrations/" + migration.Name())
		if err != nil {
			return err
		}

		if _, err := db.Exec(string(content)); err != nil {
			return err
		}
	}

	return nil
}

