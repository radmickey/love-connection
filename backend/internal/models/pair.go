package models

import (
	"time"

	"github.com/google/uuid"
)

type Pair struct {
	ID        uuid.UUID `json:"id" db:"id"`
	User1ID   uuid.UUID `json:"user1_id" db:"user1_id"`
	User2ID   uuid.UUID `json:"user2_id" db:"user2_id"`
	User1     *User     `json:"user1,omitempty"`
	User2     *User     `json:"user2,omitempty"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type CreatePairRequest struct {
	QRCode string `json:"qr_code" binding:"required"`
}

