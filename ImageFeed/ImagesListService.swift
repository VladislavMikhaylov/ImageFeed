import UIKit

// Хранение информации об изображении в приложении
struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

// Структуры для декодирования JSON-ответа
struct PhotoResult: Decodable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case width
        case height
        case description
        case likedByUser = "liked_by_user"
        case urls
    }
}

struct UrlsResult: Decodable {
    let thumb: String
    let regular: String
    
    enum CodingKeys: String, CodingKey {
        case thumb
        case regular
    }
}

// Загрузка изображений и управление страницами
final class ImagesListService {
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var isLoading: Bool = false
    
    func fetchPhotosNextPage() {
        guard !isLoading else { return }
        
        isLoading = true
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        fetchPhotos(page: nextPage) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { result in
                    Photo(
                        id: result.id,
                        size: CGSize(width: result.width, height: result.height),
                        createdAt: self.parseDate(from: result.createdAt),
                        welcomeDescription: result.description,
                        thumbImageURL: result.urls.thumb,
                        largeImageURL: result.urls.regular,
                        isLiked: result.likedByUser
                    )
                }
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                }
            case .failure(let error):
                print("Error loading photos: \(error)")
            }
        }
    }
    
    private func fetchPhotos(page: Int, completion: @escaping (Result<[PhotoResult], Error>) -> Void) {
        let accessKey = "mXP93bAbtMkYRhdDz9giHyxKdGRQpcgdxTWbxBiBOl4"
        let urlString = "https://api.unsplash.com/photos?page=\(page)&client_id=\(accessKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            do {
                let photoResults = try JSONDecoder().decode([PhotoResult].self, from: data)
                completion(.success(photoResults))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
