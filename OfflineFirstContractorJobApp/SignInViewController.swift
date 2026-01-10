//  SignInViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var backBtnView: UIView!
    @IBOutlet weak var showPasswordImg: UIImageView!
    @IBOutlet weak var passwordTf: UITextField!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var emailTf: UITextField!
    @IBOutlet weak var emailView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        backBtnView.layer.cornerRadius = 40/2
        let borderColor = UIColor.black.withAlphaComponent(0.0).cgColor

        [emailView, passwordView].forEach { view in
            view?.layer.cornerRadius = 16
            view?.layer.borderWidth = 2
            view?.layer.borderColor = borderColor
            view?.clipsToBounds = true
        }
        backBtnView.layer.shadowColor =
            UIColor.black.withAlphaComponent(0.1).cgColor   // #0000001A
        backBtnView.layer.shadowOpacity = 1
        backBtnView.layer.shadowRadius = 12
        backBtnView.layer.shadowOffset = CGSize(width: 0, height: 4)
        backBtnView.layer.masksToBounds = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        signInBtn.applyGradient(
                colors: [
                    UIColor(hex: "#3B82F6"),
                    UIColor(hex: "#2563EB")
                ],
                cornerRadius: 16,
                shadowColor: UIColor(hex: "#3B82F6", alpha: 0.2)
            )
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func createAccountBtn(_ sender: UIButton) {
    }
    @IBAction func forgotPasswordBtn(_ sender: UIButton) {
    }
    
    @IBAction func signInBtnAction(_ sender: UIButton) {
    }
}
