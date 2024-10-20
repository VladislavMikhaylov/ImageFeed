import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    //MARK: - Properties
    
    private var logoutButton: UIButton?
    private var avatarImageView: UIImageView?
    private var nameLabel: UILabel?
    private var loginNameLabel: UILabel?
    private var descriptionLabel: UILabel?
    private var profileImageServiceObserver: NSObjectProtocol?
    @IBAction func logoutButtonTapped(_ sender: Any) {
        // TODO: logoutAction
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(
            red: 0.10,
            green: 0.11,
            blue: 0.13,
            alpha: 1.00)
        
        addAvatarImage()
        addLogoutButton()
        addNameLabel()
        addloginNameLabel()
        addDescriptionLabel()
        
        if let profile = ProfileService.shared.profile {
            print("Loading Profile")
            updateProfileDetails(profile: profile)
        } else {
            print("Can't load Profile")
        }
        
        if let savedAvatarURL = UserDefaults.standard.string(forKey: "avatarURL"),
           let url = URL(string: savedAvatarURL) {
            let processor = RoundCornerImageProcessor(cornerRadius: 20)
            avatarImageView?.kf.indicatorType = .activity
            avatarImageView?.kf.setImage(
                with: url,
                placeholder: UIImage(named: "Placeholder"),
                options: [.processor(processor)]
            )
        }
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateAvatar()
            }
        fetchProfileAndAvatar()
    }
    private func fetchProfileAndAvatar() {
        guard let profile = ProfileService.shared.profile else { return }
        updateProfileDetails(profile: profile)
        
        if let username = ProfileService.shared.profile?.username {
            ProfileImageService.shared.fetchProfileImageURL(username: username) { [weak self] result in
                switch result {
                case .success(let url):
                    UserDefaults.standard.set(url, forKey: "avatarURL")
                    self?.updateAvatar(with: URL(string: url)!)
                case .failure(let error):
                    print("Error fetching profile image: \(error)")
                }
            }
        }
    }
    
    private func updateProfileDetails(profile: ProfileService.Profile) {
        print("Func updateProfile is working")
        loginNameLabel?.text = profile.username
        nameLabel?.text = profile.name
        descriptionLabel?.text = profile.bio
    }
    
    private func updateAvatar() {
        guard let profileImageURL = ProfileImageService.shared.avatarURL,
              let url = URL(string: profileImageURL) else {
            print("No valid avatar URL found")
            return
        }
        updateAvatar(with: url)
    }
    
    private func updateAvatar(with url: URL) {
        let processor = ResizingImageProcessor(referenceSize: CGSize(width: 70, height: 70))
        |> RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView?.kf.indicatorType = .activity
        avatarImageView?.kf.setImage(
            with: url,
            placeholder: UIImage(named: "Placeholder"),
            options: [.processor(processor)]
        )
    }
    
    private func addAvatarImage() {
        let avatarImageView = UIImageView(image: UIImage(named: "avatar"))
        view.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.clipsToBounds = true
        self.avatarImageView = avatarImageView
    }
    
    private func addLogoutButton() {
        let logoutButton = UIButton.systemButton(
            with: UIImage(named: "logout_button")!,
            target: self,
            action: nil)
        view.addSubview(logoutButton)
        logoutButton.tintColor = UIColor(named: "logout_button_color")
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        logoutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6).isActive = true
        guard let photo = avatarImageView else {
            logoutButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 45).isActive = true
            self.logoutButton = logoutButton
            return
        }
        logoutButton.centerYAnchor.constraint(equalTo: photo.centerYAnchor).isActive = true
        self.logoutButton = logoutButton
    }
    
    private func addNameLabel() {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 23)
        nameLabel.textColor = .white
        nameLabel.text = "Екатерина Новикова"
        view.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        guard let photo = self.avatarImageView else {
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 110).isActive = true
            self.nameLabel = nameLabel
            return
        }
        nameLabel.firstBaselineAnchor.constraint(equalTo: photo.bottomAnchor, constant: 26).isActive = true
        self.nameLabel = nameLabel
    }
    
    private func addloginNameLabel() {
        let loginNameLabel = UILabel()
        loginNameLabel.font = UIFont.systemFont(ofSize: 13)
        loginNameLabel.textColor = UIColor(named: "YP Gray")
        loginNameLabel.text = "@ekaterina_nov"
        view.addSubview(loginNameLabel)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        loginNameLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        loginNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        guard let name = self.nameLabel else {
            loginNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 136).isActive = true
            self.loginNameLabel = loginNameLabel
            return
        }
        loginNameLabel.topAnchor.constraint(equalTo: name.lastBaselineAnchor, constant: 8).isActive = true
        self.loginNameLabel = loginNameLabel
    }
    
    private func addDescriptionLabel() {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .white
        descriptionLabel.text = "Hello, world!"
        view.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        guard let login = self.loginNameLabel else {
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 162).isActive = true
            self.descriptionLabel = descriptionLabel
            return
        }
        descriptionLabel.topAnchor.constraint(equalTo: login.bottomAnchor, constant: 8).isActive = true
        self.descriptionLabel = descriptionLabel
    }
}
