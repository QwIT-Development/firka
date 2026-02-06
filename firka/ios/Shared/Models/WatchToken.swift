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

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case idToken
        case iss
        case studentId
        case studentIdNorm
        case expiryDate
    }
}
