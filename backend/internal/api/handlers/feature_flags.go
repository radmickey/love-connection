package handlers

import (
	"love-connection/backend/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetFeatureFlags(c *gin.Context) {
	flags := models.FeatureFlags{
		EnableEmailPasswordAuth: false,
		EnableAppleSignIn:       true,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    flags,
	})
}

