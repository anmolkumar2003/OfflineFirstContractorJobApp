// JobNotesViewController.swift
// OfflineFirstContractorJobApp
// Created by mac on 10-01-2026.

import UIKit

class JobNotesViewController: UIViewController {

    @IBOutlet weak var notesTableView: UITableView!
    @IBOutlet weak var addNoteButton: UIButton!
    @IBOutlet weak var noteTextView: UITextView!

    var job: Job!
    private var notes: [Note] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadNotes()
        setupTextViewPlaceholder()
    }

    private func setupTableView() {
        notesTableView.delegate = self
        notesTableView.dataSource = self
        notesTableView.register(UINib(nibName: "NoteTableViewCell", bundle: nil), forCellReuseIdentifier: "NoteTableViewCell")
    }

    private func setupTextViewPlaceholder() {
        noteTextView.setPlaceholder("Add New Note..")
    }

    func loadNotes() {
        // Load from local storage
        let jobId = job.id ?? job.localId
        notes = LocalStorageManager.shared.getNotesForJob(jobId: jobId)
        notesTableView.reloadData()

        // Try to load from server if online
        if NetworkManager.shared.isConnected, let jobServerId = job.id {
            APIService.shared.getNotes(jobId: jobServerId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let serverNotes):
                        for note in serverNotes {
                            LocalStorageManager.shared.saveNote(note)
                        }
                        self?.loadNotes() // Reload after syncing
                    case .failure:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Add Note Directly from UITextView

    @IBAction func addNoteButtonTapped(_ sender: UIButton) {
        let content = noteTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Only add if user has typed something (not placeholder)
        guard !content.isEmpty, noteTextView.textColor != .lightGray else { return }

        createNote(content: content)

        // Clear textView and reset placeholder
        noteTextView.text = "Add New Note.."
        noteTextView.textColor = .lightGray
    }

    private func createNote(content: String) {
        let jobId = job.id ?? job.localId
        var newNote = Note(
            id: nil,
            jobId: jobId,
            content: content,
            createdAt: nil,
            updatedAt: nil
        )
        newNote.syncStatus = .pending

        // Save locally
        LocalStorageManager.shared.saveNote(newNote)
        LocalStorageManager.shared.addPendingNote(newNote)

        // Update table immediately
        notes.append(newNote)
        notesTableView.reloadData()

        // Sync with server if online
        guard NetworkManager.shared.isConnected, let jobServerId = job.id else { return }

        APIService.shared.createNote(jobId: jobServerId, content: content) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let createdNote):
                    if let index = self?.notes.firstIndex(where: { $0.localId == newNote.localId }) {
                        var syncedNote = createdNote
                        syncedNote.localId = newNote.localId
                        syncedNote.syncStatus = .synced
                        LocalStorageManager.shared.saveNote(syncedNote)
                        LocalStorageManager.shared.removePendingNote(localId: newNote.localId)

                        self?.notes[index] = syncedNote
                        self?.notesTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                case .failure:
                    break
                }
            }
        }
    }
}

// MARK: - UITableView DataSource & Delegate

extension JobNotesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableViewCell", for: indexPath) as! NoteTableViewCell
        cell.configure(with: notes[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let note = notes[indexPath.row]

        // Allow editing via alert (optional)
        let alert = UIAlertController(title: "Edit Note", message: "Update your note", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = note.content
        }

        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let content = textField.text?.trimmingCharacters(in: .whitespaces),
                  !content.isEmpty else { return }
            self?.updateNote(note, content: content)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(updateAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    private func updateNote(_ note: Note, content: String) {
        var updatedNote = note
        updatedNote.content = content
        updatedNote.syncStatus = .pending

        // Save locally
        LocalStorageManager.shared.saveNote(updatedNote)
        LocalStorageManager.shared.addPendingNote(updatedNote)
        loadNotes()

        // Sync with server
        if NetworkManager.shared.isConnected,
           let jobServerId = job.id,
           let noteId = note.id {
            APIService.shared.updateNote(jobId: jobServerId, noteId: noteId, content: content) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let syncedNote):
                        var finalNote = syncedNote
                        finalNote.localId = note.localId
                        finalNote.syncStatus = .synced
                        LocalStorageManager.shared.saveNote(finalNote)
                        LocalStorageManager.shared.removePendingNote(localId: note.localId)
                        self?.loadNotes()
                    case .failure:
                        break
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 135 }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 80 }
}

// MARK: - UITextView Placeholder

extension UITextView: UITextViewDelegate {
    func setPlaceholder(_ text: String, color: UIColor = .lightGray) {
        self.text = text
        self.textColor = color
        self.delegate = self
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add New Note.."
            textView.textColor = .lightGray
        }
    }
}
