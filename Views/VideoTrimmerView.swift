import SwiftUI
import AVKit

struct VideoTrimmerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PostViewModel
    let videoURL: URL
    let startTime: Double
    let endTime: Double
    let onTrimComplete: (URL) -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isTrimming = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(height: 300)
                        .cornerRadius(12)
                }
                
                VStack(spacing: 15) {
                    // Time display
                    HStack {
                        Text("Start: \(Int(startTime))s")
                        Spacer()
                        Text("End: \(Int(endTime))s")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    
                    // Playback controls
                    HStack(spacing: 30) {
                        Button {
                            isPlaying.toggle()
                            if isPlaying {
                                player?.play()
                            } else {
                                player?.pause()
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                        }
                        
                        Button {
                            trimVideo()
                        } label: {
                            HStack {
                                if isTrimming {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isTrimming ? "Trimming..." : "Trim Video")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(isTrimming ? Color.secondary : Color.blue)
                            .cornerRadius(25)
                        }
                        .disabled(isTrimming)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Trim Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func setupPlayer() {
        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // Add periodic time observer
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            let absoluteTime = time.seconds
            currentTime = max(0, absoluteTime - startTime) // time relative to startTime
            
            if absoluteTime >= endTime {
                player?.pause()
                player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
                isPlaying = false
            }
        }

        Task {
            let originalDuration = try await asset.load(.duration).seconds
            duration = endTime - startTime
            await player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
        }
    }
    
    private func trimVideo() {
        isTrimming = true
        
        Task {
            do {
                let trimmedURL = try await viewModel.trimVideo(
                    from: videoURL,
                    startTime: startTime,
                    endTime: endTime
                )
                
                await MainActor.run {
                    isTrimming = false
                    onTrimComplete(trimmedURL)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isTrimming = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
} 