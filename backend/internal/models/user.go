package models

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID          uuid.UUID `json:"id" db:"id"`
	Email       *string   `json:"email,omitempty" db:"email"`
	AppleID     *string   `json:"apple_id,omitempty" db:"apple_id"`
	Username    string    `json:"username" db:"username"`
	PasswordHash *string  `json:"-" db:"password_hash"`
	DeviceToken *string   `json:"-" db:"device_token"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Username string `json:"username" binding:"required,min=3,max=50"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type AppleSignInRequest struct {
	IdentityToken    string `json:"identity_token" binding:"required"`
	AuthorizationCode string `json:"authorization_code" binding:"required"`
	Username         *string `json:"username,omitempty"`
}

