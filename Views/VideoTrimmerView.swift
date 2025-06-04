import SwiftUI
import AVKit

struct VideoTrimmerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PostViewModel
    let videoURL: URL
    let initialStartTime: Double
    let initialEndTime: Double
    let onTrimComplete: (URL) -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var totalDuration: Double = 0
    @State private var isTrimming = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Trimming controls
    @State private var startTime: Double = 0
    @State private var endTime: Double = 60
    @State private var isLoadingDuration = true
    
    // Maximum video duration (60 seconds)
    private let maxDuration: Double = 60.0
    
    // Computed properties for safe slider ranges
    private var startTimeRange: ClosedRange<Double> {
        guard totalDuration > 0 else { return 0...0 }
        let upperBound = max(0, min(totalDuration - 0.1, endTime - 0.1))
        return 0...max(0, upperBound)
    }
    
    private var endTimeRange: ClosedRange<Double> {
        guard totalDuration > 0 else { return 1...1 }
        let lowerBound = min(totalDuration, max(0.1, startTime + 0.1))
        let upperBound = min(totalDuration, startTime + maxDuration)
        return lowerBound...max(lowerBound, upperBound)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Video Player Section
                VStack(spacing: 16) {
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(height: 280)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 280)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    
                    // Playback Controls
                    HStack(spacing: 20) {
                        Button {
                            seekToStart()
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 44, height: 44)
                        
                        Button {
                            isPlaying.toggle()
                            if isPlaying {
                                player?.play()
                            } else {
                                player?.pause()
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                        }
                        .frame(width: 60, height: 60)
                        
                        Button {
                            seekToEnd()
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Trimming Controls Section
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Video Range")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.primary)
                        
                        // Duration info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Duration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatTime(totalDuration))
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Selected Duration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatTime(endTime - startTime))
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // Visual Timeline
                        VStack(spacing: 12) {
                            // Timeline track
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    // Selected range
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue)
                                        .frame(
                                            width: max(0, CGFloat((endTime - startTime) / totalDuration) * geometry.size.width),
                                            height: 8
                                        )
                                        .offset(x: CGFloat(startTime / totalDuration) * geometry.size.width)
                                    
                                    // Current playback position indicator
                                    Circle()
                                        .fill(Color.white)
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 16, height: 16)
                                        .offset(x: CGFloat(currentTime / totalDuration) * geometry.size.width - 8)
                                }
                            }
                            .frame(height: 20)
                            .padding(.horizontal, 8)
                            
                            // Time labels
                            HStack {
                                Text("0:00")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatTime(totalDuration))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                        }
                        
                        // Start Time Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Start Time")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(formatTime(startTime))
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .monospacedDigit()
                            }
                            
                            Slider(value: $startTime, in: startTimeRange) { editing in
                                if !editing {
                                    seekToTime(startTime)
                                }
                            }
                            .tint(.blue)
                            .onChange(of: startTime) { _, newValue in
                                // Ensure end time maintains at least 1 second duration
                                if endTime - newValue < 1 {
                                    endTime = min(totalDuration, newValue + 1)
                                }
                                // Ensure we don't exceed max duration
                                if endTime - newValue > maxDuration {
                                    endTime = min(totalDuration, newValue + maxDuration)
                                }
                            }
                        }
                        
                        // End Time Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("End Time")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(formatTime(endTime))
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .monospacedDigit()
                            }
                            
                            Slider(value: $endTime, in: endTimeRange) { editing in
                                if !editing {
                                    seekToTime(endTime)
                                }
                            }
                            .tint(.blue)
                            .onChange(of: endTime) { _, newValue in
                                // Ensure we maintain at least 1 second duration
                                if newValue - startTime < 1 {
                                    startTime = max(0, newValue - 1)
                                }
                                // Ensure we don't exceed max duration
                                if newValue - startTime > maxDuration {
                                    startTime = max(0, newValue - maxDuration)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Maximum duration warning
                    if endTime - startTime > maxDuration {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Maximum video duration is 60 seconds")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // Preview Selected Range Button
                        Button {
                            previewSelectedRange()
                        } label: {
                            HStack {
                                Image(systemName: "play.rectangle")
                                Text("Preview")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(25)
                        }
                        .disabled(isLoadingDuration)
                        
                        // Trim Video Button
                        Button {
                            trimVideo()
                        } label: {
                            HStack {
                                if isTrimming {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isTrimming ? "Trimming..." : "Trim & Save")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(isTrimming || isLoadingDuration ? Color.secondary : Color.blue)
                            )
                        }
                        .disabled(isTrimming || isLoadingDuration || endTime - startTime > maxDuration)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Trim Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
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
    
    // MARK: - Helper Methods
    
    private func setupPlayer() {
        let asset = AVURLAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // Load video duration
        Task {
            do {
                let duration = try await asset.load(.duration).seconds
                await MainActor.run {
                    totalDuration = max(1.0, duration) // Ensure minimum 1 second
                    
                    // Set initial values with proper bounds checking
                    let safeInitialStart = max(0, min(initialStartTime, totalDuration - 1))
                    let safeInitialEnd = min(totalDuration, max(safeInitialStart + 1, initialEndTime))
                    
                    startTime = safeInitialStart
                    endTime = safeInitialEnd
                    
                    // Ensure we don't exceed max duration
                    if endTime - startTime > maxDuration {
                        endTime = min(totalDuration, startTime + maxDuration)
                    }
                    
                    // Final validation - ensure minimum 1 second duration
                    if endTime - startTime < 1 {
                        if startTime + 1 <= totalDuration {
                            endTime = startTime + 1
                        } else {
                            startTime = max(0, endTime - 1)
                        }
                    }
                    
                    isLoadingDuration = false
                    
                    // Seek to start time
                    seekToTime(startTime)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load video duration"
                    showError = true
                }
            }
        }
        
        // Add periodic time observer
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
            
            // Auto-pause when reaching end of selected range during preview
            if currentTime >= endTime && isPlaying {
                player?.pause()
                isPlaying = false
            }
        }
    }
    
    private func seekToTime(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func seekToStart() {
        seekToTime(startTime)
    }
    
    private func seekToEnd() {
        seekToTime(endTime)
    }
    
    private func previewSelectedRange() {
        seekToTime(startTime)
        isPlaying = true
        player?.play()
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func trimVideo() {
        guard endTime - startTime <= maxDuration else {
            errorMessage = "Selected duration exceeds 60 seconds maximum"
            showError = true
            return
        }
        
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