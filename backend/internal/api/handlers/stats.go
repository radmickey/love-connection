package handlers

import (
	"database/sql"
	"love-connection/backend/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type StatsHandler struct {
	db *sql.DB
}

func NewStatsHandler(db *sql.DB) *StatsHandler {
	return &StatsHandler{db: db}
}

func (h *StatsHandler) GetStats(c *gin.Context) {
	userID, _ := c.Get("user_id")
	currentUserID := userID.(uuid.UUID)

	var pairID uuid.UUID
	err := h.db.QueryRow(
		"SELECT id FROM pairs WHERE user1_id = $1 OR user2_id = $1",
		currentUserID,
	).Scan(&pairID)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": models.Stats{
				TotalEvents:           0,
				TotalDurationSeconds:  0,
				AverageDurationSeconds: 0,
			},
		})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	var stats models.Stats
	err = h.db.QueryRow(
		`SELECT 
			COUNT(*) as total_events,
			COALESCE(SUM(duration_seconds), 0) as total_duration_seconds,
			COALESCE(AVG(duration_seconds), 0) as average_duration_seconds
		FROM love_events
		WHERE pair_id = $1`,
		pairID,
	).Scan(&stats.TotalEvents, &stats.TotalDurationSeconds, &stats.AverageDurationSeconds)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stats"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

