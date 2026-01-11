//  NoteTableViewCell.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit

class NoteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        containerView.applyGradient(
            colors: [
                UIColor(hex: "#3B82F6"),
                UIColor(hex: "#00000000")
            ],
            startPoint: CGPoint(x: 0.5, y: 0.0),
            endPoint: CGPoint(x: 0.5, y: 1.0)
        )
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


