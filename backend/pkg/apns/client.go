package apns

import (
	"crypto/ecdsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Client struct {
	keyID     string
	teamID    string
	bundleID  string
	privateKey *ecdsa.PrivateKey
	token     string
	tokenExp  time.Time
}

func NewClient(keyPath, keyID, teamID, bundleID string) (*Client, error) {
	keyData, err := ioutil.ReadFile(keyPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read key file: %w", err)
	}

	block, _ := pem.Decode(keyData)
	if block == nil {
		return nil, fmt.Errorf("failed to decode PEM block")
	}

	privateKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse private key: %w", err)
	}

	ecdsaKey, ok := privateKey.(*ecdsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("key is not ECDSA private key")
	}

	return &Client{
		keyID:     keyID,
		teamID:    teamID,
		bundleID:  bundleID,
		privateKey: ecdsaKey,
	}, nil
}

func (c *Client) generateToken() (string, error) {
	if time.Now().Before(c.tokenExp) {
		return c.token, nil
	}

	now := time.Now()
	claims := jwt.MapClaims{
		"iss": c.teamID,
		"iat": now.Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodES256, claims)
	token.Header["kid"] = c.keyID

	tokenString, err := token.SignedString(c.privateKey)
	if err != nil {
		return "", err
	}

	c.token = tokenString
	c.tokenExp = now.Add(55 * time.Minute)

	return tokenString, nil
}

func (c *Client) SendNotification(deviceToken, title, body string) error {
	token, err := c.generateToken()
	if err != nil {
		return err
	}

	url := fmt.Sprintf("https://api.sandbox.push.apple.com/3/device/%s", deviceToken)
	if c.isProduction() {
		url = fmt.Sprintf("https://api.push.apple.com/3/device/%s", deviceToken)
	}

	payload := map[string]interface{}{
		"aps": map[string]interface{}{
			"alert": map[string]string{
				"title": title,
				"body":  body,
			},
			"sound": "default",
			"badge": 1,
		},
	}

	return c.sendHTTP2Request(url, token, payload)
}

func (c *Client) isProduction() bool {
	return true
}

func (c *Client) sendHTTP2Request(url, token string, payload map[string]interface{}) error {
	// TODO: Implement HTTP/2 client for APNs
	// This requires http2 package and proper TLS configuration
	// For now, this is a placeholder that logs the notification
	fmt.Printf("APNs Notification to %s: %+v\n", url, payload)
	return nil
}

