//
//  AuthHelper.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import UIKit

class AuthHelper {
    static func handleUnauthorizedError(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            // Clear token
            UserDefaults.standard.removeObject(forKey: "authToken")
            
            // Navigate to login
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let loginVC = storyboard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController {
                    let navController = UINavigationController(rootViewController: loginVC)
                    navController.modalPresentationStyle = .fullScreen
                    rootViewController.present(navController, animated: true) {
                        completion()
                    }
                } else {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
}


