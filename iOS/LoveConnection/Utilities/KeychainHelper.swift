//
//  KeychainHelper.swift
//  LoveConnection
//
//  Created on 2025-01-27.
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let tokenKey = "com.loveconnection.auth.token"
    private let refreshTokenKey = "com.loveconnection.auth.refresh_token"
    
    private init() {}
    
    func saveToken(_ token: String) -> Bool {
        return save(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return get(forKey: tokenKey)
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        return save(token, forKey: refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }
    
    func deleteToken() {
        delete(forKey: tokenKey)
        delete(forKey: refreshTokenKey)
    }
    
    private func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

