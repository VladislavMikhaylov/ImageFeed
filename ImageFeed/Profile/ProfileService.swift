import UIKit

enum ProfileServiceError: Error {
    case invalidRequest
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    private let storage = OAuth2TokenStorage()
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    
    private(set) var profile: Profile?
    
    struct ProfileResult: Codable {
        let username: String
        let first_name: String
        let last_name: String
        let bio: String
    }
    
    struct Profile {
        let username: String
        let name: String
        let bio: String

        init(profileResult: ProfileResult) {
            self.username = "@" + profileResult.username
            self.name = profileResult.first_name + " " + profileResult.last_name
            self.bio = profileResult.bio
        }
    }
    
    private func makeProfileURL () -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            assertionFailure("Failed to create ProfileURL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let token = storage.token else {
            assertionFailure("Failed to get ProfileToken")
            return nil
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("request: \(request)")
        return request
    }
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        guard lastToken != token else {
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        guard
            let request = makeProfileURL()
        else {
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        let task = URLSession.shared.data(for: request) { result in
                switch result {
                case .success(let data):
                    do {
                        print("decoding started \(data)")
                        let decoder = JSONDecoder()
                        let profileResult = try decoder.decode(ProfileResult.self, from: data)
                        let result = Profile(profileResult: profileResult)
                        print("decode JSON success \(result)")
                        self.profile = result
                        completion(.success(result))
                    } catch {
                        print("Failed to decode ProfileJSON: \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("Error fetching profile: \(error)")
                    completion(.failure(error))
                }
            }
        task.resume()
        }
}
