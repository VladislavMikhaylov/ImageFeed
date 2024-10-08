import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    
    static let shared = OAuth2TokenStorage()
    private init() {}
    
    private let storage = KeychainWrapper.standard
    private enum StorageKeys: String {
        case token
    }
    
    var token: String? {
        get {
            storage.string(forKey: StorageKeys.token.rawValue)
        }
        set {
            guard let newValue else {
                assertionFailure("Invalid token value")
                return
            }
            storage.set(newValue, forKey: StorageKeys.token.rawValue)
        }
    }
}
