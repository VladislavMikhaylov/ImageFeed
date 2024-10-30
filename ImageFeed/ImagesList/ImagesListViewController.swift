import UIKit

final class ImagesListViewController: UIViewController {
    
    @IBOutlet private var tableView: UITableView!
    
    private var photos: [Photo] = []
    private let imagesListService = ImagesListService()
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_Ru")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangePhotos),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        imagesListService.fetchPhotosNextPage()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                super.prepare(for: segue, sender: sender)
                return
            }
            let largeImageUrl = photos[indexPath.row].largeImageURL
            viewController.imageURL = largeImageUrl
        }
    }
    
    // MARK: - Обновление таблицы
    
    @objc private func didChangePhotos() {
        updateTableViewAnimated()
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { i in
                    IndexPath(row: i, section: 0)
                }
                tableView.insertRows(at: indexPaths, with: .automatic)
            } completion: { _ in
                // Обновляем высоты ячеек
                self.tableView.reloadRows(at: (0..<self.photos.count).map { IndexPath(row: $0, section: 0) }, with: .automatic)
            }
        }
    }
}
//MARK: - Extensions

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        let imageURL = photo.thumbImageURL
        
        // Используйте Kingfisher для загрузки изображения
        cell.cellImage.kf.indicatorType = .activity // Показываем индикатор загрузки
        cell.cellImage.kf.setImage(with: URL(string: imageURL)) // Загружаем изображение по URL

        // Установка метки даты
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = "Дата не указана"
        }

        // Установка изображения для кнопки "Нравится"
        let likeImage = photo.isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageSize = photo.size
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = imageViewWidth / imageSize.width
        let cellHeight = imageSize.height * scale + imageInsets.top + imageInsets.bottom
    
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
}
