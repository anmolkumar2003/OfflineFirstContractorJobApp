//
//  Job.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import Foundation

struct Job: Codable, Identifiable {
    let id: String?
    var title: String
    var description: String?
    var clientName: String
    var city: String
    var budget: Double
    var startDate: String?
    var status: JobStatus
    
    enum JobStatus: String, Codable {
        case active = "active"
        case pending = "pending"
        case completed = "completed"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case clientName = "client_name"
        case city
        case budget
        case startDate = "start_date"
        case status
    }
    
    // For local storage tracking
    var syncStatus: SyncStatus = .synced
    var localId: String = UUID().uuidString
}

enum SyncStatus: String, Codable {
    case pending = "pending"
    case synced = "synced"
    case failed = "failed"
}

struct JobRequest: Codable {
    let title: String
    let description: String?
    let clientName: String
    let city: String
    let budget: Double
    let startDate: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case clientName = "client_name"
        case city
        case budget
        case startDate = "start_date"
        case status
    }
}


