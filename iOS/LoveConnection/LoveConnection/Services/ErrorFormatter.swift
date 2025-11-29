import Foundation

struct ErrorFormatter {
    static func userFriendlyMessage(from error: Error) -> String {
        // First, try to cast as APIError
        if let apiError = error as? APIError {
            return formatAPIError(apiError)
        }

        // Also check if the error description contains APIError patterns
        let errorString = error.localizedDescription
        let lowercased = errorString.lowercased()

        // If it looks like an API error but wasn't caught above, handle it
        if lowercased.contains("invalid response") ||
           lowercased.contains("invalid url") ||
           lowercased.contains("http error") ||
           lowercased.contains("decoding error") {
            return "Something went wrong, please try again later"
        }

        // Only show specific messages for known user-facing errors
        // Everything else gets a generic friendly message

        // Username validation errors (user can fix these)
        if lowercased.contains("username") && (lowercased.contains("already taken") || lowercased.contains("already exists") || lowercased.contains("duplicate")) {
            return "This username is already taken"
        }

        if lowercased.contains("username") && lowercased.contains("validation") {
            if lowercased.contains("at least") {
                return "Username must be at least 3 characters"
            }
            if lowercased.contains("12") || lowercased.contains("maximum") {
                return "Username must be 12 characters or less"
            }
            if lowercased.contains("letter") || lowercased.contains("alphanumeric") {
                return "Username must start with a letter and contain only letters and numbers"
            }
            if lowercased.contains("space") {
                return "Username cannot contain spaces"
            }
            return "Please enter a valid username"
        }

        // Email validation errors (user can fix these)
        if lowercased.contains("email") && (lowercased.contains("already exists") || lowercased.contains("duplicate")) {
            return "An account with this email already exists"
        }

        if lowercased.contains("email") && (lowercased.contains("validation") || lowercased.contains("invalid")) {
            return "Please enter a valid email address"
        }

        // Password validation errors (user can fix these)
        if lowercased.contains("password") && lowercased.contains("validation") {
            if lowercased.contains("at least") || lowercased.contains("6") {
                return "Password must be at least 6 characters long"
            }
            return "Please enter a valid password"
        }

        // Authentication errors (user-facing)
        if lowercased.contains("invalid credentials") ||
           lowercased.contains("unauthorized") ||
           (lowercased.contains("invalid") && (lowercased.contains("email") || lowercased.contains("password"))) {
            return "Invalid email or password"
        }

        // Network connectivity errors (user can check their connection)
        if lowercased.contains("network") ||
           lowercased.contains("connection") ||
           lowercased.contains("could not connect") ||
           lowercased.contains("hostname could not be found") ||
           lowercased.contains("no internet") {
            return "Unable to connect. Please check your internet connection"
        }

        if lowercased.contains("timeout") {
            return "Request timed out. Please try again"
        }

        // For ALL other errors (database, server, technical, unknown) - show generic friendly message
        return "Something went wrong, please try again later"
    }

    private static func formatAPIError(_ error: APIError) -> String {
        switch error {
        case .invalidURL:
            return "Unable to connect. Please check your internet connection"
        case .invalidResponse:
            return "Something went wrong, please try again later"
        case .httpError(let code):
            switch code {
            case 400:
                // Check if it's a validation error we can show specifically
                return "Invalid request. Please check your input"
            case 401:
                return "Authentication failed"
            case 403:
                return "Access denied"
            case 404:
                return "Something went wrong, please try again later"
            case 500...599:
                return "Something went wrong, please try again later"
            default:
                return "Something went wrong, please try again later"
            }
        case .serverError(let message):
            // Always use userFriendlyMessage which will return friendly message for all non-user errors
            let friendlyMessage = userFriendlyMessage(from: message)
            // Ensure we never return technical error details
            if friendlyMessage == message && !isUserFacingError(message) {
                return "Something went wrong, please try again later"
            }
            return friendlyMessage
        case .decodingError:
            return "Something went wrong, please try again later"
        }
    }

    private static func userFriendlyMessage(from message: String) -> String {
        let lowercased = message.lowercased()

        // Only show specific messages for known user-facing errors
        // Everything else gets a generic friendly message

        // Username errors (user can fix these)
        if lowercased.contains("username") && (lowercased.contains("already taken") || lowercased.contains("already exists") || lowercased.contains("duplicate")) {
            return "This username is already taken"
        }

        if lowercased.contains("username") && lowercased.contains("validation") {
            if lowercased.contains("at least") {
                return "Username must be at least 3 characters"
            }
            if lowercased.contains("12") || lowercased.contains("maximum") {
                return "Username must be 12 characters or less"
            }
            if lowercased.contains("letter") || lowercased.contains("alphanumeric") {
                return "Username must start with a letter and contain only letters and numbers"
            }
            if lowercased.contains("space") {
                return "Username cannot contain spaces"
            }
            return "Please enter a valid username"
        }

        // Email errors (user can fix these)
        if lowercased.contains("email") && (lowercased.contains("already exists") || lowercased.contains("duplicate")) {
            return "An account with this email already exists"
        }

        if lowercased.contains("email") && (lowercased.contains("validation") || lowercased.contains("invalid")) {
            return "Please enter a valid email address"
        }

        // Password errors (user can fix these)
        if lowercased.contains("password") && lowercased.contains("validation") {
            if lowercased.contains("at least") || lowercased.contains("6") {
                return "Password must be at least 6 characters long"
            }
            return "Please enter a valid password"
        }

        // Authentication errors (user-facing)
        if lowercased.contains("invalid credentials") ||
           lowercased.contains("unauthorized") ||
           (lowercased.contains("invalid") && (lowercased.contains("email") || lowercased.contains("password"))) {
            return "Invalid email or password"
        }

        // For ALL other errors (database, server, technical, unknown) - show generic friendly message
        return "Something went wrong, please try again later"
    }

    private static func isUserFacingError(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        // Check if this is a known user-facing error
        return (lowercased.contains("username") && (lowercased.contains("already taken") || lowercased.contains("already exists") || lowercased.contains("duplicate") || lowercased.contains("validation"))) ||
               (lowercased.contains("email") && (lowercased.contains("already exists") || lowercased.contains("duplicate") || lowercased.contains("validation") || lowercased.contains("invalid"))) ||
               (lowercased.contains("password") && lowercased.contains("validation")) ||
               (lowercased.contains("invalid credentials") || lowercased.contains("unauthorized"))
    }
}

