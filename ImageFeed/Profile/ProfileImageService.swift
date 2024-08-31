import Foundation

enum ProfileImageServiceError: Error {
    case invalidRequest
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private init() {}
    private let storage = OAuth2TokenStorage()
    
    private (set) var avatarURL: String?
    private var lastToken: String?
    
    struct UserResult: Codable {
        let profileImage: ProfileImage
        
        enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
    }
    
    struct ProfileImage: Codable {
        let small: URL
    }
    
    private func makeProfileImageURL(username: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            assertionFailure("Failed to create ProfileImage")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let token = storage.token else {
            assertionFailure("Failed to get ProfileImageToken")
            return nil
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("request: \(request)")
        return request
    }
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard let request = makeProfileImageURL(username: username) else {
            completion(.failure(ProfileImageServiceError.invalidRequest))
            return
        }
        
        let task = URLSession.shared.data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    print("Decoding started \(data)")
                    let decoder = JSONDecoder()
                    let userResult = try decoder.decode(UserResult.self, from: data)
                    let profileImageURL = userResult.profileImage.small.absoluteString
                    print("Decode JSON success \(result)")
                    self.avatarURL = profileImageURL
                    completion(.success(profileImageURL))
                    NotificationCenter.default
                        .post(
                            name: ProfileImageService.didChangeNotification,
                            object: self,
                            userInfo: ["URL": profileImageURL])
                } catch {
                    print("Failed to decode ProfileImageJSON: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("Error fetching profile image: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
