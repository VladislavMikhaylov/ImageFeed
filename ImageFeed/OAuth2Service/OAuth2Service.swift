import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token")
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        guard let url = urlComponents?.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    func fetchOAuthToken(
        withCode code: String, completion: @escaping (Result<String, Error>) -> Void) {
            assert(Thread.isMainThread)
            guard lastCode != code else {
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
            guard let request = makeOAuthTokenRequest(code: code)
            else {
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
            let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        self?.task = nil
                        self?.lastCode = nil
                        return
                    }
                    guard let data = data else {
                        completion(.failure(AuthServiceError.invalidRequest))
                        self?.task = nil
                        self?.lastCode = nil
                        return
                    }
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                        let token = response.token
                        completion(.success(token))
                    } catch {
                        print("OAuth token decode error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    self?.task = nil
                    self?.lastCode = nil
                }
            }
            self.task = task
            task.resume()
        }
}
