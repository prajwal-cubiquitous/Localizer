//
//  PostViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//

import FirebaseAuth
import Firebase
import FirebaseFirestore
import SwiftUI
import PhotosUI
import SensitiveContentAnalysis
import UniformTypeIdentifiers
import AVFoundation
import SwiftData

enum MediaItem: Identifiable, Equatable {
    case image(UIImage)
    case video(URL, thumbnail: UIImage?)

    var id: UUID { UUID() }
    
    var videoURL: URL? {
        switch self {
        case .video(let url, _):
            return url
        case .image:
            return nil
        }
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        switch (lhs, rhs) {
        case (.image(let lhsImage), .image(let rhsImage)):
            return lhsImage.pngData() == rhsImage.pngData()
        case (.video(let lhsURL, _), .video(let rhsURL, _)):
            return lhsURL == rhsURL
        default:
            return false
        }
    }
}

struct MediaProcessingResult {
    let canAdd: Bool
    let message: String
}

class PostViewModel: ObservableObject {
    private let locationManager = LocationManager.shared
    
    // Published properties for UI binding
    @Published var caption: String = ""
    @Published var isSensitiveContent: Bool = false
    @Published var images: [UIImage] = []
    @Published var videos: [URL] = []
    @Published var photosPicked: [PhotosPickerItem] = []
    @Published var urls: [String] = []
    @Published var mediaItems: [MediaItem] = []
    @Published var selectedVideoURL: URL?
    @Published var isShowingVideoTrimmer = false
    @Published var trimmedVideoURL: URL?
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isPosting: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showFailureAlert: Bool = false
    @Published var shouldNavigateToNewsFeed: Bool = false
    
    // Track which video is being re-trimmed
    @Published var videoBeingRetrimmed: URL?
    
    // MARK: - Post Creation
    
    func createPost(constituencyId: String) async {
        await MainActor.run {
            isPosting = true
        }
        
        do {
            if !mediaItems.isEmpty {
                // Upload media and create post with media
                try await uploadMultipleImages(caption: caption, constituencyId: constituencyId)
            } else {
                // Create text-only post
                try await uploadNews(caption: caption, cosntituencyId: constituencyId)
            }
            
            await MainActor.run {
                // Reset form
                caption = ""
                clearAllMedia()
                isPosting = false
                showSuccessAlert = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create post: \(error.localizedDescription)"
                showFailureAlert = true
                isPosting = false
            }
        }
    }
    
    @MainActor
    func uploadMultipleImages(caption: String, constituencyId: String) async throws {
        urls.removeAll()
        
        // Upload images
        for image in images {
            do {
                let url = try await ImageUploaderForNews.uploadImage(image)
                urls.append(url)
            } catch {
                throw error
            }
        }
        
        // Upload videos
        for videoURL in videos {
            do {
                let videoData = try Data(contentsOf: videoURL)
                let compressedData = await compressVideo(data: videoData)
                
                let uploadedURL = try await VideoUploader.uploadVideo(withData: compressedData ?? videoData)
                urls.append(uploadedURL)
            } catch {
                throw error
            }
        }
        
        try await uploadNewsimages(caption: caption, imageURLS: urls, constituencyId: constituencyId)
    }
    
    func uploadNews(caption: String, cosntituencyId : String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let news = News(ownerUid: uid,
                        caption: caption,
                        timestamp: Timestamp(),
                        likesCount: 0,
                        commentsCount: 0,
                        cosntituencyId: cosntituencyId)
        
        try await NewsService.uploadNews(news)
        
        // Increment post count in Firestore & SwiftData
        try await incrementPostCount(for: uid)
    }
    
    func uploadNewsimages(caption: String, imageURLS: [String]?, constituencyId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let news = News(ownerUid: uid,
                        caption: caption,
                        timestamp: Timestamp(),
                        likesCount: 0,
                        commentsCount: 0,
                        cosntituencyId: constituencyId,
                        newsImageURLs: imageURLS)
        
        try await NewsService.uploadNews(news)
        
        // Increment post count
        try await incrementPostCount(for: uid)
    }
    
    // MARK: - Media Processing
    
