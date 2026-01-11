//  DashboardViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var jobsTableView: UITableView!
    @IBOutlet weak var syncStatusView: UIView!
    @IBOutlet weak var syncStatusLabel: UILabel!
    
    private var jobs: [Job] = []
    private var filteredJobs: [Job] = []
    private var isSearching = false
    private var isShowingAllJobs = false
    private let maxJobsToShow = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSyncStatus()
        loadJobs()
        
        // Start network monitoring
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange),
            name: NSNotification.Name("NetworkStatusChanged"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadJobs()
        updateSyncStatus()
    }
    
    private func setupUI() {
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
        welcomeLabel.text = "Welcome back, \(userName)"
        
        navigationController?.navigationBar.isHidden = true
        
        // Setup search bar
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search jobs..."
    }
    
    private func setupTableView() {
        jobsTableView.delegate = self
        jobsTableView.dataSource = self
        jobsTableView.register(UINib(nibName: "JobTableViewCell", bundle: nil), forCellReuseIdentifier: "JobTableViewCell")
        jobsTableView.separatorStyle = .none
    }
    
    private func setupSyncStatus() {
        syncStatusView.layer.cornerRadius = 8
        syncStatusView.backgroundColor = UIColor(hex: "#10B981", alpha: 0.1)
        updateSyncStatus()
    }
    
    @objc private func handleNetworkChange() {
        DispatchQueue.main.async {
            self.updateSyncStatus()
            if NetworkManager.shared.isConnected {
                self.loadJobsFromServer()
            }
        }
    }
    
    private func updateSyncStatus() {
        let pendingJobs = LocalStorageManager.shared.getPendingJobs()
        let pendingNotes = LocalStorageManager.shared.getPendingNotes()
        
        if NetworkManager.shared.isConnected {
            if pendingJobs.isEmpty && pendingNotes.isEmpty {
                syncStatusLabel.text = "All changes synced"
                syncStatusView.backgroundColor = UIColor(hex: "#10B981", alpha: 0.1)
            } else {
                syncStatusLabel.text = "Syncing changes..."
                syncStatusView.backgroundColor = UIColor(hex: "#F59E0B", alpha: 0.1)
            }
        } else {
            syncStatusLabel.text = "Offline"
            syncStatusView.backgroundColor = UIColor(hex: "#EF4444", alpha: 0.1)
        }
    }
    
    private func loadJobs() {
        // Load from local storage first
        jobs = LocalStorageManager.shared.getAllJobs()
        filteredJobs = jobs
        isShowingAllJobs = false
        jobsTableView.reloadData()
        updateSyncStatus()
        
        // Try to sync with server if online
        if NetworkManager.shared.isConnected {
            loadJobsFromServer()
        } else {
            // Try to sync pending items
            SyncManager.shared.syncAll()
        }
    }
    
    private func showAllJobs() {
        isShowingAllJobs = true
        jobsTableView.reloadData()
    }
    
    private func loadJobsFromServer() {
        APIService.shared.getJobs { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let serverJobs):
                    // Merge with local jobs - only add if not exists
                    for serverJob in serverJobs {
                        guard let serverId = serverJob.id else { continue }
                        
                        // Check if job already exists by server ID
                        if let existingJob = LocalStorageManager.shared.getJob(serverId: serverId) {
                            // Job exists - update it with server data but preserve localId and syncStatus if pending
                            var updatedJob = serverJob
                            updatedJob.localId = existingJob.localId
                            // Only update sync status to synced if it was synced before
                            // Keep pending status if it was pending
                            if existingJob.syncStatus == .synced {
                                updatedJob.syncStatus = .synced
                            } else {
                                updatedJob.syncStatus = existingJob.syncStatus
                            }
                            LocalStorageManager.shared.saveJob(updatedJob)
                        } else {
                            // New job from server - create with new localId
                            var jobToSave = serverJob
                            jobToSave.localId = UUID().uuidString
                            jobToSave.syncStatus = .synced
                            LocalStorageManager.shared.saveJob(jobToSave)
                        }
                    }
                    self?.loadJobs()
                    SyncManager.shared.syncAll()
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.code != -1009 { // Not a network error
                        let errorMessage = nsError.code == 500 ? "Server error. Please try again later." : error.localizedDescription
                        print("Error loading jobs: \(errorMessage)")
                        // Show user-friendly error message for 500 errors
                        if nsError.code == 500 {
                            self?.showErrorAlert(message: "Server error occurred. Your local jobs are still available.")
                        }
                    }
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func createJobButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let createJobVC = storyboard.instantiateViewController(withIdentifier: "CreateJobViewController") as? CreateJobViewController {
            createJobVC.delegate = self
            navigationController?.pushViewController(createJobVC, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension DashboardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let jobCount = isSearching ? filteredJobs.count : jobs.count
        
        // If not searching and not showing all, add 1 for "View All" button
        if !isSearching && !isShowingAllJobs && jobCount > maxJobsToShow {
            return maxJobsToShow + 1
        }
        
        return jobCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let jobCount = isSearching ? filteredJobs.count : jobs.count
        
        // Show "View All" button cell
        if !isSearching && !isShowingAllJobs && jobCount > maxJobsToShow && indexPath.row == maxJobsToShow {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "ViewAllCell")
            cell.textLabel?.text = "View All (\(jobCount) jobs)"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor(hex: "#3B82F6")
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            cell.selectionStyle = .default
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "JobTableViewCell", for: indexPath) as! JobTableViewCell
        let job = isSearching ? filteredJobs[indexPath.row] : jobs[indexPath.row]
        cell.configure(with: job)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let jobCount = isSearching ? filteredJobs.count : jobs.count
        
        // Handle "View All" button tap
        if !isSearching && !isShowingAllJobs && jobCount > maxJobsToShow && indexPath.row == maxJobsToShow {
            showAllJobs()
            return
        }
        
        let job = isSearching ? filteredJobs[indexPath.row] : jobs[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let jobDetailVC = storyboard.instantiateViewController(withIdentifier: "JobDetailViewController") as? JobDetailViewController {
            jobDetailVC.job = job
            navigationController?.pushViewController(jobDetailVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}

// MARK: - UISearchBarDelegate

extension DashboardViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredJobs = jobs
            isShowingAllJobs = false
        } else {
            isSearching = true
            filteredJobs = jobs.filter { job in
                job.title.lowercased().contains(searchText.lowercased()) ||
                job.clientName.lowercased().contains(searchText.lowercased()) ||
                job.city.lowercased().contains(searchText.lowercased())
            }
        }
        jobsTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - CreateJobDelegate

extension DashboardViewController: CreateJobDelegate {
    func jobCreated(_ job: Job) {
        loadJobs()
    }
}


