//  SyncManager.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import Foundation
import Network

final class SyncManager {

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
            guard let self else { return }

            let wasOnline = self.isOnline
            self.isOnline = path.status == .satisfied

            if self.isOnline && !wasOnline {
                DispatchQueue.main.async {
                    self.syncAll()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NetworkStatusChanged"),
                        object: true
                    )
                }
            }

            if !self.isOnline && wasOnline {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NetworkStatusChanged"),
                        object: false
                    )
                }
            }
        }

        monitor.start(queue: queue)
        isOnline = monitor.currentPath.status == .satisfied

        if isOnline {
            syncAll()
        }
    }

    func isNetworkAvailable() -> Bool {
        return isOnline
    }

    // MARK: - Sync Entry Point

    func syncAll() {
        guard isOnline else { return }

        syncPendingJobs()
        syncPendingNotes()
        syncPendingVideos()
    }

    // MARK: - JOB SYNC

    private func syncPendingJobs() {
        let pendingJobs = LocalStorageManager.shared.getPendingJobs()

        for job in pendingJobs {

            let jobRequest = JobRequest(
                clientJobId: job.localId,
                title: job.title,
                description: job.description,
                clientName: job.clientName,
                city: job.city,
                budget: job.budget,
                startDate: job.startDate ?? "",
                status: job.status.rawValue
            )

            // UPDATE
            if let serverId = job.id {
                APIService.shared.updateJob(id: serverId, jobRequest) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let updatedJob):
                            var synced = updatedJob
                            synced.localId = job.localId
                            synced.syncStatus = .synced
                            LocalStorageManager.shared.saveJob(synced)

                        case .failure:
                            var failed = job
                            failed.syncStatus = .failed
                            LocalStorageManager.shared.saveJob(failed)
                        }
                    }
                }

            }
            // CREATE
            else {
                APIService.shared.createJob(jobRequest) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let createdJob):
                            var synced = createdJob
                            synced.localId = job.localId
                            synced.syncStatus = .synced
                            LocalStorageManager.shared.saveJob(synced)

                        case .failure:
                            var failed = job
                            failed.syncStatus = .failed
                            LocalStorageManager.shared.saveJob(failed)
                        }
                    }
                }
            }
        }
    }

    // MARK: - NOTES SYNC

    private func syncPendingNotes() {
        let pendingNotes = LocalStorageManager.shared.getPendingNotes()
        let jobs = LocalStorageManager.shared.getAllJobs()

        for note in pendingNotes {

            guard let job = jobs.first(where: {
                $0.localId == note.jobId || $0.id == note.jobId
            }) else { continue }

            guard let jobServerId = job.id else {
                // Job not synced yet → wait
                continue
            }

            // UPDATE
            if let noteId = note.id {
                APIService.shared.updateNote(
                    jobId: jobServerId,
                    noteId: noteId,
                    content: note.content
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let updated):
                            var synced = updated
                            synced.localId = note.localId
                            synced.syncStatus = .synced
                            LocalStorageManager.shared.saveNote(synced)

                        case .failure:
                            var failed = note
                            failed.syncStatus = .failed
                            LocalStorageManager.shared.saveNote(failed)
                        }
                    }
                }

            }
            // CREATE
            else {
                APIService.shared.createNote(
                    jobId: jobServerId,
                    content: note.content
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let created):
                            var synced = created
                            synced.localId = note.localId
                            synced.syncStatus = .synced
                            LocalStorageManager.shared.saveNote(synced)

                        case .failure:
                            var failed = note
                            failed.syncStatus = .failed
                            LocalStorageManager.shared.saveNote(failed)
                        }
                    }
                }
            }
        }
    }

    // MARK: - VIDEOS SYNC

    private func syncPendingVideos() {
        let pendingVideos = LocalStorageManager.shared.getPendingVideos()
        let jobs = LocalStorageManager.shared.getAllJobs()

        for video in pendingVideos {

            guard let job = jobs.first(where: {
                $0.localId == video.localJobId || $0.id == video.localJobId
            }),
            let jobServerId = job.id,
            let videoURL = URL(string: video.videoPath),
            let videoData = try? Data(contentsOf: videoURL)
            else { continue }

            APIService.shared.uploadVideo(
                jobId: jobServerId,
                videoData: videoData
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        LocalStorageManager.shared.removePendingVideo(
                            localId: video.localId
                        )
                    case .failure:
                        break // retry later
                    }
                }
            }
        }
    }

    // MARK: - Manual Trigger

    func triggerSync() {
        guard isOnline else { return }
        syncAll()
    }
}