    func processPickedPhotos(_ photos: [PhotosPickerItem], currentVideoCount: Int, currentImageCount: Int) async -> MediaProcessingResult {
        
        await MainActor.run {
            isProcessing = true
        }
        
        var newVideoCount = currentVideoCount
        var newImageCount = currentImageCount
        var rejectedItems: [String] = []
        
        for photo in photos {
            do {
                if let contentType = photo.supportedContentTypes.first {
                    let isVideo = contentType.conforms(to: .movie)
                    
                    if isVideo {
                        // Check video limit: only 1 video allowed
                        if newVideoCount >= 1 {
                            rejectedItems.append("video (limit: 1)")
                            continue
                        }
                        
                        // Check total limit with video: max 5 items (1 video + 4 images)
                        if newVideoCount + newImageCount >= 5 {
                            rejectedItems.append("video (total limit: 5)")
                            continue
                        }
                        
                        if let videoData = try await photo.loadTransferable(type: Data.self) {
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                            try videoData.write(to: tempURL)
                            
                            let _ = try await getVideoDuration(from: tempURL)
                            
                            await MainActor.run {
                                selectedVideoURL = tempURL
                                videoBeingRetrimmed = nil
                                isShowingVideoTrimmer = true
                            }
                            newVideoCount += 1
                        }
                    } else {
                        // Check image limits
                        let hasVideo = newVideoCount > 0
                        let maxImages = hasVideo ? 4 : 5
                        
                        if newImageCount >= maxImages {
                            rejectedItems.append("image (limit: \(maxImages))")
                            continue
                        }
                        
                        if let imageData = try await photo.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: imageData) {
                            await MainActor.run {
                                mediaItems.append(.image(uiImage))
                                images.append(uiImage)
                            }
                            newImageCount += 1
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to process media: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
        
        // Return result
        if rejectedItems.isEmpty {
            return MediaProcessingResult(canAdd: true, message: "")
        } else {
            let message = "Some items couldn't be added:\n• \(rejectedItems.joined(separator: "\n• "))\n\nLimits: 1 video + 4 photos OR 5 photos maximum"
            return MediaProcessingResult(canAdd: false, message: message)
        }
    }
    
    func addTrimmedVideo(_ trimmedURL: URL) {
        
        Task {
            let thumbnail: UIImage?
            if #available(iOS 18.0, *) {
                thumbnail = await generateThumbnailAsync(from: trimmedURL)
            } else {
                thumbnail = generateThumbnail(from: trimmedURL)
            }
            
            await MainActor.run {
                updateVideoInMediaItems(trimmedURL: trimmedURL, thumbnail: thumbnail)
            }
        }
    }
    
    private func updateVideoInMediaItems(trimmedURL: URL, thumbnail: UIImage?) {
        // Check if this is a re-trim of an existing video
        if let videoBeingRetrimmed = videoBeingRetrimmed,
           let index = mediaItems.firstIndex(where: { item in
               if case .video(let url, _) = item {
                   return url == videoBeingRetrimmed
               }
               return false
           }) {
            // Replace existing video
            
            // Remove old video file
            if case .video(let oldURL, _) = mediaItems[index] {
                try? FileManager.default.removeItem(at: oldURL)
                videos.removeAll { $0 == oldURL }
            }
            
            // Update with new trimmed video
            mediaItems[index] = .video(trimmedURL, thumbnail: thumbnail)
            videos.append(trimmedURL)
        } else {
            // Add new video
            mediaItems.append(.video(trimmedURL, thumbnail: thumbnail))
            videos.append(trimmedURL)
        }
        
        // Clean up original video file if it was temporary
        if let originalURL = selectedVideoURL {
            try? FileManager.default.removeItem(at: originalURL)
        }
        
        // Reset state
        selectedVideoURL = nil
        videoBeingRetrimmed = nil
        isShowingVideoTrimmer = false
        
    }
    
    func startVideoRetrimming(for videoURL: URL) {
        selectedVideoURL = videoURL
        videoBeingRetrimmed = videoURL
        isShowingVideoTrimmer = true
    }
    
    func removeMediaItem(at index: Int) {
        if index < mediaItems.count {
            let item = mediaItems[index]
            switch item {
            case .video(let url, _):
                videos.removeAll { $0 == url }
                try? FileManager.default.removeItem(at: url)
            case .image(let image):
                if let imageIndex = images.firstIndex(of: image) {
                    images.remove(at: imageIndex)
                }
            }
            mediaItems.remove(at: index)
        }
    }
    
    func replaceImage(at index: Int, with newImage: UIImage) {
        guard index < mediaItems.count else { return }
        
        if case .image(let oldImage) = mediaItems[index] {
            // Update mediaItems array
            mediaItems[index] = .image(newImage)
            
            // Update images array
            if let imageIndex = images.firstIndex(of: oldImage) {
                images[imageIndex] = newImage
            }
        }
    }
    
    func clearAllMedia() {
        mediaItems.removeAll()
        images.removeAll()
        videos.forEach { try? FileManager.default.removeItem(at: $0) }
        videos.removeAll()
        urls.removeAll()
    }
    
    // MARK: - Video Processing
    
    private func compressVideo(data: Data) async -> Data? {
        let tempInputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_input.mov")
        let tempOutputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_output.mov")
        
        do {
            try data.write(to: tempInputURL)
            
            let asset = AVURLAsset(url: tempInputURL)
            
            // Check if the asset is valid
            do {
                let _ = try await asset.load(.duration)
            } catch {
                try? FileManager.default.removeItem(at: tempInputURL)
                return nil
            }
            
            // Try different compression presets in order of preference
            let presets = [
                AVAssetExportPresetMediumQuality,
                AVAssetExportPresetLowQuality,
                AVAssetExportPresetHighestQuality
            ]
            
            for preset in presets {
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
                    continue
                }
                
                exportSession.outputURL = tempOutputURL
                exportSession.outputFileType = .mov
                exportSession.shouldOptimizeForNetworkUse = true
                
                
                do {
                    try await exportSession.export(to: tempOutputURL, as: .mov)
                    
                    // If we reach here, export was successful
                    let compressedData = try Data(contentsOf: tempOutputURL)
                    let originalSize = data.count
                    let compressedSize = compressedData.count
                    let _ = Double(compressedSize) / Double(originalSize)
                    
                    
                    // Clean up temp files
                    try? FileManager.default.removeItem(at: tempInputURL)
                    try? FileManager.default.removeItem(at: tempOutputURL)
                    
                    return compressedData
                } catch {
                    // Try next preset
                    continue
                }
            }
            
            
        } catch {
        }
        
        // Clean up temp files
        try? FileManager.default.removeItem(at: tempInputURL)
        try? FileManager.default.removeItem(at: tempOutputURL)
        
        return nil
    }
    
    func getVideoDuration(from url: URL) async throws -> Double {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
    
    @available(iOS, deprecated: 18.0, message: "Use async thumbnail generation instead")
    func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    @available(iOS 18.0, *)
    func generateThumbnailAsync(from videoURL: URL) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        return await withCheckedContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: .zero) { cgImage, actualTime, error in
                if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Video Trimming
    
    func trimVideo(from inputURL: URL, startTime: Double, endTime: Double) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_trimmed.mov")
        
        let asset = AVURLAsset(url: inputURL)
        let composition = AVMutableComposition()
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let startTimeCM = CMTime(seconds: startTime, preferredTimescale: 600)
        let endTimeCM = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTimeCM, end: endTimeCM)
        
        try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        
        // Add audio track if available
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = timeRange
        
        // Use new iOS 18 API
        try await exportSession.export(to: outputURL, as: .mov)
        
        return outputURL
    }
    
    // MARK: - Post Count Handling
    private func incrementPostCount(for uid: String) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        // Atomically increment in Firestore
        try await userRef.updateData(["postsCount": FieldValue.increment(Int64(1))])
        
        // Update local SwiftData cache (if available) on main actor
        if let context = AuthViewModel.shared.modelContext {
            do {
                let fetch = FetchDescriptor<LocalUser>(
                    predicate: #Predicate { $0.id == uid }
                )
                if let localUser = try context.fetch(fetch).first {
                    localUser.postCount += 1
                }
            } catch {
            }
        }
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
