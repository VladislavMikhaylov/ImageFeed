import UIKit

final class SplashViewController: UIViewController {
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        addSplashScreenLogo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkAuthenticationStatus()
        
        if let token = oauth2TokenStorage.token {
            print("Ready to load profile")
            fetchProfile(token: token)
        } else {
            showAuthScreen()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func addSplashScreenLogo() {
        let screenLogo = UIImageView(image: UIImage(named: "VectorLogo"))
        screenLogo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(screenLogo)
        screenLogo.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        screenLogo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    private func checkAuthenticationStatus() {
        if oauth2TokenStorage.token != nil {
            loadUserInfoAndProceed()
        } else {
            showAuthScreen()
        }
    }
    
    private func loadUserInfoAndProceed() {
        switchToTabBarController()
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Invalid Configuration") }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
    
    private func showAuthScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(
            withIdentifier: "AuthViewController"
        ) as? AuthViewController else {
            fatalError("Failed to instantiate AuthViewController from Storyboard")
        }
        let navigationController = UINavigationController(rootViewController: authViewController)
        authViewController.delegate = self
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ authViewController: AuthViewController) {
        dismiss(animated: true)
    }
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        print("loading profile - SplashScreen")
        ProfileService.shared.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                print("splashscreen fetchProfile working \(result)")
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { imageResult in
                    switch imageResult {
                    case .success(let avatarURL):
                        print("Successfully fetched avatar URL: \(avatarURL)")
                    case .failure(let error):
                        print("Failed to fetch avatar URL: \(error)")
                    }
                }
                self.switchToTabBarController()
                
            case .failure:
                // TODO: Sprint 11 Покажите ошибку получения профиля
                break
            }
        }
    }
}
