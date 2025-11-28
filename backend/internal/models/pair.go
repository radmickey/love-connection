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

type PairRequest struct {
	ID          uuid.UUID `json:"id" db:"id"`
	RequesterID uuid.UUID `json:"requester_id" db:"requester_id"`
	RequestedID uuid.UUID `json:"requested_id" db:"requested_id"`
	Requester   *User     `json:"requester,omitempty"`
	Requested   *User     `json:"requested,omitempty"`
	Status      string    `json:"status" db:"status"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type RespondPairRequest struct {
	RequestID uuid.UUID `json:"request_id" binding:"required"`
	Accept    bool      `json:"accept" binding:"required"`
}
