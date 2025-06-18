//
//  MediaItemView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI
import AVKit
import Kingfisher
import Combine

// MARK: - Individual Media Item Component  
struct MediaItemView: View {
    let urlString: String
    let height: CGFloat
    
    // ✅ More precise video detection
    private var isVideo: Bool {
        let lowercaseURL = urlString.lowercased()
        
        // Check for video file extensions - look for actual file extensions in URL
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]
        let hasVideoExtension = videoExtensions.contains { ext in
            // Check for the extension either at the end of URL or before query parameters
            lowercaseURL.contains(".\(ext)") || lowercaseURL.range(of: "\\.\\(ext)[?&#]", options: .regularExpression) != nil
        }
        
        // Check for video folder paths
        let isInVideoFolder = lowercaseURL.contains("news_videos")
        
        return hasVideoExtension || isInVideoFolder
    }
    
    var body: some View {
        if isVideo {
            DownloadableVideoPlayer(videoURL: urlString)
                .frame(height: height)
                .clipped()
        } else {
            KFImage(URL(string: urlString))
                .placeholder {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: height)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.blue)
                        }
                }
                .onFailure { error in
                    print("Image loading failed for \(urlString): \(error)")
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: height)
                .clipped()
        }
    }
}

// MARK: - Enhanced Video Player with Download Support
struct DownloadableVideoPlayer: View {
    let videoURL: String
    
    @State private var player: AVPlayer?
    @State private var downloadState: DownloadState = .idle
    @State private var cancellables = Set<AnyCancellable>()
    
    enum DownloadState {
        case idle
        case downloading
        case ready
        case failed
    }
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.isMuted = true
                    }
            } else {
                // Show loading or error state
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Group {
                            switch downloadState {
                            case .idle, .downloading:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            case .failed:
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                    Text("Video Error")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            case .ready:
                                EmptyView()
                            }
                        }
                    )
            }
        }
        .onAppear {
            downloadAndSetupVideo()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func downloadAndSetupVideo() {
        guard let url = URL(string: videoURL) else {
            print("❌ Invalid video URL: \(videoURL)")
            downloadState = .failed
            return
        }
        
        downloadState = .downloading
        
        Task {
            do {
                // ✅ Extract file extension from original URL to preserve media format
                let fileExtension = extractFileExtension(from: videoURL)
                let fileName = "\(UUID().uuidString).\(fileExtension)"
                
                let localURL = try await MediaHandler.downloadMedia(from: url, fileName: fileName)
                
                await MainActor.run {
                    setupPlayer(with: localURL)
                    downloadState = .ready
                }
            } catch {
                print("❌ Video download failed: \(error)")
                await MainActor.run {
                    downloadState = .failed
                }
            }
        }
    }
    
    private func extractFileExtension(from urlString: String) -> String {
        // Extract extension from URL
        if let url = URL(string: urlString) {
            let pathExtension = url.pathExtension
            if !pathExtension.isEmpty {
                return pathExtension
            }
        }
        
        // Fallback: look for common video extensions in the URL
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]
        for ext in videoExtensions {
            if urlString.lowercased().contains(".\(ext)") {
                return ext
            }
        }
        
        // Default fallback for video URLs without clear extension
        return "mov"
    }
    
    private func setupPlayer(with videoURL: URL) {
        // Create player item first to check if it's valid
        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Create player
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = true // Start muted
        
        // Observe player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .readyToPlay:
                    // Player is ready, no action needed
                    break
                case .failed:
                    print("❌ Video player item failed: \(videoURL)")
                    if let error = playerItem.error {
                        print("❌ Player error: \(error)")
                    }
                    self.downloadState = .failed
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe playback errors
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            print("❌ Video playback failed to end: \(videoURL)")
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("❌ Playback error: \(error)")
            }
            self.downloadState = .failed
        }
        
        self.player = newPlayer
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
}
