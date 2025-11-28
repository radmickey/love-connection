package main

import (
	"log"
	"love-connection/backend/internal/api"
	"love-connection/backend/internal/database"
	"love-connection/backend/internal/websocket"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	db, err := database.Connect()
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	if err := database.RunMigrations(db); err != nil {
		log.Fatal("Failed to run migrations:", err)
	}

	hub := websocket.NewHub()
	r := gin.Default()

	api.SetupRoutes(r, db, hub)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

