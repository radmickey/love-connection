package database

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/lib/pq"
)

func Connect() (*sql.DB, error) {
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "localhost"
	}

	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}

	user := os.Getenv("DB_USER")
	if user == "" {
		user = "postgres"
	}

	password := os.Getenv("DB_PASSWORD")
	if password == "" {
		password = "postgres"
	}

	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "loveconnection"
	}

	sslmode := os.Getenv("DB_SSLMODE")
	if sslmode == "" {
		sslmode = "disable"
	}

	// First, try to connect to the target database
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		host, port, user, password, dbname, sslmode)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	// Try to ping the database
	if err := db.Ping(); err != nil {
		// If database doesn't exist, try to create it
		db.Close()

		// Connect to default postgres database to create the target database
		defaultDSN := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=postgres sslmode=%s",
			host, port, user, password, sslmode)

		defaultDB, err := sql.Open("postgres", defaultDSN)
		if err != nil {
			return nil, fmt.Errorf("failed to connect to postgres database: %w", err)
		}
		defer defaultDB.Close()

		// Check if database exists
		var exists int
		checkQuery := fmt.Sprintf("SELECT 1 FROM pg_database WHERE datname = '%s'", dbname)
		err = defaultDB.QueryRow(checkQuery).Scan(&exists)

		if err == sql.ErrNoRows {
			// Database doesn't exist, create it
			createQuery := fmt.Sprintf("CREATE DATABASE %s", dbname)
			_, err = defaultDB.Exec(createQuery)
			if err != nil {
				return nil, fmt.Errorf("failed to create database: %w", err)
			}
		} else if err != nil {
			return nil, fmt.Errorf("failed to check database existence: %w", err)
		}

		// Now connect to the newly created (or existing) database
		db, err = sql.Open("postgres", dsn)
		if err != nil {
			return nil, err
		}

		if err := db.Ping(); err != nil {
			return nil, fmt.Errorf("failed to connect to database after creation: %w", err)
		}
	}

	return db, nil
}

