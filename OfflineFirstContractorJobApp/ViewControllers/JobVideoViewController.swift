//
//  JobVideoViewController.swift
//  OfflineFirstContractorJobApp
//

import UIKit
import AVKit
import MobileCoreServices

class JobVideoViewController: UIViewController {
    
    @IBOutlet weak var dragaAndDropLbl: UILabel!
    @IBOutlet weak var uploadBtn: UIButton!
    @IBOutlet weak var noVideosView: UIView!
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
        loadExistingVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadExistingVideo()
    }
    
    private func loadExistingVideo() {
        let pendingVideos = LocalStorageManager.shared.getPendingVideos()
        if let pendingVideo = pendingVideos.first(where: { $0.localJobId == job.localId || $0.jobId == job.id }) {
            if let videoURL = URL(string: pendingVideo.videoPath) {
                self.videoURL = videoURL
                updateVideoUI()
                playVideo(url: videoURL)
            }
        }
    }
    
    private func setupUI() {
        selectVideoButton.layer.cornerRadius = 16
        videoStatusLabel.text = "No video selected"
        updateVideoUI()
    }
    
    private func updateVideoUI() {
        if videoURL != nil {
            noVideosView.isHidden = true
            videoPlayerView.isHidden = false
            selectVideoButton.isHidden = false
            videoStatusLabel.isHidden = false
            dragaAndDropLbl.isHidden = true
            uploadBtn.isHidden = true
            noVideosView.isHidden = true
            selectVideoButton.isHidden = true
            videoStatusLabel.isHidden = true
        } else {
            // No video, show no videos view
            noVideosView.isHidden = false
            videoPlayerView.isHidden = false
            selectVideoButton.isHidden = false
            videoStatusLabel.isHidden = false
            dragaAndDropLbl.isHidden = false
            uploadBtn.isHidden = false
            noVideosView.isHidden = false
            selectVideoButton.isHidden = false
            videoStatusLabel.isHidden = false
        }
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
    
    // MARK: - Select Video Button Action
    @IBAction func selectVideoButtonTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"] // Only videos
        picker.videoQuality = .typeMedium
        present(picker, animated: true)
    }
    
    // MARK: - Save Video Locally
    private func saveVideoLocally(videoURL: URL) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("\(UUID().uuidString).mp4")
        do {
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            self.videoURL = destinationURL
            
            // Save pending video
            let jobId = job.id ?? job.localId
            LocalStorageManager.shared.addPendingVideo(
                jobId: jobId,
                localJobId: job.localId,
                videoPath: destinationURL.absoluteString
            )
            
            videoStatusLabel.text = "Video saved locally. Will upload when online."
            
            // Update UI to show video player
            updateVideoUI()
            playVideo(url: destinationURL)
            
            // Try to upload if online
            if NetworkManager.shared.isConnected, let jobServerId = job.id {
                uploadVideo(videoURL: destinationURL)
            }
        } catch {
            videoStatusLabel.text = "Error saving video: \(error.localizedDescription)"
            updateVideoUI()
        }
    }
    
    // MARK: - Upload Video
    private func uploadVideo(videoURL: URL) {
        guard let videoData = try? Data(contentsOf: videoURL),
              let jobServerId = job.id else { return }
        
        videoStatusLabel.text = "Uploading video..."
        selectVideoButton.isEnabled = false
        
        APIService.shared.uploadVideo(jobId: jobServerId, videoData: videoData) { [weak self] result in
            DispatchQueue.main.async {
                self?.selectVideoButton.isEnabled = true
                switch result {
                case .success:
                    self?.videoStatusLabel.text = "Video uploaded successfully"
                    // Remove from pending videos
                    let pendingVideos = LocalStorageManager.shared.getPendingVideos()
                    if let pendingVideo = pendingVideos.first(where: {
                        $0.localJobId == self?.job.localId || $0.jobId == self?.job.id
                    }) {
                        LocalStorageManager.shared.removePendingVideo(localId: pendingVideo.localId)
                    }
                    // Update UI
                    self?.updateVideoUI()
                case .failure(let error):
                    self?.videoStatusLabel.text = "Upload failed. Will retry when online."
                    print("Video upload error: \(error.localizedDescription)")
                    // Update UI even on failure
                    self?.updateVideoUI()
                }
            }
        }
    }
    
    // MARK: - Play Video
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
