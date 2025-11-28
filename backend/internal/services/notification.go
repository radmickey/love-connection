package services

import (
	"database/sql"
	"fmt"
	"os"
)

func SendNotification(db *sql.DB, userID interface{}, senderUsername string, durationSeconds int) {
	var deviceToken sql.NullString
	err := db.QueryRow("SELECT device_token FROM users WHERE id = $1", userID).Scan(&deviceToken)
	if err != nil || !deviceToken.Valid {
		return
	}

	formattedDuration := formatDuration(durationSeconds)
	message := fmt.Sprintf("Пользователь %s отправил сердечко! <3\n%s", senderUsername, formattedDuration)

	apnsKeyPath := os.Getenv("APNS_KEY_PATH")
	apnsKeyID := os.Getenv("APNS_KEY_ID")
	apnsTeamID := os.Getenv("APNS_TEAM_ID")
	apnsBundleID := os.Getenv("APNS_BUNDLE_ID")

	if apnsKeyPath == "" || apnsKeyID == "" || apnsTeamID == "" || apnsBundleID == "" {
		return
	}

	sendAPNSNotification(deviceToken.String, message, apnsKeyPath, apnsKeyID, apnsTeamID, apnsBundleID)
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

func sendAPNSNotification(deviceToken, message, keyPath, keyID, teamID, bundleID string) {
	// TODO: Implement APNs client
	// This would require implementing the APNs HTTP/2 protocol
	// For now, this is a placeholder
	fmt.Printf("Would send notification to %s: %s\n", deviceToken, message)
}

