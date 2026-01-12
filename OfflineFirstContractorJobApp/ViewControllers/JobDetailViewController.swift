//  JobDetailViewController.swift
//  OfflineFirstContractorJobApp
//  Created by mac on 10-01-2026.

import UIKit
import AVKit
import AVFoundation

class JobDetailViewController: UIViewController {
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var clientNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    
    var job: Job!
    
    private var overviewViewController: JobOverviewViewController!
    private var notesViewController: JobNotesViewController!
    private var videoViewController: JobVideoViewController!
    
    private var currentViewController: UIViewController?
    private var actualContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContainerView()
        setupUI()
        setupSegmentedControl()
        setupViewControllers()
        showOverview()
    }
    
    private func setupContainerView() {
        // If containerView is connected to the main view, create a proper container
        if containerView == view {
            actualContainerView = UIView()
            actualContainerView.translatesAutoresizingMaskIntoConstraints = false
            actualContainerView.backgroundColor = .clear
            view.addSubview(actualContainerView)
            
            // Find the header view (the view that contains jobTitleLabel and segmentedControl)
            var headerView: UIView?
            var currentView: UIView? = jobTitleLabel.superview
            while currentView != nil && currentView != view {
                if currentView?.subviews.contains(segmentedControl) == true {
                    headerView = currentView
                    break
                }
                currentView = currentView?.superview
            }
            
            if let headerView = headerView {
                NSLayoutConstraint.activate([
                    actualContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
                    actualContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    actualContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    actualContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            } else {
                // Fallback: position below segmented control
                NSLayoutConstraint.activate([
                    actualContainerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
                    actualContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    actualContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    actualContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            }
        } else {
            actualContainerView = containerView
        }
    }
    
    private func setupUI() {
        jobTitleLabel.text = job.title
        clientNameLabel.text = job.clientName
        editButton.layer.cornerRadius = 18
        statusView.layer.shadowColor = UIColor(hex: "#0000001A").cgColor
        statusView.layer.shadowOpacity = 0.1
        statusView.layer.shadowRadius = 20
        statusView.layer.shadowOffset = CGSize(width: 0, height: 0)
        statusView.layer.masksToBounds = false
    }
    
    //  Setup segmented control with icons
    private func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        
        let segments: [(icon: String, title: String)] = [
            ("doc.text.fill", "Overview"),
            ("note.text", "Notes"),
            ("video.fill", "Video")
        ]
        
        for (index, segment) in segments.enumerated() {
            let isSelected = index == 0
            let iconColor = isSelected ? UIColor(hex: "#3B82F6") : UIColor(hex: "#64748B")
            let icon = UIImage(systemName: segment.icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
            let tintedIcon = icon?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
            let imageWithText = createImageWithText(icon: tintedIcon, text: segment.title, isSelected: isSelected)
            segmentedControl.insertSegment(with: imageWithText, at: index, animated: false)
        }
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = UIColor(hex: "#F1F5F9")
        
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = UIColor.white
            segmentedControl.layer.cornerRadius = 12
            segmentedControl.clipsToBounds = true
        }
        
        segmentedControl.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }
    
    private func createImageWithText(icon: UIImage?, text: String, isSelected: Bool) -> UIImage? {
        let iconSize: CGFloat = 18
        let textSize: CGFloat = 14
        let spacing: CGFloat = 6
        let padding: CGFloat = 12
        
        let textColor = isSelected ? UIColor(hex: "#3B82F6") : UIColor(hex: "#64748B")
        let font = isSelected ? UIFont.systemFont(ofSize: textSize, weight: .semibold) : UIFont.systemFont(ofSize: textSize, weight: .regular)
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let textSize_actual = (text as NSString).size(withAttributes: textAttributes)
        
        let totalWidth = iconSize + spacing + textSize_actual.width + (padding * 2)
        let totalHeight = max(iconSize, textSize_actual.height) + (padding * 2)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { context in
            var currentX: CGFloat = padding
            
            if let icon = icon {
                let iconY = (totalHeight - iconSize) / 2
                let iconRect = CGRect(x: currentX, y: iconY, width: iconSize, height: iconSize)
                icon.draw(in: iconRect)
                currentX += iconSize + spacing
            }
            let textY = (totalHeight - textSize_actual.height) / 2
            let textRect = CGRect(x: currentX, y: textY, width: textSize_actual.width, height: textSize_actual.height)
            (text as NSString).draw(in: textRect, withAttributes: textAttributes)
        }
    }
    
    private func setupViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        overviewViewController = storyboard.instantiateViewController(withIdentifier: "JobOverviewViewController") as? JobOverviewViewController
        overviewViewController.job = job
        
        notesViewController = storyboard.instantiateViewController(withIdentifier: "JobNotesViewController") as? JobNotesViewController
        notesViewController.job = job
        
        videoViewController = storyboard.instantiateViewController(withIdentifier: "JobVideoViewController") as? JobVideoViewController
        videoViewController.job = job
    }
    
    private func showOverview() {
        removeCurrentViewController()
        addChild(overviewViewController)
        actualContainerView.addSubview(overviewViewController.view)
        overviewViewController.view.frame = actualContainerView.bounds
        overviewViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overviewViewController.didMove(toParent: self)
        currentViewController = overviewViewController
    }
    
    private func showNotes() {
        removeCurrentViewController()
        addChild(notesViewController)
        actualContainerView.addSubview(notesViewController.view)
        notesViewController.view.frame = actualContainerView.bounds
        notesViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        notesViewController.didMove(toParent: self)
        currentViewController = notesViewController
    }
    
    private func showVideo() {
        removeCurrentViewController()
        addChild(videoViewController)
        actualContainerView.addSubview(videoViewController.view)
        videoViewController.view.frame = actualContainerView.bounds
        videoViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        videoViewController.didMove(toParent: self)
        currentViewController = videoViewController
    }
    
    private func removeCurrentViewController() {
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let createJobVC = storyboard.instantiateViewController(withIdentifier: "CreateJobViewController") as? CreateJobViewController {
            createJobVC.existingJob = job
            createJobVC.delegate = self
            navigationController?.pushViewController(createJobVC, animated: true)
        }
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        updateSegmentImages()
        
        switch sender.selectedSegmentIndex {
        case 0:
            showOverview()
        case 1:
            showNotes()
        case 2:
            showVideo()
        default:
            break
        }
    }
    
    private func updateSegmentImages() {
        let segments: [(icon: String, title: String)] = [
            ("doc.text.fill", "Overview"),
            ("note.text", "Notes"),
            ("video.fill", "Video")
        ]
        
        for (index, segment) in segments.enumerated() {
            let isSelected = segmentedControl.selectedSegmentIndex == index
            let iconColor = isSelected ? UIColor(hex: "#3B82F6") : UIColor(hex: "#64748B")
            let icon = UIImage(systemName: segment.icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
            let tintedIcon = icon?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
            
            let imageWithText = createImageWithText(icon: tintedIcon, text: segment.title, isSelected: isSelected)
            segmentedControl.setImage(imageWithText, forSegmentAt: index)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

extension JobDetailViewController: CreateJobDelegate {
    func jobCreated(_ job: Job) {
        self.job = job
        jobTitleLabel.text = job.title
        clientNameLabel.text = job.clientName
        
        overviewViewController.job = job
        notesViewController.job = job
        videoViewController.job = job
        
        if segmentedControl.selectedSegmentIndex == 0 {
            overviewViewController.refreshData()
        } else if segmentedControl.selectedSegmentIndex == 1 {
            notesViewController.loadNotes()
        }
    }
}
