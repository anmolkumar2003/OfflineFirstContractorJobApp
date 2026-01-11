//  CreateAccountViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var backBtnView: UIView!
    @IBOutlet weak var fullNameTf: UITextField!
    @IBOutlet weak var encryptionImg: UIImageView!
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
            UIColor.black.withAlphaComponent(0.1).cgColor   // #0000001A
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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
                case .success(let authResponse):
                    // Save user name
                    UserDefaults.standard.set(self?.fullNameTf.text?.trimmingCharacters(in: .whitespaces), forKey: "userName")
                    
                    // Navigate to dashboard
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let dashboardVC = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController {
                        let navController = UINavigationController(rootViewController: dashboardVC)
                        navController.modalPresentationStyle = .fullScreen
                        self?.present(navController, animated: true)
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
