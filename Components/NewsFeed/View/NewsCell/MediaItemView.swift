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
            lowercaseURL.contains(".\(ext)") || lowercaseURL.contains(".\(ext)?")
        }
        
        // Check for video folder paths
        let isInVideoFolder = lowercaseURL.contains("news_videos")
        
        return hasVideoExtension || isInVideoFolder
    }
    
    var body: some View {
        if isVideo {
            DownloadableVideoPlayer(videoURL: urlString)
                .frame(height: height)
        } else {
            // ✅ Image with better error handling
            KFImage(URL(string: urlString))
                .onFailure { _ in
                    // Silent error handling - no debug prints
                }
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: height)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: height)
                .clipped()
        }
    }
}

// MARK: - Downloadable Video Player
struct DownloadableVideoPlayer: View {
    let videoURL: String
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var localVideoURL: URL?
    @State private var cancellables = Set<AnyCancellable>()
    
    // ✅ Extract file extension from URL
    private func extractFileExtension(from urlString: String) -> String {
        // Try to get extension from URL path
        if let url = URL(string: urlString) {
            let pathExtension = url.pathExtension.lowercased()
            if !pathExtension.isEmpty {
                return pathExtension
            }
        }
        
        // Fallback: look for common video extensions in the URL string
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]
        for ext in videoExtensions {
            if urlString.lowercased().contains(".\(ext)") {
                return ext
            }
        }
        
        return "mov" // Default fallback
    }
    
    var body: some View {
        ZStack {
            if let player = player, !hasError {
                VideoPlayer(player: player)
                    .onAppear {
                        player.isMuted = true
                    }
            } else if hasError {
                // ✅ Fallback to image if video fails
                KFImage(URL(string: videoURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                // Loading state
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView("Loading video...")
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
        }
        .onAppear {
            downloadAndSetupVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
            cancellables.removeAll()
        }
    }
    
    private func downloadAndSetupVideo() {
        guard let url = URL(string: videoURL) else {
            hasError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                // ✅ Preserve file extension when downloading
                let fileExtension = extractFileExtension(from: videoURL)
                let filename = "\(url.lastPathComponent.components(separatedBy: "?").first ?? UUID().uuidString).\(fileExtension)"
                
                let localURL = try await MediaHandler.downloadMedia(from: url, fileName: filename)
                
                await MainActor.run {
                    self.localVideoURL = localURL
                    setupPlayer(with: localURL)
                }
            } catch {
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
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
                    // Player is ready
                    isLoading = false
                    hasError = false
                case .failed:
                    hasError = true
                    isLoading = false
                    if playerItem.error != nil {
                        // Silent error handling - no debug prints
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe playback errors
        newPlayer.publisher(for: \.reasonForWaitingToPlay)
            .receive(on: DispatchQueue.main)
            .sink { reason in
                if let reason = reason, reason == .evaluatingBufferingRate {
                    // Handle buffering if needed
                }
            }
            .store(in: &cancellables)
        
        // Set up notification for playback end
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // Restart video when it ends
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
            .store(in: &cancellables)
        
        // Handle playback errors
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                if notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] != nil {
                    // Silent error handling - no debug prints
                }
                hasError = true
            }
            .store(in: &cancellables)
        
        self.player = newPlayer
    }
}
