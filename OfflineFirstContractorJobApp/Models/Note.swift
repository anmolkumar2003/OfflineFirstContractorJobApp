//  Note.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import Foundation

struct Note: Codable, Identifiable {
    let id: String?
    var jobId: String
    var content: String
    var createdAt: String?
    var updatedAt: String?
    
    // For local storage tracking
    var syncStatus: SyncStatus = .synced
    var localId: String = UUID().uuidString
    
    enum CodingKeys: String, CodingKey {
        case id
        case jobId = "job_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct NoteRequest: Codable {
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case content
    }
}


