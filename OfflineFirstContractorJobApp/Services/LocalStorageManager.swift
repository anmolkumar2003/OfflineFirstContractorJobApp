//
//  LocalStorageManager.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import Foundation

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let jobsKey = "saved_jobs"
    private let notesKey = "saved_notes"
    private let pendingJobsKey = "pending_jobs"
    private let pendingNotesKey = "pending_notes"
    private let pendingVideosKey = "pending_videos"
    
    private init() {}
    
    // MARK: - Jobs
    
    func saveJob(_ job: Job) {
        var jobs = getAllJobs()
        // Check if job exists by server ID first, then by local ID
        if let serverId = job.id, let index = jobs.firstIndex(where: { $0.id == serverId }) {
            jobs[index] = job
        } else if let index = jobs.firstIndex(where: { $0.localId == job.localId }) {
            jobs[index] = job
        } else {
            jobs.append(job)
        }
        saveJobs(jobs)
    }
    
    func getAllJobs() -> [Job] {
        guard let data = UserDefaults.standard.data(forKey: jobsKey),
              let jobs = try? JSONDecoder().decode([Job].self, from: data) else {
            return []
        }
        return jobs
    }
    
    func getJob(localId: String) -> Job? {
        return getAllJobs().first(where: { $0.localId == localId })
    }
    
    func getJob(serverId: String) -> Job? {
        return getAllJobs().first(where: { $0.id == serverId })
    }
    
    func jobExists(serverId: String?) -> Bool {
        guard let serverId = serverId else { return false }
        return getAllJobs().contains(where: { $0.id == serverId })
    }
    
    func deleteJob(localId: String) {
        var jobs = getAllJobs()
        jobs.removeAll(where: { $0.localId == localId })
        saveJobs(jobs)
    }
    
    private func saveJobs(_ jobs: [Job]) {
        if let data = try? JSONEncoder().encode(jobs) {
            UserDefaults.standard.set(data, forKey: jobsKey)
        }
    }
    
    // MARK: - Notes
    
    func saveNote(_ note: Note) {
        var notes = getAllNotes()
        if let index = notes.firstIndex(where: { $0.localId == note.localId }) {
            notes[index] = note
        } else {
            notes.append(note)
        }
        saveNotes(notes)
    }
    
    func getNotesForJob(jobId: String) -> [Note] {
        return getAllNotes().filter { note in
            note.jobId == jobId || (note.id != nil && note.jobId == jobId)
        }
    }
    
    func getAllNotes() -> [Note] {
        guard let data = UserDefaults.standard.data(forKey: notesKey),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return []
        }
        return notes
    }
    
    func deleteNote(localId: String) {
        var notes = getAllNotes()
        notes.removeAll(where: { $0.localId == localId })
        saveNotes(notes)
    }
    
    private func saveNotes(_ notes: [Note]) {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: notesKey)
        }
    }
    
    // MARK: - Pending Jobs
    
    func addPendingJob(_ job: Job) {
        var pending = getPendingJobs()
        // Check if already exists to avoid duplicates
        if !pending.contains(where: { $0.localId == job.localId }) {
            pending.append(job)
            savePendingJobs(pending)
        }
    }
    
    func getPendingJobs() -> [Job] {
        return getAllJobs().filter { $0.syncStatus == .pending }
    }
    
    func removePendingJob(localId: String) {
        // Update job sync status to synced instead of removing
        if var job = getJob(localId: localId) {
            job.syncStatus = .synced
            saveJob(job)
        }
    }
    
    private func savePendingJobs(_ jobs: [Job]) {
        // Pending jobs are tracked via syncStatus in the main jobs array
        // This method is kept for compatibility but doesn't need separate storage
        for job in jobs {
            var updatedJob = job
            updatedJob.syncStatus = .pending
            saveJob(updatedJob)
        }
    }
    
    // MARK: - Pending Notes
    
    func addPendingNote(_ note: Note) {
        var pending = getPendingNotes()
        if !pending.contains(where: { $0.localId == note.localId }) {
            pending.append(note)
            savePendingNotes(pending)
        }
    }
    
    func getPendingNotes() -> [Note] {
        return getAllNotes().filter { $0.syncStatus == .pending }
    }
    
    func removePendingNote(localId: String) {
        if var note = getAllNotes().first(where: { $0.localId == localId }) {
            note.syncStatus = .synced
            saveNote(note)
        }
    }
    
    private func savePendingNotes(_ notes: [Note]) {
        // Pending notes are tracked via syncStatus in the main notes array
        for note in notes {
            var updatedNote = note
            updatedNote.syncStatus = .pending
            saveNote(updatedNote)
        }
    }
    
    // MARK: - Pending Videos
    
    struct PendingVideo: Codable {
        let jobId: String
        let localJobId: String
        let videoPath: String
        let localId: String
    }
    
    func addPendingVideo(jobId: String, localJobId: String, videoPath: String) {
        var pending = getPendingVideos()
        let video = PendingVideo(jobId: jobId, localJobId: localJobId, videoPath: videoPath, localId: UUID().uuidString)
        pending.append(video)
        savePendingVideos(pending)
    }
    
    func getPendingVideos() -> [PendingVideo] {
        guard let data = UserDefaults.standard.data(forKey: pendingVideosKey),
              let videos = try? JSONDecoder().decode([PendingVideo].self, from: data) else {
            return []
        }
        return videos
    }
    
    func removePendingVideo(localId: String) {
        var pending = getPendingVideos()
        pending.removeAll(where: { $0.localId == localId })
        savePendingVideos(pending)
    }
    
    private func savePendingVideos(_ videos: [PendingVideo]) {
        if let data = try? JSONEncoder().encode(videos) {
            UserDefaults.standard.set(data, forKey: pendingVideosKey)
        }
    }
    
    // MARK: - Clear All Data (for logout/new account)
    
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: jobsKey)
        UserDefaults.standard.removeObject(forKey: notesKey)
        UserDefaults.standard.removeObject(forKey: pendingJobsKey)
        UserDefaults.standard.removeObject(forKey: pendingNotesKey)
        UserDefaults.standard.removeObject(forKey: pendingVideosKey)
        UserDefaults.standard.synchronize()
    }
}
