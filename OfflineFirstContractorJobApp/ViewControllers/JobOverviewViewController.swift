//  JobOverviewViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class JobOverviewViewController: UIViewController {
    @IBOutlet weak var statusVew: UIView!
    @IBOutlet weak var budgetView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var budgetLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var clientNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var job: Job!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadJob()
        statusVew.layer.shadowColor = UIColor(hex: "#0000001A").cgColor
        statusVew.layer.shadowOpacity = 0.1
        statusVew.layer.shadowRadius = 4
        statusVew.layer.shadowOffset = CGSize(width: 0, height: 0)
        statusVew.layer.masksToBounds = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        budgetView.applyGradient(
            colors: [
                UIColor(hex: "#3B82F6"),
                UIColor(hex: "#2563EB")
            ],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        budgetView.cornerRadius = 20
        budgetView.layer.masksToBounds = true
    }

    func refreshData() {
        loadJob()
    }
    
    private func loadJob() {
        guard let job = job else { return }
        budgetLabel.text = String(format: "$%.0f", job.budget)
        locationLabel.text = job.city
        
        if let startDate = job.startDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: startDate) {
                formatter.dateFormat = "MMM d, yyyy"
                startDateLabel.text = formatter.string(from: date)
            } else {
                startDateLabel.text = startDate
            }
        } else {
            startDateLabel.text = "Not started"
        }
        
        clientNameLabel.text = job.clientName
        descriptionLabel.text = job.description?.isEmpty == false ? job.description : "No description available"
        
        // Status color
        switch job.status {
        case .active:
            statusLabel.textColor = UIColor(hex: "#0F172A")
        case .pending:
            statusLabel.textColor = UIColor(hex: "#0F172A")
        case .completed:
            statusLabel.textColor = UIColor(hex: "#0F172A")
        }
    }
    
    private func updateSyncStatus() {
        let pendingJobs = LocalStorageManager.shared.getPendingJobs()
        let pendingNotes = LocalStorageManager.shared.getPendingNotes()
        
        if NetworkManager.shared.isConnected {
            if pendingJobs.isEmpty && pendingNotes.isEmpty {
                statusLabel.text = "All changes synced"
            } else {
                statusLabel.text = "Syncing changes..."
            }
        } else {
            statusLabel.text = "Offline"
        }
    }
}

