//  JobTableViewCell.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class JobTableViewCell: UITableViewCell {
    
    @IBOutlet weak var statusImg: UIImageView!
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var clientNameLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var budgetLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        statusView.layer.cornerRadius = 8
    }
    
    func configure(with job: Job) {
        jobTitleLabel.text = job.title
        clientNameLabel.text = job.clientName
        statusLabel.text = job.status.displayName
        budgetLabel.text = String(format: "$%.0f", job.budget)
        locationLabel.text = job.city
        
        if let startDate = job.startDate {
            startDateLabel.text = "Started \(formatDate(startDate))"
        } else {
            startDateLabel.text = "Not started"
        }
        
        // Status color
        switch job.status {
        case .active:
            statusView.backgroundColor = UIColor(hex: "#10B981", alpha: 0.2)
            statusLabel.textColor = UIColor(hex: "#10B981")
            statusImg.image = UIImage(named: "active")
        case .pending:
            statusView.backgroundColor = UIColor(hex: "#F59E0B", alpha: 0.1)
            statusLabel.textColor = UIColor(hex: "#F59E0B")
            statusImg.image = UIImage(named: "pendingIcon")
        case .completed:
            statusView.backgroundColor = UIColor(hex: "#3B82F6", alpha: 0.2)
            statusLabel.textColor = UIColor(hex: "#3B82F6")
            statusImg.image = UIImage(named: "")

        }
        
            }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}


