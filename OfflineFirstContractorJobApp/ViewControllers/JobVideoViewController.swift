//
//  JobVideoViewController.swift
//  OfflineFirstContractorJobApp
//
//  Created by mac on 10-01-2026.
//

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

class JobVideoViewController: UIViewController {
    
    @IBOutlet weak var selectVideoButton: UIButton!
    @IBOutlet weak var videoStatusLabel: UILabel!
    @IBOutlet weak var videoPlayerView: UIView!
    
    var job: Job!
    private var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        selectVideoButton.layer.cornerRadius = 16
        videoStatusLabel.text = "No video selected"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        selectVideoButton.applyGradient(
            colors: [
                UIColor(hex: "#3B82F6"),
                UIColor(hex: "#2563EB")
            ],
            cornerRadius: 16,
            shadowColor: UIColor(hex: "#3B82F6", alpha: 0.2)
        )
        playerLayer?.frame = videoPlayerView.bounds
    }
    
    @IBAction func selectVideoButtonTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoQuality = .typeMedium
        present(picker, animated: true)
    }
    
    private func saveVideoLocally(videoURL: URL) {
        // Copy video to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("\(UUID().uuidString).mp4")
        
        do {
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            self.videoURL = destinationURL
            
            // Save pending video
            let jobId = job.id ?? job.localId
            let localJobId = job.localId
            LocalStorageManager.shared.addPendingVideo(
                jobId: jobId,
                localJobId: localJobId,
                videoPath: destinationURL.absoluteString
            )
            
            videoStatusLabel.text = "Video saved locally. Will upload when online."
            
            // Try to upload if online
            if NetworkManager.shared.isConnected, let jobServerId = job.id {
                uploadVideo(videoURL: destinationURL)
            }
        } catch {
            videoStatusLabel.text = "Error saving video: \(error.localizedDescription)"
        }
    }
    
    private func uploadVideo(videoURL: URL) {
        guard let videoData = try? Data(contentsOf: videoURL),
              let jobServerId = job.id else {
            return
        }
        
        videoStatusLabel.text = "Uploading video..."
        selectVideoButton.isEnabled = false
        
        APIService.shared.uploadVideo(jobId: jobServerId, videoData: videoData) { [weak self] result in
            DispatchQueue.main.async {
                self?.selectVideoButton.isEnabled = true
                
                switch result {
                case .success:
                    self?.videoStatusLabel.text = "Video uploaded successfully"
                    // Remove from pending
                    if let localId = self?.videoURL?.lastPathComponent {
                        // Remove pending video entry
                    }
                case .failure(let error):
                    self?.videoStatusLabel.text = "Upload failed. Will retry when online."
                }
            }
        }
    }
    
    private func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer?.removeFromSuperlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoPlayerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        videoPlayerView.layer.addSublayer(playerLayer!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playPauseVideo))
        videoPlayerView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func playPauseVideo() {
        if player?.rate == 0 {
            player?.play()
        } else {
            player?.pause()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension JobVideoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let videoURL = info[.mediaURL] as? URL {
            saveVideoLocally(videoURL: videoURL)
            playVideo(url: videoURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


