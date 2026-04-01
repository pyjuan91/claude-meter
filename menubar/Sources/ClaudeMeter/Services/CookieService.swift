import Foundation
import SQLite3
import CryptoShim

// MARK: - Read & decrypt cookies from the Claude Desktop Electron app

enum CookieService {

    enum CookieError: LocalizedError {
        case databaseNotFound
        case sqliteError(String)
        case cookieNotFound(String)
        case decryptionFailed
        case invalidData
        case pbkdf2Failed

        var errorDescription: String? {
            switch self {
            case .databaseNotFound:
                return "Claude Desktop cookie database not found. Is the app installed and logged in?"
            case .sqliteError(let msg):
                return "SQLite error: \(msg)"
            case .cookieNotFound(let name):
                return "Cookie \"\(name)\" not found in Claude Desktop storage."
            case .decryptionFailed:
                return "Failed to decrypt cookie. The Keychain password may have changed."
            case .invalidData:
                return "Cookie data is not in the expected Chromium v10 format."
            case .pbkdf2Failed:
                return "PBKDF2 key derivation failed."
            }
        }
    }

    // Chromium cookie encryption constants (macOS)
    private static let salt = Array("saltysalt".utf8)
    private static let iterations: UInt32 = 1003
    private static let keyLength = 16  // AES-128
    private static let ivBytes = [UInt8](repeating: 0x20, count: 16)  // 16 × space

    private static var cookiePath: String {
        NSHomeDirectory() + "/Library/Application Support/Claude/Cookies"
    }

    // MARK: - Public API

    /// Decrypt a named cookie from the Claude Desktop Electron store.
    static func getCookie(name: String, host: String = ".claude.ai") throws -> String {
        let password = try KeychainService.getEncryptionPassword()
        let derivedKey = try deriveKey(password: password)
        let encryptedBlob = try readEncryptedCookie(name: name, host: host)
        return try decrypt(blob: encryptedBlob, key: derivedKey)
    }

    // MARK: - PBKDF2 key derivation

    private static func deriveKey(password: String) throws -> [UInt8] {
        let passwordBytes = Array(password.utf8)
        var derivedKey = [UInt8](repeating: 0, count: keyLength)

        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes, passwordBytes.count,
            salt, salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
            iterations,
            &derivedKey, keyLength
        )

        guard status == kCCSuccess else { throw CookieError.pbkdf2Failed }
        return derivedKey
    }

    // MARK: - SQLite reader

    private static func readEncryptedCookie(name: String, host: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: cookiePath) else {
            throw CookieError.databaseNotFound
        }

        var db: OpaquePointer?
        // Open read-only — never modify the Desktop app's database
        guard sqlite3_open_v2(cookiePath, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else {
            let msg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(db)
            throw CookieError.sqliteError(msg)
        }
        defer { sqlite3_close(db) }

        // Allow up to 1 s for the Desktop app to release its write lock
        sqlite3_busy_timeout(db, 1000)

        let sql = "SELECT encrypted_value FROM cookies WHERE host_key = ?1 AND name = ?2 LIMIT 1"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw CookieError.sqliteError(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        // SQLITE_TRANSIENT tells SQLite to copy the string immediately
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, host, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, name, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw CookieError.cookieNotFound(name)
        }
        guard let blob = sqlite3_column_blob(stmt, 0) else {
            throw CookieError.invalidData
        }
        let size = Int(sqlite3_column_bytes(stmt, 0))
        return Data(bytes: blob, count: size)
    }

    // MARK: - AES-128-CBC decryption

    private static func decrypt(blob: Data, key: [UInt8]) throws -> String {
        // Chromium v10 format: "v10" (3 bytes) + encrypted payload
        guard blob.count > 3 else { throw CookieError.invalidData }

        let prefix = blob.prefix(3)
        guard String(data: prefix, encoding: .ascii) == "v10" else {
            // Unencrypted cookie — return as-is
            if let plain = String(data: blob, encoding: .utf8) { return plain }
            throw CookieError.invalidData
        }

        let payload = [UInt8](blob.dropFirst(3))

        // Electron's cookie encryption embeds a 16-byte random nonce as the IV
        // followed by the AES-128-CBC ciphertext. After decryption, the first
        // 16 bytes of plaintext are internal padding that must be discarded.
        guard payload.count > 32 else { throw CookieError.invalidData }

        let iv = Array(payload.prefix(16))
        let ciphertext = Array(payload.dropFirst(16))

        var plaintext = [UInt8](repeating: 0, count: ciphertext.count + kCCBlockSizeAES128)
        var plaintextLength = 0

        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            key, keyLength,
            iv,
            ciphertext, ciphertext.count,
            &plaintext, plaintext.count,
            &plaintextLength
        )

        guard status == Int32(kCCSuccess) else { throw CookieError.decryptionFailed }

        // Skip the 16-byte internal padding prepended by Electron before the actual value
        let skipBytes = 16
        guard plaintextLength > skipBytes else { throw CookieError.invalidData }

        let valueBytes = plaintext[skipBytes..<plaintextLength]
        guard let result = String(bytes: valueBytes, encoding: .utf8) else {
            throw CookieError.invalidData
        }
        return result
    }
}
