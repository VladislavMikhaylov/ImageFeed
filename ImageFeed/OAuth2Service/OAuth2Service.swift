import Foundation

enum AuthServiceError: Error {
    case invalidRequest
    case decodingError
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
                print("[fetchOAuthToken]: InvalidRequest - Attempted to reuse the same code.")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
            guard let request = makeOAuthTokenRequest(code: code) else {
                print("[fetchOAuthToken]: InvalidRequest - Failed to create request.")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
            let task: URLSessionDataTask = urlSession.objectTask(for: request) {
                [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        let token = response.token
                        completion(.success(token))
                    case .failure(let error):
                        print("[fetchOAuthToken]: Error - \(error.localizedDescription)")
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

extension URLSession {
    func objectTask<T: Decodable>(for request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let data = data else {
                let error = AuthServiceError.invalidRequest
                print("No data received.")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(responseObject))
                }
            } catch {
                print("Decoding error: \(error.localizedDescription), Data: \(String(data: data, encoding: .utf8) ?? "nil")")
                DispatchQueue.main.async {
                    completion(.failure(AuthServiceError.decodingError))
                }
            }
        }
    }
}
