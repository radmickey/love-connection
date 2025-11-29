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

		// Создаем HTML страницу, которая откроет deep link
		deepLink := "loveconnection://add?username=" + url.QueryEscape(username)
		html := `<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Open in Love Connection</title>
	<style>
		body {
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
			display: flex;
			justify-content: center;
			align-items: center;
			min-height: 100vh;
			margin: 0;
			background: linear-gradient(135deg, #ffeef5 0%, #fff5f8 50%, #ffffff 100%);
		}
		.container {
			text-align: center;
			padding: 40px;
			background: white;
			border-radius: 20px;
			box-shadow: 0 10px 40px rgba(0,0,0,0.1);
			max-width: 400px;
		}
		.heart {
			font-size: 60px;
			margin-bottom: 20px;
		}
		h1 {
			color: #333;
			margin-bottom: 10px;
		}
		p {
			color: #666;
			margin-bottom: 30px;
		}
		.button {
			display: inline-block;
			padding: 15px 30px;
			background: linear-gradient(135deg, #ff6b9d 0%, #ff8fab 100%);
			color: white;
			text-decoration: none;
			border-radius: 25px;
			font-weight: 600;
			transition: transform 0.2s;
		}
		.button:hover {
			transform: scale(1.05);
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
		<p>Connecting you with <strong>` + username + `</strong></p>
		<a href="` + deepLink + `" class="button" id="openApp">Open App</a>
	</div>
	<script>
		// Попытка автоматически открыть deep link
		setTimeout(function() {
			window.location.href = "` + deepLink + `";
		}, 100);

		// Если через 2 секунды не открылось, показываем кнопку
		setTimeout(function() {
			document.getElementById('openApp').style.display = 'inline-block';
		}, 2000);
	</script>
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
