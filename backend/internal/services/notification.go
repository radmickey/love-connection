package services

import (
	"database/sql"
	"fmt"
	"love-connection/backend/pkg/apns"
	"os"
	"sync"

	"github.com/google/uuid"
)

var apnsClient *apns.Client
var apnsClientOnce sync.Once

func SendNotification(db *sql.DB, userID uuid.UUID, senderUsername string, durationSeconds int) {
	var deviceToken sql.NullString
	err := db.QueryRow("SELECT device_token FROM users WHERE id = $1", userID).Scan(&deviceToken)
	if err != nil || !deviceToken.Valid {
		return
	}

	formattedDuration := formatDuration(durationSeconds)
	title := "Love Connection"
	body := fmt.Sprintf("Пользователь %s отправил сердечко! <3\n%s", senderUsername, formattedDuration)

	apnsKeyPath := os.Getenv("APNS_KEY_PATH")
	apnsKeyID := os.Getenv("APNS_KEY_ID")
	apnsTeamID := os.Getenv("APNS_TEAM_ID")
	apnsBundleID := os.Getenv("APNS_BUNDLE_ID")

	if apnsKeyPath == "" || apnsKeyID == "" || apnsTeamID == "" || apnsBundleID == "" {
		fmt.Printf("APNs not configured, would send: %s\n", body)
		return
	}

	apnsClientOnce.Do(func() {
		client, err := apns.NewClient(apnsKeyPath, apnsKeyID, apnsTeamID, apnsBundleID)
		if err != nil {
			fmt.Printf("Failed to create APNs client: %v\n", err)
			return
		}
		apnsClient = client
	})

	if apnsClient != nil {
		if err := apnsClient.SendNotification(deviceToken.String, title, body); err != nil {
			fmt.Printf("Failed to send APNs notification: %v\n", err)
		}
	}
}

func formatDuration(seconds int) string {
	minutes := seconds / 60
	secs := seconds % 60

	if minutes > 0 {
		if secs > 0 {
			return fmt.Sprintf("%d мин %d сек", minutes, secs)
		}
		return fmt.Sprintf("%d мин", minutes)
	}
	return fmt.Sprintf("%d сек", secs)
}

