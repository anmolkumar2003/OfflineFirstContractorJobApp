//
//  AuthModels.swift
//  OfflineFirstContractorJobApp
//

import Foundation

// MARK: - User
struct User: Codable {
    let id: String
    let name: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
    }
}

// MARK: - Login / Signup API Wrapper
struct AuthAPIResponse: Codable {
    let success: Bool
    let status: Int
    let message: String
    let data: AuthUserData
}

// MARK: - User + Token
struct AuthUserData: Codable {
    let id: String
    let name: String
    let email: String
    let token: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
        case token
    }
}

// MARK: - Request Body
struct AuthRequest: Codable {
    let name: String?
    let email: String
    let password: String
}
