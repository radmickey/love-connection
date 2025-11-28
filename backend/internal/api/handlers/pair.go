package handlers

import (
	"database/sql"
	"love-connection/backend/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PairHandler struct {
	db *sql.DB
}

func NewPairHandler(db *sql.DB) *PairHandler {
	return &PairHandler{db: db}
}

func (h *PairHandler) CreatePair(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	var req models.CreatePairRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	partnerID, err := uuid.Parse(req.QRCode)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid QR code"})
		return
	}

	if partnerID == currentUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot pair with yourself"})
		return
	}

	var existingPairID uuid.UUID
	err = h.db.QueryRow(
		`SELECT id FROM pairs WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)`,
		currentUserID, partnerID,
	).Scan(&existingPairID)

	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Pair already exists"})
		return
	}

	var user1Exists, user2Exists bool
	err = h.db.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)", currentUserID).Scan(&user1Exists)
	if err != nil || !user1Exists {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Current user not found"})
		return
	}

	err = h.db.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)", partnerID).Scan(&user2Exists)
	if err != nil || !user2Exists {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Partner not found"})
		return
	}

	var pairID uuid.UUID
	err = h.db.QueryRow(
		"INSERT INTO pairs (user1_id, user2_id) VALUES ($1, $2) RETURNING id",
		currentUserID, partnerID,
	).Scan(&pairID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create pair"})
		return
	}

	var pair models.Pair
	var user1, user2 models.User
	err = h.db.QueryRow(
		`SELECT p.id, p.user1_id, p.user2_id, p.created_at,
			u1.id, u1.email, u1.apple_id, u1.username, u1.created_at,
			u2.id, u2.email, u2.apple_id, u2.username, u2.created_at
		FROM pairs p
		JOIN users u1 ON p.user1_id = u1.id
		JOIN users u2 ON p.user2_id = u2.id
		WHERE p.id = $1`,
		pairID,
	).Scan(
		&pair.ID, &pair.User1ID, &pair.User2ID, &pair.CreatedAt,
		&user1.ID, &user1.Email, &user1.AppleID, &user1.Username, &user1.CreatedAt,
		&user2.ID, &user2.Email, &user2.AppleID, &user2.Username, &user2.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pair"})
		return
	}

	pair.User1 = &user1
	pair.User2 = &user2

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    pair,
	})
}

func (h *PairHandler) GetCurrentPair(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	var pair models.Pair
	var user1, user2 models.User
	err := h.db.QueryRow(
		`SELECT p.id, p.user1_id, p.user2_id, p.created_at,
			u1.id, u1.email, u1.apple_id, u1.username, u1.created_at,
			u2.id, u2.email, u2.apple_id, u2.username, u2.created_at
		FROM pairs p
		JOIN users u1 ON p.user1_id = u1.id
		JOIN users u2 ON p.user2_id = u2.id
		WHERE p.user1_id = $1 OR p.user2_id = $1`,
		currentUserID,
	).Scan(
		&pair.ID, &pair.User1ID, &pair.User2ID, &pair.CreatedAt,
		&user1.ID, &user1.Email, &user1.AppleID, &user1.Username, &user1.CreatedAt,
		&user2.ID, &user2.Email, &user2.AppleID, &user2.Username, &user2.CreatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    nil,
		})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pair"})
		return
	}

	pair.User1 = &user1
	pair.User2 = &user2

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    pair,
	})
}

