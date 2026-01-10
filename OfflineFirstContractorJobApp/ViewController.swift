//  ViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var signInAccountBtn: UIButton!
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var parentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInAccountBtn.layer.borderColor =
            UIColor.white.withAlphaComponent(0.2).cgColor
        signInAccountBtn.layer.borderWidth = 1
        createAccountBtn.layer.cornerRadius = 16
        signInAccountBtn.layer.cornerRadius = 16
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        parentView.applyGradient(
//            colors: [
//                UIColor(hex: "#0F172A"),
//                UIColor(hex: "#1E293B"),
//                UIColor(hex: "#0F172A")
//            ]
//        )
//
        parentView.applyGradient(
            colors: [
                UIColor(hex: "#0F172A"),   // top
                UIColor(hex: "#1E293B"),   // middle - lightest point
                UIColor(hex: "#0F172A")    // bottom - same as top
            ],
            startPoint: CGPoint(x: 0.5, y: 0.0),   // ← from top center
            endPoint:   CGPoint(x: 0.5, y: 1.0)    // → to bottom center
        )
        
        createAccountBtn.applyGradient(
            colors: [
                UIColor(hex: "#3B82F6"),
                UIColor(hex: "#2563EB")
            ],
            cornerRadius: 16
        )
        
        createAccountBtn.applyShadow(
            color: UIColor(hex: "#3B82F6", alpha: 0.2),
            radius: 10
        )
    }
    @IBAction func signInAccountBtn(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "CreateAccountViewController") as! CreateAccountViewController

            self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func createAccountBtnAction(_ sender: Any) {
    }
}
