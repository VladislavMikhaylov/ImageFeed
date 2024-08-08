import Foundation

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    init() {}
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token")
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.AccessKey),
            URLQueryItem(name: "client_secret", value: Constants.SecretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.RedirectURI),
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
        withCode code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let request = makeOAuthTokenRequest(code: code)
        guard let request else {
            print("Invalid fetch token request")
            return
        }
        let task = URLSession.shared.data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    let token = response.token
                    completion(.success(token))
                } catch {
                    print("OAuth token decode error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
