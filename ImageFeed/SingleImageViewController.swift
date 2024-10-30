import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    var imageURL: String? {
        didSet {
            guard isViewLoaded, let urlString = imageURL, let url = URL(string: urlString) else { return }
            imageView.kf.setImage(with: url, placeholder: UIImage(named: "stub"))
        }
    }
    
    private var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "stub")
        
        if let urlString = imageURL, let url = URL(string: urlString) {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "stub"),
                options: [.transition(.fade(0.3))],
                completionHandler: { [weak self] result in
                    guard let self = self, case .success(let value) = result else { return }
                    self.rescaleAndCenterImageInScrollView(image: value.image)
                }
            )
        } else if let image {
            imageView.image = image
            rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.height / imageSize.height
        let wScale = visibleRectSize.width / imageSize.width
        let scale = min(maxZoomScale, max(hScale, wScale))
        scrollView.minimumZoomScale = min(maxZoomScale, max(minZoomScale, min(hScale, wScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming (in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView){
        guard let image else {return}
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let scale = scrollView.zoomScale
        let left = max((visibleRectSize.width - imageSize.width*scale) / 2, 0)
        let top = max((visibleRectSize.height - imageSize.height*scale) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
    }
}
