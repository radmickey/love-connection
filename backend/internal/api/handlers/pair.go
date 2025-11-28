package handlers

import (
	"database/sql"
	"love-connection/backend/internal/models"
	"love-connection/backend/internal/services"
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

func (h *PairHandler) CreatePairRequest(c *gin.Context) {
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

	var existingRequestID uuid.UUID
	err = h.db.QueryRow(
		`SELECT id FROM pair_requests
		WHERE ((requester_id = $1 AND requested_id = $2) OR (requester_id = $2 AND requested_id = $1))
		AND status = 'pending'`,
		currentUserID, partnerID,
	).Scan(&existingRequestID)

	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Pair request already exists"})
		return
	}

	var user2Exists bool
	var requestedUsername string
	err = h.db.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM users WHERE id = $1), (SELECT username FROM users WHERE id = $1)",
		partnerID,
	).Scan(&user2Exists, &requestedUsername)

	if err != nil || !user2Exists {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User not found"})
		return
	}

	var requesterUsername string
	err = h.db.QueryRow("SELECT username FROM users WHERE id = $1", currentUserID).Scan(&requesterUsername)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get requester info"})
		return
	}

	var requestID uuid.UUID
	err = h.db.QueryRow(
		"INSERT INTO pair_requests (requester_id, requested_id, status) VALUES ($1, $2, 'pending') RETURNING id",
		currentUserID, partnerID,
	).Scan(&requestID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create pair request"})
		return
	}

	var pairRequest models.PairRequest
	var requester, requested models.User
	err = h.db.QueryRow(
		`SELECT pr.id, pr.requester_id, pr.requested_id, pr.status, pr.created_at, pr.updated_at,
			u1.id, u1.email, u1.apple_id, u1.username, u1.created_at,
			u2.id, u2.email, u2.apple_id, u2.username, u2.created_at
		FROM pair_requests pr
		JOIN users u1 ON pr.requester_id = u1.id
		JOIN users u2 ON pr.requested_id = u2.id
		WHERE pr.id = $1`,
		requestID,
	).Scan(
		&pairRequest.ID, &pairRequest.RequesterID, &pairRequest.RequestedID, &pairRequest.Status, &pairRequest.CreatedAt, &pairRequest.UpdatedAt,
		&requester.ID, &requester.Email, &requester.AppleID, &requester.Username, &requester.CreatedAt,
		&requested.ID, &requested.Email, &requested.AppleID, &requested.Username, &requested.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pair request"})
		return
	}

	pairRequest.Requester = &requester
	pairRequest.Requested = &requested

	go services.SendPairRequestNotification(h.db, partnerID, requesterUsername)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    pairRequest,
	})
}

func (h *PairHandler) RespondPairRequest(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	var req models.RespondPairRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var pairRequest models.PairRequest
	var requester, requested models.User
	err := h.db.QueryRow(
		`SELECT pr.id, pr.requester_id, pr.requested_id, pr.status, pr.created_at, pr.updated_at,
			u1.id, u1.email, u1.apple_id, u1.username, u1.created_at,
			u2.id, u2.email, u2.apple_id, u2.username, u2.created_at
		FROM pair_requests pr
		JOIN users u1 ON pr.requester_id = u1.id
		JOIN users u2 ON pr.requested_id = u2.id
		WHERE pr.id = $1 AND pr.requested_id = $2 AND pr.status = 'pending'`,
		req.RequestID, currentUserID,
	).Scan(
		&pairRequest.ID, &pairRequest.RequesterID, &pairRequest.RequestedID, &pairRequest.Status, &pairRequest.CreatedAt, &pairRequest.UpdatedAt,
		&requester.ID, &requester.Email, &requester.AppleID, &requester.Username, &requester.CreatedAt,
		&requested.ID, &requested.Email, &requested.AppleID, &requested.Username, &requested.CreatedAt,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pair request not found"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pair request"})
		return
	}

	newStatus := "rejected"
	if req.Accept {
		newStatus = "accepted"
	}

	_, err = h.db.Exec(
		"UPDATE pair_requests SET status = $1, updated_at = NOW() WHERE id = $2",
		newStatus, req.RequestID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update pair request"})
		return
	}

	if req.Accept {
		var pairID uuid.UUID
		err = h.db.QueryRow(
			"INSERT INTO pairs (user1_id, user2_id) VALUES ($1, $2) RETURNING id",
			pairRequest.RequesterID, pairRequest.RequestedID,
		).Scan(&pairID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create pair"})
			return
		}

		var pair models.Pair
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
			&requester.ID, &requester.Email, &requester.AppleID, &requester.Username, &requester.CreatedAt,
			&requested.ID, &requested.Email, &requested.AppleID, &requested.Username, &requested.CreatedAt,
		)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pair"})
			return
		}

		pair.User1 = &requester
		pair.User2 = &requested

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    pair,
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Pair request rejected",
		})
	}
}

func (h *PairHandler) GetPairRequests(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	rows, err := h.db.Query(
		`SELECT pr.id, pr.requester_id, pr.requested_id, pr.status, pr.created_at, pr.updated_at,
			u1.id, u1.email, u1.apple_id, u1.username, u1.created_at,
			u2.id, u2.email, u2.apple_id, u2.username, u2.created_at
		FROM pair_requests pr
		JOIN users u1 ON pr.requester_id = u1.id
		JOIN users u2 ON pr.requested_id = u2.id
		WHERE pr.requested_id = $1 AND pr.status = 'pending'
		ORDER BY pr.created_at DESC`,
		currentUserID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pair requests"})
		return
	}
	defer rows.Close()

	var requests []models.PairRequest
	for rows.Next() {
		var pr models.PairRequest
		var requester, requested models.User
		err := rows.Scan(
			&pr.ID, &pr.RequesterID, &pr.RequestedID, &pr.Status, &pr.CreatedAt, &pr.UpdatedAt,
			&requester.ID, &requester.Email, &requester.AppleID, &requester.Username, &requester.CreatedAt,
			&requested.ID, &requested.Email, &requested.AppleID, &requested.Username, &requested.CreatedAt,
		)
		if err != nil {
			continue
		}
		pr.Requester = &requester
		pr.Requested = &requested
		requests = append(requests, pr)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    requests,
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
