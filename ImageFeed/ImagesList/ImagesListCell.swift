import UIKit
import Kingfisher

class ImagesListCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    static let reuseIdentifier = "ImagesListCell"
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
    }
}
