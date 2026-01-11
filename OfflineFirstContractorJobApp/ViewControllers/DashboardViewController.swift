//  DashboardViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var jobCountLbl: UILabel!
    @IBOutlet weak var userNameBtn: UIButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var jobsTableView: UITableView!
    @IBOutlet weak var syncStatusLabel: UILabel!
    
    private var jobs: [Job] = []
    private var filteredJobs: [Job] = []
    private var isSearching = false
    private var isShowingAllJobs = false
    private let maxJobsToShow = 3
    private var isShowingErrorAlert = false

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
        print("🔑 TOKEN:", UserDefaults.standard.string(forKey: "authToken") ?? "nil")
    }
    
    private func setupUI() {
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
        welcomeLabel.text = "\(userName)"
        let firstChar = userName.prefix(1).uppercased()
        userNameBtn.setTitle(firstChar, for: .normal)
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
            } else {
                syncStatusLabel.text = "Syncing changes..."
            }
        } else {
            syncStatusLabel.text = "Offline"
        }
    }
    
    private func loadJobs() {
        jobs = LocalStorageManager.shared.getAllJobs()
        filteredJobs = jobs
        isShowingAllJobs = false
        jobCountLbl.text = "Your Jobs (\(jobs.count))"
        
        jobsTableView.reloadData()
        updateSyncStatus()
        
        if NetworkManager.shared.isConnected {
            loadJobsFromServer()
        } else {
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
                guard let self = self else { return }

                switch result {

                case .success(let serverJobs):
                    for serverJob in serverJobs {
                        guard let serverId = serverJob.id else { continue }

                        if let existingJob = LocalStorageManager.shared.getJob(serverId: serverId) {
                            var updatedJob = serverJob
                            updatedJob.localId = existingJob.localId
                            updatedJob.syncStatus = existingJob.syncStatus
                            LocalStorageManager.shared.saveJob(updatedJob)
                        } else {
                            var jobToSave = serverJob
                            jobToSave.localId = UUID().uuidString
                            jobToSave.syncStatus = .synced
                            LocalStorageManager.shared.saveJob(jobToSave)
                        }
                    }

                    self.loadJobs()
                    SyncManager.shared.syncAll()

                case .failure(let error):
                    let nsError = error as NSError

                    guard !self.isShowingErrorAlert else { return }
                    self.isShowingErrorAlert = true

                    let message: String
                    switch nsError.code {
                    case 401:
                        message = "Session expired. Please login again."
                    case 500:
                        message = "Server error. Try again later."
                    default:
                        message = nsError.domain
                    }

                    self.showErrorAlert(message: message) {
                        self.isShowingErrorAlert = false
                    }
                }
            }
        }
    }

    
    private func showErrorAlert(message: String, onDismiss: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                onDismiss?()
            }
        )

        // Prevent presenting multiple alerts
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }

    @IBAction func viewAllBtn(_ sender: UIButton) {
        isShowingAllJobs = true
        jobsTableView.reloadData()
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
        let list = isSearching ? filteredJobs : jobs
        if isShowingAllJobs {
            return list.count
        }
        return min(list.count, maxJobsToShow)
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "JobTableViewCell",
            for: indexPath
        ) as! JobTableViewCell
        
        let job = isSearching
        ? filteredJobs[indexPath.row]
        : jobs[indexPath.row]
        
        cell.configure(with: job)
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let job = isSearching
        ? filteredJobs[indexPath.row]
        : jobs[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let jobDetailVC = storyboard.instantiateViewController(
            withIdentifier: "JobDetailViewController"
        ) as? JobDetailViewController else { return }
        
        jobDetailVC.job = job
        navigationController?.pushViewController(jobDetailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
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


