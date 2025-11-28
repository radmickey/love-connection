//
//  Constants.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation

struct Constants {
    static let baseURL = "https://api.loveconnection.app" // TODO: Update with actual backend URL

    struct API {
        static let authRegister = "/api/auth/register"
        static let authLogin = "/api/auth/login"
        static let authApple = "/api/auth/apple"
        static let userMe = "/api/user/me"
        static let pairsRequest = "/api/pairs/request"
        static let pairsRespond = "/api/pairs/respond"
        static let pairsRequests = "/api/pairs/requests"
        static let pairsCurrent = "/api/pairs/current"
        static let loveSend = "/api/love/send"
        static let loveHistory = "/api/love/history"
        static let stats = "/api/stats"
        static let websocket = "/ws"
    }

    struct Colors {
        static let heartColor = "heartRed"
        static let backgroundColor = "background"
    }
}

