package api

import (
	"database/sql"
	"love-connection/backend/internal/api/handlers"
	"love-connection/backend/internal/api/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, db *sql.DB) {
	r.Use(middleware.CORS())

	api := r.Group("/api")
	{
		auth := api.Group("/auth")
		{
			authHandler := handlers.NewAuthHandler(db)
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/apple", authHandler.AppleSignIn)
		}

		api.Use(middleware.Auth())
		{
			userHandler := handlers.NewUserHandler(db)
			api.GET("/user/me", userHandler.GetMe)
			api.POST("/user/device-token", userHandler.UpdateDeviceToken)

			pairHandler := handlers.NewPairHandler(db)
			api.POST("/pairs/create", pairHandler.CreatePair)
			api.GET("/pairs/current", pairHandler.GetCurrentPair)

			loveHandler := handlers.NewLoveHandler(db)
			api.POST("/love/send", loveHandler.SendLove)
			api.GET("/love/history", loveHandler.GetHistory)

			statsHandler := handlers.NewStatsHandler(db)
			api.GET("/stats", statsHandler.GetStats)
		}
	}
}

