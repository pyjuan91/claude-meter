import Foundation
import Security

// MARK: - Keychain reader for Electron "Safe Storage" passwords

enum KeychainService {

    enum KeychainError: LocalizedError {
        case itemNotFound
        case unexpectedData
        case osError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Keychain item \"Claude Safe Storage\" not found. Is the Claude Desktop app installed?"
            case .unexpectedData:
                return "Keychain returned data that could not be decoded as UTF-8."
            case .osError(let status):
                return "Keychain error: OSStatus \(status)"
            }
        }
    }

    /// In-memory cache so we only hit the Keychain once per app launch
    /// (avoids repeated authorisation prompts).
    private static var cachedPassword: String?

    /// Reads the encryption password Electron stored under the given service name.
    static func getEncryptionPassword(service: String = "Claude Safe Storage") throws -> String {
        if let cached = cachedPassword { return cached }

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            // Match the exact entry Electron wrote (account = "Claude Key")
            kSecAttrAccount as String: "Claude Key",
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw status == errSecItemNotFound
                ? KeychainError.itemNotFound
                : KeychainError.osError(status)
        }

        guard let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }

        cachedPassword = password
        return password
    }
}
