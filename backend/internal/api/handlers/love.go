package handlers

import (
	"database/sql"
	"love-connection/backend/internal/models"
	"love-connection/backend/internal/services"
	"love-connection/backend/internal/websocket"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type LoveHandler struct {
	db  *sql.DB
	hub *websocket.Hub
}

func NewLoveHandler(db *sql.DB, hub *websocket.Hub) *LoveHandler {
	return &LoveHandler{db: db, hub: hub}
}

func (h *LoveHandler) SendLove(c *gin.Context) {
	userID, _ := c.Get("user_id")
	senderID := userID.(uuid.UUID)

	var req models.SendLoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var pairID uuid.UUID
	err := h.db.QueryRow(
		"SELECT id FROM pairs WHERE user1_id = $1 OR user2_id = $1",
		senderID,
	).Scan(&pairID)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No pair found"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	var eventID uuid.UUID
	err = h.db.QueryRow(
		"INSERT INTO love_events (pair_id, sender_id, duration_seconds) VALUES ($1, $2, $3) RETURNING id",
		pairID, senderID, req.DurationSeconds,
	).Scan(&eventID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create love event"})
		return
	}

	var event models.LoveEvent
	var sender models.User
	var pairID sql.NullString
	err = h.db.QueryRow(
		`SELECT e.id, e.pair_id, e.sender_id, e.duration_seconds, e.created_at,
			u.id, u.email, u.apple_id, u.username, u.created_at
		FROM love_events e
		JOIN users u ON e.sender_id = u.id
		WHERE e.id = $1`,
		eventID,
	).Scan(
		&event.ID, &pairID, &event.SenderID, &event.DurationSeconds, &event.CreatedAt,
		&sender.ID, &sender.Email, &sender.AppleID, &sender.Username, &sender.CreatedAt,
	)

	if pairID.Valid {
		parsedID, err := uuid.Parse(pairID.String)
		if err == nil {
			event.PairID = &parsedID
		}
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch event"})
		return
	}

	event.Sender = &sender

	var partnerID uuid.UUID
	err = h.db.QueryRow(
		"SELECT CASE WHEN user1_id = $1 THEN user2_id ELSE user1_id END FROM pairs WHERE id = $2",
		senderID, pairID,
	).Scan(&partnerID)

	if err == nil {
		go services.SendNotification(h.db, partnerID, sender.Username, req.DurationSeconds)
		h.hub.BroadcastLoveEvent(event, partnerID)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    event,
	})
}

func (h *LoveHandler) GetHistory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	rows, err := h.db.Query(
		`SELECT e.id, e.pair_id, e.sender_id, e.duration_seconds, e.created_at,
			u.id, u.email, u.apple_id, u.username, u.created_at
		FROM love_events e
		JOIN users u ON e.sender_id = u.id
		WHERE e.sender_id = $1
		ORDER BY e.created_at DESC
		LIMIT 100`,
		currentUserID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch history"})
		return
	}
	defer rows.Close()

	var events []models.LoveEvent
	for rows.Next() {
		var event models.LoveEvent
		var sender models.User
		var pairID sql.NullString
		err := rows.Scan(
			&event.ID, &pairID, &event.SenderID, &event.DurationSeconds, &event.CreatedAt,
			&sender.ID, &sender.Email, &sender.AppleID, &sender.Username, &sender.CreatedAt,
		)
		if err != nil {
			continue
		}
		if pairID.Valid {
			parsedID, err := uuid.Parse(pairID.String)
			if err == nil {
				event.PairID = &parsedID
			}
		}
		event.Sender = &sender
		events = append(events, event)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    events,
	})
}
