//
//  KeychainHelper.swift
//  Furg
//
//  Secure storage for sensitive data (tokens, credentials)
//

import Foundation
import Security

enum KeychainHelper {
    static let jwtTokenKey = "com.furg.app.jwt_token"
    static let userIdKey = "com.furg.app.user_id"

    // MARK: - Save

    static func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Try to delete existing first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - Read

    static func read(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return data
    }

    // MARK: - Delete

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    static func clearAll() {
        delete(forKey: jwtTokenKey)
        delete(forKey: userIdKey)
    }

    // MARK: - Convenience Methods

    static var jwtToken: String? {
        get {
            guard let data = read(forKey: jwtTokenKey) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            if let newValue = newValue, let data = newValue.data(using: .utf8) {
                try? save(data, forKey: jwtTokenKey)
            } else {
                delete(forKey: jwtTokenKey)
            }
        }
    }

    static var userId: String? {
        get {
            guard let data = read(forKey: userIdKey) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            if let newValue = newValue, let data = newValue.data(using: .utf8) {
                try? save(data, forKey: userIdKey)
            } else {
                delete(forKey: userIdKey)
            }
        }
    }

    // MARK: - Migration from UserDefaults

    static func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard

        // Migrate JWT token
        if let oldToken = defaults.string(forKey: "jwtToken") {
            jwtToken = oldToken
            defaults.removeObject(forKey: "jwtToken")
        }

        // Migrate user ID
        if let oldUserId = defaults.string(forKey: "userId") {
            userId = oldUserId
            defaults.removeObject(forKey: "userId")
        }

        defaults.synchronize()
    }
}

// MARK: - Error Handling

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case readFailed
    case deleteFailed
}
