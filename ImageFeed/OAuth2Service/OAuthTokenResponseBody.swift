import Foundation

struct OAuthTokenResponseBody: Decodable {
    let token: String
    let token_type: String
    let scope: String
    let created_at: Int
    
    private enum CodingKeys: String, CodingKey {
        case token = "access_token"
        case token_type = "token_type"
        case scope = "scope"
        case created_at = "created_at"
    }
}
