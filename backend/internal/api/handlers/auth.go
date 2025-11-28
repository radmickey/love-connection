package handlers

import (
	"database/sql"
	"love-connection/backend/internal/models"
	"love-connection/backend/internal/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AuthHandler struct {
	db *sql.DB
}

func NewAuthHandler(db *sql.DB) *AuthHandler {
	return &AuthHandler{db: db}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := services.ValidateRegisterRequest(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	passwordHash, err := services.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	var userID uuid.UUID
	err = h.db.QueryRow(
		"INSERT INTO users (email, username, password_hash) VALUES ($1, $2, $3) RETURNING id",
		req.Email, req.Username, passwordHash,
	).Scan(&userID)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email or username already exists"})
		return
	}

	token, err := services.GenerateToken(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	var user models.User
	err = h.db.QueryRow(
		"SELECT id, email, username, created_at FROM users WHERE id = $1",
		userID,
	).Scan(&user.ID, &user.Email, &user.Username, &user.CreatedAt)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user"})
		return
	}

	authResponse := models.AuthResponse{
		Token: token,
		User:  user,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    authResponse,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	var passwordHash string
	err := h.db.QueryRow(
		"SELECT id, email, username, password_hash, created_at FROM users WHERE email = $1",
		req.Email,
	).Scan(&user.ID, &user.Email, &user.Username, &passwordHash, &user.CreatedAt)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	if !services.CheckPasswordHash(req.Password, passwordHash) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	token, err := services.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	authResponse := models.AuthResponse{
		Token: token,
		User:  user,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    authResponse,
	})
}

func (h *AuthHandler) AppleSignIn(c *gin.Context) {
	var req models.AppleSignInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	var userID uuid.UUID

	err := h.db.QueryRow(
		"SELECT id, email, apple_id, username, created_at FROM users WHERE apple_id = $1",
		req.UserIdentifier,
	).Scan(&user.ID, &user.Email, &user.AppleID, &user.Username, &user.CreatedAt)

	if err == sql.ErrNoRows {
		username := "User"
		if req.Username != nil && *req.Username != "" {
			username = *req.Username
		}

		err = h.db.QueryRow(
			"INSERT INTO users (apple_id, username) VALUES ($1, $2) RETURNING id",
			req.UserIdentifier, username,
		).Scan(&userID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user: " + err.Error()})
			return
		}

		err = h.db.QueryRow(
			"SELECT id, email, apple_id, username, created_at FROM users WHERE id = $1",
			userID,
		).Scan(&user.ID, &user.Email, &user.AppleID, &user.Username, &user.CreatedAt)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user: " + err.Error()})
			return
		}
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error: " + err.Error()})
		return
	}

	token, err := services.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	authResponse := models.AuthResponse{
		Token: token,
		User:  user,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    authResponse,
	})
}

