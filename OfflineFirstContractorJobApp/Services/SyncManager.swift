//
//  SyncManager.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import Foundation
import Network

class SyncManager {
    static let shared = SyncManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isOnline = false
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wasOnline = self?.isOnline ?? false
            self?.isOnline = path.status == .satisfied
            
            if self?.isOnline == true && !wasOnline {
                // Just came online, trigger sync
                DispatchQueue.main.async {
                    self?.syncAll()
                    NotificationCenter.default.post(name: NSNotification.Name("NetworkStatusChanged"), object: nil)
                }
            }
            
            if self?.isOnline == false && wasOnline {
                // Just went offline
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("NetworkStatusChanged"), object: nil)
                }
            }
        }
        monitor.start(queue: queue)
        
        // Check initial status
        isOnline = monitor.currentPath.status == .satisfied
        if isOnline {
            syncAll()
        }
    }
    
    func isNetworkAvailable() -> Bool {
        return isOnline
    }
    
    // MARK: - Sync Operations
    
    func syncAll() {
        guard isNetworkAvailable() else { return }
        
        syncPendingJobs()
        syncPendingNotes()
        syncPendingVideos()
    }
    
    private func syncPendingJobs() {
        let pendingJobs = LocalStorageManager.shared.getPendingJobs()
        
        for job in pendingJobs {
            let jobRequest = JobRequest(
                title: job.title,
                description: job.description,
                clientName: job.clientName,
                city: job.city,
                budget: job.budget,
                startDate: job.startDate,
                status: job.status.rawValue
            )
            
            if let jobId = job.id {
                // Update existing job
                APIService.shared.updateJob(id: jobId, jobRequest) { [weak self] result in
                    switch result {
                    case .success(let updatedJob):
                        var syncedJob = updatedJob
                        syncedJob.syncStatus = .synced
                        syncedJob.localId = job.localId
                        LocalStorageManager.shared.saveJob(syncedJob)
                        LocalStorageManager.shared.removePendingJob(localId: job.localId)
                    case .failure:
                        var failedJob = job
                        failedJob.syncStatus = .failed
                        LocalStorageManager.shared.saveJob(failedJob)
                    }
                }
            } else {
                // Create new job
                APIService.shared.createJob(jobRequest) { [weak self] result in
                    switch result {
                    case .success(let createdJob):
                        var syncedJob = createdJob
                        syncedJob.localId = job.localId
                        syncedJob.syncStatus = .synced
                        LocalStorageManager.shared.saveJob(syncedJob)
                        LocalStorageManager.shared.removePendingJob(localId: job.localId)
                    case .failure:
                        var failedJob = job
                        failedJob.syncStatus = .failed
                        LocalStorageManager.shared.saveJob(failedJob)
                    }
                }
            }
        }
    }
    
    private func syncPendingNotes() {
        let pendingNotes = LocalStorageManager.shared.getPendingNotes()
        
        for note in pendingNotes {
            if let noteId = note.id {
                // Update existing note
                APIService.shared.updateNote(jobId: note.jobId, noteId: noteId, content: note.content) { result in
                    switch result {
                    case .success(let updatedNote):
                        var syncedNote = updatedNote
                        syncedNote.localId = note.localId
                        syncedNote.syncStatus = .synced
                        LocalStorageManager.shared.saveNote(syncedNote)
                        LocalStorageManager.shared.removePendingNote(localId: note.localId)
                    case .failure:
                        var failedNote = note
                        failedNote.syncStatus = .failed
                        LocalStorageManager.shared.saveNote(failedNote)
                    }
                }
            } else {
                // Create new note - need to get job server ID first
                let jobs = LocalStorageManager.shared.getAllJobs()
                if let job = jobs.first(where: { $0.localId == note.jobId || $0.id == note.jobId }) {

                    let jobServerId = job.id ?? job.localId

                    APIService.shared.createNote(jobId: jobServerId, content: note.content) { result in
                        switch result {
                        case .success(let createdNote):
                            var syncedNote = createdNote
                            syncedNote.localId = note.localId
                            syncedNote.syncStatus = .synced
                            LocalStorageManager.shared.saveNote(syncedNote)
                            LocalStorageManager.shared.removePendingNote(localId: note.localId)

                        case .failure:
                            var failedNote = note
                            failedNote.syncStatus = .failed
                            LocalStorageManager.shared.saveNote(failedNote)
                        }
                    }
                }
            }
        }
    }
    private func syncPendingVideos() {
        let pendingVideos = LocalStorageManager.shared.getPendingVideos()
        
        for video in pendingVideos {
            guard let videoURL = URL(string: video.videoPath),
                  let videoData = try? Data(contentsOf: videoURL) else {
                continue
            }
            
            let jobs = LocalStorageManager.shared.getAllJobs()
            guard let job = jobs.first(where: {
                $0.localId == video.localJobId || $0.id == video.localJobId
            }) else {
                continue
            }
            
            let jobServerId = job.id ?? job.localId
            
            APIService.shared.uploadVideo(jobId: jobServerId, videoData: videoData) { result in
                switch result {
                case .success:
                    LocalStorageManager.shared.removePendingVideo(localId: video.localId)
                case .failure:
                    // Keep video in pending for retry
                    break
                }
            }
        }
    }

    
    // MARK: - Manual Sync Trigger
    
    func triggerSync() {
        if isNetworkAvailable() {
            syncAll()
        }
    }
}

