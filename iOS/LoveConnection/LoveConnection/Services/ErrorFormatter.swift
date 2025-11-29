import Foundation

struct ErrorFormatter {
    static func userFriendlyMessage(from error: Error) -> String {
        if let apiError = error as? APIError {
            return formatAPIError(apiError)
        }

        let errorString = error.localizedDescription
        let lowercased = errorString.lowercased()

        // Database errors - show generic message
        if lowercased.contains("database") ||
           lowercased.contains("pq:") ||
           lowercased.contains("sql") ||
           lowercased.contains("does not exist") ||
           lowercased.contains("connection refused") ||
           lowercased.contains("connection timeout") {
            return "Something went wrong, please try again later"
        }

        // Server errors - show generic message
        if lowercased.contains("server error") ||
           lowercased.contains("internal server error") ||
           lowercased.contains("500") {
            return "Something went wrong, please try again later"
        }

        // User-friendly validation errors
        if errorString.contains("Email") && errorString.contains("validation") {
            return "Please enter a valid email address"
        }

        if errorString.contains("Password") && errorString.contains("validation") {
            return "Password must be at least 6 characters long"
        }

        if errorString.contains("Username") && errorString.contains("validation") {
            return "Username is required"
        }

        if errorString.contains("email") && errorString.contains("tag") {
            return "Please enter a valid email address"
        }

        if errorString.contains("already exists") || errorString.contains("duplicate") {
            if errorString.lowercased().contains("email") {
                return "An account with this email already exists"
            }
            if errorString.lowercased().contains("username") {
                return "This username is already taken"
            }
            return "This information is already in use"
        }

        if errorString.contains("invalid credentials") ||
           errorString.contains("unauthorized") ||
           lowercased.contains("invalid email or password") ||
           lowercased.contains("invalid email") ||
           lowercased.contains("invalid password") {
            return "Invalid email or password"
        }

        // Network errors
        if errorString.contains("network") ||
           errorString.contains("connection") ||
           lowercased.contains("could not connect") ||
           lowercased.contains("hostname could not be found") {
            return "Unable to connect. Please check your internet connection"
        }

        if errorString.contains("timeout") {
            return "Request timed out. Please try again"
        }

        // For any other technical errors, show generic message
        return "Something went wrong, please try again later"
    }

    private static func formatAPIError(_ error: APIError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid server address"
        case .invalidResponse:
            return "Unexpected response from server"
        case .httpError(let code):
            switch code {
            case 400:
                return "Invalid request. Please check your input"
            case 401:
                return "Authentication failed"
            case 403:
                return "Access denied"
            case 404:
                return "Resource not found"
            case 500...599:
                return "Server error. Please try again later"
            default:
                return "Request failed (Error \(code))"
            }
        case .serverError(let message):
            let lowercased = message.lowercased()
            // Check if it's a database or internal error
            if lowercased.contains("database") ||
               lowercased.contains("pq:") ||
               lowercased.contains("sql") ||
               lowercased.contains("does not exist") ||
               lowercased.contains("internal") ||
               lowercased.contains("server error") {
                return "Something went wrong, please try again later"
            }
            return userFriendlyMessage(from: message)
        case .decodingError:
            return "Unable to process server response"
        }
    }

    private static func userFriendlyMessage(from message: String) -> String {
        let lowercased = message.lowercased()

        // Database errors - show generic message
        if lowercased.contains("database") ||
           lowercased.contains("pq:") ||
           lowercased.contains("sql") ||
           lowercased.contains("does not exist") ||
           lowercased.contains("internal") ||
           lowercased.contains("server error") {
            return "Something went wrong, please try again later"
        }

        if lowercased.contains("email") && (lowercased.contains("validation") || lowercased.contains("failed")) {
            return "Please enter a valid email address"
        }

        if lowercased.contains("password") && lowercased.contains("validation") {
            return "Password must be at least 6 characters long"
        }

        if lowercased.contains("username") && lowercased.contains("validation") {
            return "Username is required"
        }

        if lowercased.contains("already exists") || lowercased.contains("duplicate") {
            if lowercased.contains("email") {
                return "An account with this email already exists"
            }
            if lowercased.contains("username") {
                return "This username is already taken"
            }
            return "This information is already in use"
        }

        // For any other technical errors, show generic message
        return "Something went wrong, please try again later"
    }
}

