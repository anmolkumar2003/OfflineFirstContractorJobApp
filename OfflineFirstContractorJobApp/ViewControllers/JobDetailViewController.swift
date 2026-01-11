//
//  JobDetailViewController.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import UIKit
import AVKit
import AVFoundation

class JobDetailViewController: UIViewController {
    
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
        
        editButton.layer.cornerRadius = 8
        editButton.layer.borderWidth = 1
        editButton.layer.borderColor = UIColor(hex: "#3B82F6").cgColor
        
        // Update segmented control titles if needed
        if segmentedControl.numberOfSegments >= 3 {
            segmentedControl.setTitle("Overview", forSegmentAt: 0)
            segmentedControl.setTitle("Notes", forSegmentAt: 1)
            segmentedControl.setTitle("Video", forSegmentAt: 2)
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
