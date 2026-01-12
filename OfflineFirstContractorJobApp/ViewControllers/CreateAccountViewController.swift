//  CreateAccountViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var encryptionImg: UIImageView!
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var backBtnView: UIView!
    @IBOutlet weak var fullNameTf: UITextField!
    @IBOutlet weak var passwordTf: UITextField!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var emailTf: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var fullNameView: UIView!
    
    private var isPasswordVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backBtnView.layer.cornerRadius = 40/2
        let borderColor = UIColor.black.withAlphaComponent(0.0).cgColor

        [emailView, fullNameView, passwordView].forEach { view in
            view?.layer.cornerRadius = 16
            view?.layer.borderWidth = 2
            view?.layer.borderColor = borderColor
            view?.clipsToBounds = true
        }
        createAccountBtn.layer.cornerRadius = 16
        backBtnView.layer.shadowColor =
            UIColor.black.withAlphaComponent(0.1).cgColor
        backBtnView.layer.shadowOpacity = 1
        backBtnView.layer.shadowRadius = 12
        backBtnView.layer.shadowOffset = CGSize(width: 0, height: 4)
        backBtnView.layer.masksToBounds = false
        
        passwordTf.isSecureTextEntry = true
        
        // Add tap gesture to password visibility toggle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(togglePasswordVisibility))
        encryptionImg.isUserInteractionEnabled = true
        encryptionImg.addGestureRecognizer(tapGesture)
        
        setupTextFields()
    }
    
    private func setupTextFields() {
        emailTf.keyboardType = .emailAddress
        emailTf.autocapitalizationType = .none
        passwordTf.autocapitalizationType = .none
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTf.isSecureTextEntry = !isPasswordVisible
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        createAccountBtn.applyGradient(
                colors: [
                    UIColor(hex: "#3B82F6"),
                    UIColor(hex: "#2563EB")
                ],
                cornerRadius: 16,
                shadowColor: UIColor(hex: "#3B82F6", alpha: 0.2)
            )
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    private func validateInputs() -> Bool {
        guard let name = fullNameTf.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter your full name")
            return false
        }
        
        guard let email = emailTf.text?.trimmingCharacters(in: .whitespaces), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return false
        }
        
        guard isValidEmail(email) else {
            showAlert(title: "Error", message: "Please enter a valid email address")
            return false
        }
        
        guard let password = passwordTf.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return false
        }
        
        guard password.count >= 8 else {
            showAlert(title: "Error", message: "Password must be at least 8 characters")
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    @IBAction func createAccountBtn(_ sender: UIButton) {
        guard validateInputs() else { return }
        
        createAccountBtn.isEnabled = false
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = createAccountBtn.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        APIService.shared.signup(
            name: fullNameTf.text!.trimmingCharacters(in: .whitespaces),
            email: emailTf.text!.trimmingCharacters(in: .whitespaces),
            password: passwordTf.text!
        ) { [weak self] result in
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                self?.createAccountBtn.isEnabled = true
                
                switch result {
                case .success:
                    if let token = UserDefaults.standard.string(forKey: "authToken"), !token.isEmpty {
                        LocalStorageManager.shared.clearAllData()
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let dashboardVC = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController {
                            let navController = UINavigationController(rootViewController: dashboardVC)
                            navController.modalPresentationStyle = .fullScreen
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.rootViewController = navController
                                window.makeKeyAndVisible()
                            } else {
                                self?.present(navController, animated: true)
                            }
                        }
                    } else {
                        self?.showAlert(title: "Success", message: "Account created successfully! Please sign in.") {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func signInBtn(_ sender: UIButton) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

extension CreateAccountViewController {
    
    func handleSuccessfulSignup() {
        let alert = UIAlertController(
            title: "Success",
            message: "Account created successfully! Please login.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigateToLogin()
        })
        
        present(alert, animated: true)
    }
    
    private func navigateToLogin() {
        navigationController?.popViewController(animated: true)
        
        // OR navigate to login if you're not using navigation controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "SignInViewController") as? UIViewController {
            let navigationController = UINavigationController(rootViewController: loginVC)
            navigationController.modalPresentationStyle = .fullScreen
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = navigationController
                window.makeKeyAndVisible()
            }
        }
    }
}
