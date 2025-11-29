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

	// БЕЗОПАСНОСТЬ: Находим пару для отправителя и проверяем, что он действительно в этой паре
	// Это гарантирует, что пользователь может отправлять сердечки только своему партнеру
	var pairID uuid.UUID
	var user1ID, user2ID uuid.UUID
	err := h.db.QueryRow(
		"SELECT id, user1_id, user2_id FROM pairs WHERE user1_id = $1 OR user2_id = $1",
		senderID,
	).Scan(&pairID, &user1ID, &user2ID)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No pair found"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Убеждаемся, что senderID действительно является участником этой пары
	// Это защита от потенциальных гонок условий или ошибок в логике
	if senderID != user1ID && senderID != user2ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You are not a member of this pair"})
		return
	}

	// БЕЗОПАСНОСТЬ: Вставляем событие только с pairID, который мы получили из проверки выше
	// senderID берется из токена (проверен middleware), поэтому он не может быть подделан
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
	var pairIDNullable sql.NullString
	err = h.db.QueryRow(
		`SELECT e.id, e.pair_id, e.sender_id, e.duration_seconds, e.created_at,
			u.id, u.email, u.apple_id, u.username, u.created_at
		FROM love_events e
		JOIN users u ON e.sender_id = u.id
		WHERE e.id = $1`,
		eventID,
	).Scan(
		&event.ID, &pairIDNullable, &event.SenderID, &event.DurationSeconds, &event.CreatedAt,
		&sender.ID, &sender.Email, &sender.AppleID, &sender.Username, &sender.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch event"})
		return
	}

	if pairIDNullable.Valid {
		parsedID, err := uuid.Parse(pairIDNullable.String)
		if err == nil {
			event.PairID = &parsedID
		}
	}

	event.Sender = &sender

	// БЕЗОПАСНОСТЬ: Определяем партнера из уже проверенной пары
	// Используем уже полученные user1ID и user2ID для определения партнера
	// Это безопасно, потому что мы уже проверили, что senderID является участником пары
	var partnerID uuid.UUID
	if senderID == user1ID {
		partnerID = user2ID
	} else {
		partnerID = user1ID
	}

	// БЕЗОПАСНОСТЬ: Дополнительная проверка - партнер должен быть другим пользователем
	// Это защита от некорректных данных в базе (хотя есть CHECK constraint в схеме)
	if partnerID == senderID {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid pair configuration"})
		return
	}

	// Отправляем уведомление и broadcast только своему партнеру
	go services.SendNotification(h.db, partnerID, sender.Username, req.DurationSeconds)
	h.hub.BroadcastLoveEvent(event, partnerID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    event,
	})
}

func (h *LoveHandler) GetHistory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	// Получаем все события из пары пользователя (как отправленные им, так и полученные от партнера)
	rows, err := h.db.Query(
		`SELECT e.id, e.pair_id, e.sender_id, e.duration_seconds, e.created_at,
			u.id, u.email, u.apple_id, u.username, u.created_at
		FROM love_events e
		JOIN users u ON e.sender_id = u.id
		JOIN pairs p ON e.pair_id = p.id
		WHERE (p.user1_id = $1 OR p.user2_id = $1)
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
