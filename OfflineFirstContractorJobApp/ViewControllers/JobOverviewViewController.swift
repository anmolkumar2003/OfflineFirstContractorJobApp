//
//  JobOverviewViewController.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import UIKit

class JobOverviewViewController: UIViewController {
    @IBOutlet weak var budgetView: UIView!
    
    @IBOutlet weak var statusView: UIView!
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
    }

    func refreshData() {
        loadJob()
    }
    
    private func loadJob() {
        guard let job = job else { return }
        statusLabel.text = job.status.displayName
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
            statusView.backgroundColor = UIColor(hex: "#10B981", alpha: 0.2)
            statusLabel.textColor = UIColor(hex: "#10B981")
        case .pending:
            statusView.backgroundColor = UIColor(hex: "#F59E0B", alpha: 0.2)
            statusLabel.textColor = UIColor(hex: "#F59E0B")
        case .completed:
            statusView.backgroundColor = UIColor(hex: "#3B82F6", alpha: 0.2)
            statusLabel.textColor = UIColor(hex: "#3B82F6")
        }
        
        statusView.layer.cornerRadius = 8
    }
}


