import UIKit

final class SplashViewController: UIViewController {
    private let ShowAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkAuthenticationStatus()
        
        if let token = oauth2TokenStorage.token {
            print("Ready to load profile")
            fetchProfile(token: token)
        } else {
            performSegue(withIdentifier: ShowAuthenticationScreenSegueIdentifier, sender: nil)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func checkAuthenticationStatus() {
        if oauth2TokenStorage.token != nil {
            loadUserInfoAndProceed()
        } else {
            performSegue(withIdentifier: ShowAuthenticationScreenSegueIdentifier, sender: nil)
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
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers.first as? AuthViewController
            else { fatalError("Failed to prepare for \(ShowAuthenticationScreenSegueIdentifier)") }
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
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
            case .success (let profile):
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
