package api

import (
	"database/sql"
	"net/http"
	"net/url"
	"love-connection/backend/internal/api/handlers"
	"love-connection/backend/internal/api/middleware"
	"love-connection/backend/internal/websocket"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func SetupRoutes(r *gin.Engine, db *sql.DB, hub *websocket.Hub) {
	r.Use(middleware.CORS())

	go hub.Run()

	healthHandler := handlers.NewHealthHandler(db)
	r.GET("/health", healthHandler.HealthCheck)
	r.GET("/api/feature-flags", handlers.GetFeatureFlags)

	// Endpoint для редиректа на deep link при переходе по invite ссылке
	r.GET("/add", func(c *gin.Context) {
		username := c.Query("username")
		if username == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Username parameter is required"})
			return
		}
		// Редиректим на deep link для открытия приложения
		deepLink := "loveconnection://add?username=" + url.QueryEscape(username)
		c.Redirect(http.StatusFound, deepLink)
	})

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
			api.PATCH("/user/me", userHandler.UpdateMe)
			api.POST("/user/device-token", userHandler.UpdateDeviceToken)
			api.GET("/user/search", userHandler.SearchUser)
			api.GET("/user/invite-link", userHandler.GenerateInviteLink)

			pairHandler := handlers.NewPairHandler(db)
			api.POST("/pairs/request", pairHandler.CreatePairRequest)
			api.POST("/pairs/respond", pairHandler.RespondPairRequest)
			api.GET("/pairs/requests", pairHandler.GetPairRequests)
			api.GET("/pairs/current", pairHandler.GetCurrentPair)
			api.DELETE("/pairs/current", pairHandler.DeletePair)

			loveHandler := handlers.NewLoveHandler(db, hub)
			api.POST("/love/send", loveHandler.SendLove)
			api.GET("/love/history", loveHandler.GetHistory)

			statsHandler := handlers.NewStatsHandler(db)
			api.GET("/stats", statsHandler.GetStats)
		}
	}

	wsGroup := r.Group("/ws")
	wsGroup.Use(middleware.Auth())
	{
		wsGroup.GET("", func(c *gin.Context) {
			userID, _ := c.Get("user_id")
			hub.HandleWebSocket(c.Writer, c.Request, userID.(uuid.UUID))
		})
	}
}
