package models

import (
	"time"

	"github.com/google/uuid"
)

type LoveEvent struct {
	ID             uuid.UUID `json:"id" db:"id"`
	PairID         uuid.UUID `json:"pair_id" db:"pair_id"`
	SenderID       uuid.UUID `json:"sender_id" db:"sender_id"`
	Sender         *User     `json:"sender,omitempty"`
	DurationSeconds int      `json:"duration_seconds" db:"duration_seconds"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
}

type SendLoveRequest struct {
	DurationSeconds int `json:"duration_seconds" binding:"required,min=1"`
}

type Stats struct {
	TotalEvents          int     `json:"total_events"`
	TotalDurationSeconds int     `json:"total_duration_seconds"`
	AverageDurationSeconds float64 `json:"average_duration_seconds"`
}

