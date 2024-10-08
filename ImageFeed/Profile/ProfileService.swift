import Foundation

enum ProfileServiceError: Error {
    case invalidRequest
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    private let storage = OAuth2TokenStorage.shared
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    
    private(set) var profile: Profile?
    
    struct ProfileResult: Codable {
        let username: String
        let firstName: String
        let lastName: String?
        let bio: String?
        
        enum CodingKeys: String, CodingKey {
            case username
            case firstName = "first_name"
            case lastName = "last_name"
            case bio
        }
    }
    
    struct Profile {
        let username: String
        let name: String
        let loginName: String
        let bio: String
        
        init(profileResult: ProfileResult) {
            self.username = profileResult.username
            self.name = "\(profileResult.firstName) \(profileResult.lastName ?? "")"
            self.loginName = "@\(profileResult.username)"
            self.bio = profileResult.bio ?? "No bio available"
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
            print("[fetchProfile]: InvalidRequest - Request with the same token is already in progress.")
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        guard let request = makeProfileURL() else {
            print("[fetchProfile]: InvalidRequest - Failed to create request.")
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        let task: URLSessionDataTask = URLSession.shared.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let profileResult):
                let profile = Profile(profileResult: profileResult)
                print("[fetchProfile]: Success - Decoded Profile: \(profile)")
                self.profile = profile
                completion(.success(profile))
            case .failure(let error):
                print("[fetchProfile]: Error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

extension URLSession {
    func URLSessionObjectTask<T: Decodable>(for request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let data = data else {
                print("Error: No data received.")
                DispatchQueue.main.async {
                    completion(.failure(ProfileServiceError.invalidRequest))
                }
                return
            }
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedObject))
                }
            } catch {
                print("Decoding error: \(error.localizedDescription), Data: \(String(data: data, encoding: .utf8) ?? "nil")")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
