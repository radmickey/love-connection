package handlers

import (
	"database/sql"
	"love-connection/backend/internal/models"
	"net/http"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserHandler struct {
	db *sql.DB
}

func NewUserHandler(db *sql.DB) *UserHandler {
	return &UserHandler{db: db}
}

func (h *UserHandler) GetMe(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uuid.UUID)

	var user models.User
	err := h.db.QueryRow(
		"SELECT id, email, apple_id, username, created_at FROM users WHERE id = $1",
		uid,
	).Scan(&user.ID, &user.Email, &user.AppleID, &user.Username, &user.CreatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

func (h *UserHandler) UpdateDeviceToken(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uuid.UUID)

	var req struct {
		DeviceToken string `json:"device_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := h.db.Exec(
		"UPDATE users SET device_token = $1 WHERE id = $2",
		req.DeviceToken, uid,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update device token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *UserHandler) UpdateMe(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uuid.UUID)

	var req struct {
		Username string `json:"username" binding:"required,min=1,max=12"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Trim whitespace and validate
	req.Username = strings.TrimSpace(req.Username)
	if req.Username == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username cannot be empty or only whitespace"})
		return
	}

	// Check for spaces
	if strings.Contains(req.Username, " ") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username cannot contain spaces"})
		return
	}

	if len(req.Username) < 3 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username must be at least 3 characters"})
		return
	}

	if len(req.Username) > 12 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username must be 12 characters or less"})
		return
	}

	// Validate format: starts with letter, only alphanumeric
	// Pattern: ^[a-zA-Z][a-zA-Z0-9]*$
	if len(req.Username) == 0 || !((req.Username[0] >= 'a' && req.Username[0] <= 'z') || (req.Username[0] >= 'A' && req.Username[0] <= 'Z')) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username must start with a letter"})
		return
	}

	for _, char := range req.Username {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9')) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Username can only contain letters and numbers"})
			return
		}
	}

	// Проверяем, не занят ли username другим пользователем
	var existingUserID uuid.UUID
	err := h.db.QueryRow(
		"SELECT id FROM users WHERE username = $1 AND id != $2",
		req.Username, uid,
	).Scan(&existingUserID)

	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username already taken"})
		return
	} else if err != sql.ErrNoRows {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check username availability"})
		return
	}

	_, err = h.db.Exec(
		"UPDATE users SET username = $1 WHERE id = $2",
		req.Username, uid,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update username"})
		return
	}

	var user models.User
	err = h.db.QueryRow(
		"SELECT id, email, apple_id, username, created_at FROM users WHERE id = $1",
		uid,
	).Scan(&user.ID, &user.Email, &user.AppleID, &user.Username, &user.CreatedAt)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch updated user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

func (h *UserHandler) SearchUser(c *gin.Context) {
	username := strings.TrimSpace(c.Query("username"))
	if username == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username parameter is required"})
		return
	}

	var user models.User
	err := h.db.QueryRow(
		"SELECT id, email, apple_id, username, created_at FROM users WHERE username = $1",
		username,
	).Scan(&user.ID, &user.Email, &user.AppleID, &user.Username, &user.CreatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search user"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

func (h *UserHandler) GenerateInviteLink(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uuid.UUID)

	var user models.User
	err := h.db.QueryRow(
		"SELECT id, username FROM users WHERE id = $1",
		uid,
	).Scan(&user.ID, &user.Username)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get user"})
		return
	}

	// Генерируем HTTP ссылку, которая будет открывать приложение через редирект
	// Формат: https://love-couple-connect.duckdns.org/add?username=...
	// При переходе по этой ссылке бэкенд редиректит на deep link loveconnection://add?username=...
	baseURL := "https://love-couple-connect.duckdns.org"
	inviteLink := baseURL + "/add?username=" + url.QueryEscape(user.Username)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"link":     inviteLink,
			"username": user.Username,
		},
	})
}

