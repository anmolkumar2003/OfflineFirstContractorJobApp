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

    @IBAction func createAccountBtn(_ sender: UIButton) {
    }
    
    @IBAction func signInBtn(_ sender: UIButton) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
