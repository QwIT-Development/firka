import Foundation

// MARK: - Token Structure
struct WatchToken: Codable {
    let accessToken: String
    let refreshToken: String
    let idToken: String
    let iss: String
    let studentId: String
    let studentIdNorm: Int64
    let expiryDate: Date
    let tokenVersion: Int64?
    let updatedAtMs: Int64?

    init(
        accessToken: String,
        refreshToken: String,
        idToken: String,
        iss: String,
        studentId: String,
        studentIdNorm: Int64,
        expiryDate: Date,
        tokenVersion: Int64? = nil,
        updatedAtMs: Int64? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.iss = iss
        self.studentId = studentId
        self.studentIdNorm = studentIdNorm
        self.expiryDate = expiryDate
        self.tokenVersion = tokenVersion
        self.updatedAtMs = updatedAtMs
    }

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case idToken
        case iss
        case studentId
        case studentIdNorm
        case expiryDate
        case tokenVersion
        case updatedAtMs
    }

    var effectiveTokenVersion: Int64? {
        if let tokenVersion, tokenVersion > 0 {
            return tokenVersion
        }
        return Self.extractIatMillis(from: idToken)
    }

    var effectiveUpdatedAtMs: Int64? {
        if let updatedAtMs, updatedAtMs > 0 {
            return updatedAtMs
        }
        return nil
    }

    func isSameAccount(as other: WatchToken) -> Bool {
        return iss == other.iss && studentIdNorm == other.studentIdNorm
    }

    func isNewer(than other: WatchToken) -> Bool {
        if !isSameAccount(as: other) {
            return expiryDate > other.expiryDate
        }

        let incomingVersion = effectiveTokenVersion
        let currentVersion = other.effectiveTokenVersion
        if let incomingVersion, let currentVersion, incomingVersion != currentVersion {
            return incomingVersion > currentVersion
        }

        if expiryDate != other.expiryDate {
            return expiryDate > other.expiryDate
        }

        let incomingUpdatedAt = effectiveUpdatedAtMs
        let currentUpdatedAt = other.effectiveUpdatedAtMs
        if let incomingUpdatedAt, let currentUpdatedAt, incomingUpdatedAt != currentUpdatedAt {
            return incomingUpdatedAt > currentUpdatedAt
        }

        if refreshToken != other.refreshToken {
            if let _ = incomingUpdatedAt, currentUpdatedAt == nil {
                return true
            }
            if incomingUpdatedAt == nil, let _ = currentUpdatedAt {
                return false
            }
            if let _ = incomingVersion, currentVersion == nil {
                return true
            }
            if incomingVersion == nil, let _ = currentVersion {
                return false
            }
        }

        return false
    }

    static func extractIatMillis(from idToken: String) -> Int64? {
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else {
            return nil
        }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = payload.count % 4
        if padding > 0 {
            payload += String(repeating: "=", count: 4 - padding)
        }

        guard let payloadData = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }

        if let iatInt = json["iat"] as? Int {
            return Int64(iatInt) * 1000
        }
        if let iatInt64 = json["iat"] as? Int64 {
            return iatInt64 * 1000
        }
        if let iatDouble = json["iat"] as? Double {
            return Int64(iatDouble * 1000)
        }
        if let iatString = json["iat"] as? String, let iatInt64 = Int64(iatString) {
            return iatInt64 * 1000
        }

        return nil
    }
}
