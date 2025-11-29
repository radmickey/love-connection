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

	// Universal Links: Apple App Site Association file
	// Важно: файл должен быть доступен по HTTPS без расширения .json
	r.GET("/.well-known/apple-app-site-association", func(c *gin.Context) {
		// Apple требует Content-Type: application/json без charset
		c.Header("Content-Type", "application/json")
		c.String(http.StatusOK, `{
	"applinks": {
		"apps": [],
		"details": [
			{
				"appID": "UG4928G289.radmickey.CoupleLoveConnection",
				"paths": ["/add*"]
			}
		]
	}
}`)
	})

	// Endpoint для редиректа на deep link при переходе по invite ссылке
	r.GET("/add", func(c *gin.Context) {
		username := c.Query("username")
		if username == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Username parameter is required"})
			return
		}

		// Создаем HTML страницу, которая откроет deep link
		// Используем Universal Link (HTTPS) вместо custom URL scheme
		universalLink := "https://love-couple-connect.duckdns.org/add?username=" + url.QueryEscape(username)
		html := `<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Open in Love Connection</title>
	<style>
		* {
			margin: 0;
			padding: 0;
			box-sizing: border-box;
		}
		body {
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
			display: flex;
			justify-content: center;
			align-items: center;
			min-height: 100vh;
			margin: 0;
			background: linear-gradient(135deg, #ffeef5 0%, #fff5f8 50%, #ffffff 100%);
			padding: 20px;
		}
		.container {
			text-align: center;
			padding: 40px 30px;
			background: white;
			border-radius: 20px;
			box-shadow: 0 10px 40px rgba(0,0,0,0.1);
			max-width: 400px;
			width: 100%;
		}
		.heart {
			font-size: 60px;
			margin-bottom: 20px;
		}
		h1 {
			color: #333;
			margin-bottom: 10px;
			font-size: 24px;
		}
		p {
			color: #666;
			margin-bottom: 30px;
			font-size: 16px;
			line-height: 1.5;
		}
		.username {
			color: #ff6b9d;
			font-weight: 600;
		}
		.button {
			display: inline-block;
			padding: 15px 30px;
			background: linear-gradient(135deg, #ff6b9d 0%, #ff8fab 100%);
			color: white;
			text-decoration: none;
			border-radius: 25px;
			font-weight: 600;
			font-size: 16px;
			transition: transform 0.2s, box-shadow 0.2s;
			box-shadow: 0 4px 15px rgba(255, 107, 157, 0.3);
		}
		.button:hover {
			transform: scale(1.05);
			box-shadow: 0 6px 20px rgba(255, 107, 157, 0.4);
		}
		.button:active {
			transform: scale(0.95);
		}
	</style>
</head>
<body>
	<div class="container">
		<div class="heart">💕</div>
		<h1>Open in Love Connection</h1>
		<p>Connecting you with <span class="username">` + username + `</span></p>
		<a href="` + universalLink + `" class="button" style="text-decoration: none; border: none; cursor: pointer; display: inline-block;">Open App</a>
		<p style="margin-top: 20px; font-size: 14px; color: #999;">If the app doesn't open automatically, tap the button above.</p>
	</div>
</body>
</html>`
		c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(html))
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
