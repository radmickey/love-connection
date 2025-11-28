package models

type FeatureFlags struct {
	EnableEmailPasswordAuth bool `json:"enable_email_password_auth"`
	EnableAppleSignIn       bool `json:"enable_apple_sign_in"`
}

