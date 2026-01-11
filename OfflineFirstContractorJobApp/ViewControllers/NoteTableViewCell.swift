//
//  NoteTableViewCell.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import UIKit

class NoteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    //@IBOutlet weak var syncIndicatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
//        containerView.layer.cornerRadius = 8
//        containerView.layer.shadowColor = UIColor.black.cgColor
//        containerView.layer.shadowOpacity = 0.05
//        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
//        containerView.layer.shadowRadius = 2
//        
        //syncIndicatorView.layer.cornerRadius = 4
    }
    
    func configure(with note: Note) {
        contentLabel.text = note.content
        
        if let createdAt = note.createdAt {
            dateLabel.text = formatDate(createdAt)
        } else if let updatedAt = note.updatedAt {
            dateLabel.text = "Updated \(formatDate(updatedAt))"
        } else {
            dateLabel.text = "Pending"
        }
        
        // Sync indicator
       // switch note.syncStatus {
//        case .synced:
//            syncIndicatorView.backgroundColor = UIColor(hex: "#10B981")
//        case .pending:
//            syncIndicatorView.backgroundColor = UIColor(hex: "#F59E0B")
//        case .failed:
//            syncIndicatorView.backgroundColor = UIColor(hex: "#EF4444")
        //}
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: date)
        }
        return dateString
    }
}


