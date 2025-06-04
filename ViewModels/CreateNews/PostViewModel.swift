//
//  PostViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//

import FirebaseAuth
import Firebase
import SwiftUI
import PhotosUI
import SensitiveContentAnalysis
import UniformTypeIdentifiers
import AVFoundation

enum MediaItem: Identifiable, Equatable {
    case image(UIImage)
    case video(URL, thumbnail: UIImage?)

    var id: UUID { UUID() }
    
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
    
    // MARK: - Post Creation
    
    func createPost() async {
        await MainActor.run {
            isPosting = true
        }
        
        do {
            if !mediaItems.isEmpty {
                // For now, just create text post even if media is present
                // Uncomment the line below when Firebase Storage is enabled
                // try await uploadMultipleImages(caption: caption)
                try await uploadNews(caption: caption)
            } else {
                try await uploadNews(caption: caption)
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
    
    func uploadMultipleImages(caption: String) async throws {
        print("Starting upload process")
        urls.removeAll()
        
        // MARK: - COMMENTED OUT - Firebase Storage Upload
        // Uncomment when Firebase Storage is enabled
        
        /*
        // Upload images
        for image in images {
            do {
                let url = try await ImageUploaderForNews.uploadImage(image)
                urls.append(url)
                print("Uploaded image: \(url)")
            } catch {
                print("Image upload error: \(error.localizedDescription)")
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
                print("Uploaded video: \(uploadedURL)")
            } catch {
                print("Video upload error: \(error.localizedDescription)")
                throw error
            }
        }
        
        try await uploadNewsimages(caption: caption, imageURLS: urls)
        */
        
        // For now, just create text post without media URLs
        print("Media upload disabled - Firebase Storage not enabled")
        try await uploadNews(caption: caption)
    }
    
    func uploadNews(caption: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get current location
        let currentPincode = await getCurrentPincode()
        
        let news = News(ownerUid: uid, caption: caption, timestamp: Timestamp(), likesCount: 0, commentsCount: 0, postalCode: currentPincode)
        try await NewsService.uploadNews(news)
    }
    
    func uploadNewsimages(caption: String, imageURLS: [String]?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get current location
        let currentPincode = await getCurrentPincode()
        
        let news = News(ownerUid: uid, caption: caption, timestamp: Timestamp(), likesCount: 0, commentsCount: 0, postalCode: currentPincode, newsImageURLs: imageURLS)
        try await NewsService.uploadNews(news)
    }
    
    private func getCurrentPincode() async -> String {
        return await withCheckedContinuation { continuation in
            locationManager.getCurrentPincode { pincode in
                continuation.resume(returning: pincode ?? "000000")
            }
        }
    }
    
    // MARK: - Media Processing
    
    func processPickedPhotos(_ photos: [PhotosPickerItem]) async {
        print("DEBUG: Starting to process \(photos.count) picked photos")
        
        await MainActor.run {
            isProcessing = true
        }
        
        for photo in photos {
            do {
                if let contentType = photo.supportedContentTypes.first {
                    let isVideo = contentType.conforms(to: .movie)
                    
                    if isVideo {
                        print("DEBUG: Processing video item")
                        if let videoData = try await photo.loadTransferable(type: Data.self) {
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                            try videoData.write(to: tempURL)
                            print("DEBUG: Created temporary video file at: \(tempURL)")
                            
                            let duration = try await getVideoDuration(from: tempURL)
                            print("DEBUG: Video duration: \(duration) seconds")
                            
                            await MainActor.run {
                                print("DEBUG: Showing video trimmer for user selection")
                                selectedVideoURL = tempURL
                                isShowingVideoTrimmer = true
                            }
                        }
                    } else {
                        print("DEBUG: Processing image item")
                        if let imageData = try await photo.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: imageData) {
                            print("DEBUG: Processing image with size: \(imageData.count) bytes")
                            await MainActor.run {
                                mediaItems.append(.image(uiImage))
                                images.append(uiImage)
                                print("DEBUG: Added image to media items and images array")
                            }
                        }
                    }
                } else {
                    print("DEBUG: No content type found for item")
                }
            } catch {
                print("DEBUG: Error processing photo: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to process media: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
        
        print("DEBUG: Finished processing all photos. Media items count: \(mediaItems.count)")
    }
    
    func addTrimmedVideo(_ trimmedURL: URL) {
        var thumbnail: UIImage?
        if #available(iOS 18.0, *) {
            Task {
                thumbnail = await generateThumbnailAsync(from: trimmedURL)
                // Use thumbnail here
            }
        } else {
            thumbnail = generateThumbnail(from: trimmedURL)
            // Use thumbnail here
        }
        
        mediaItems.append(.video(trimmedURL, thumbnail: thumbnail))
        videos.append(trimmedURL)
        
        if let originalURL = selectedVideoURL {
            try? FileManager.default.removeItem(at: originalURL)
        }
        
        selectedVideoURL = nil
        isShowingVideoTrimmer = false
        
        print("DEBUG: Added trimmed video to media items. Total videos: \(videos.count)")
    }
    
    func removeMediaItem(at index: Int) {
        print("DEBUG: Removing media item at index: \(index)")
        if index < mediaItems.count {
            let item = mediaItems[index]
            switch item {
            case .video(let url, _):
                print("DEBUG: Removing video from videos array: \(url)")
                videos.removeAll { $0 == url }
                try? FileManager.default.removeItem(at: url)
            case .image(let image):
                print("DEBUG: Removing image from images array")
                if let imageIndex = images.firstIndex(of: image) {
                    images.remove(at: imageIndex)
                }
            }
            mediaItems.remove(at: index)
            print("DEBUG: Current media items count: \(mediaItems.count)")
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
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
                return nil
            }
            
            exportSession.outputURL = tempOutputURL
            exportSession.outputFileType = .mov
            
            do {
                try await exportSession.export(to: tempOutputURL, as: .mov)
                let compressedData = try Data(contentsOf: tempOutputURL)
                try? FileManager.default.removeItem(at: tempInputURL)
                try? FileManager.default.removeItem(at: tempOutputURL)
                return compressedData
            } catch {
                print("Video compression export error: \(error.localizedDescription)")
                return nil
            }
        } catch {
            print("Video compression error: \(error.localizedDescription)")
        }
        
        try? FileManager.default.removeItem(at: tempInputURL)
        try? FileManager.default.removeItem(at: tempOutputURL)
        return nil
    }
    
    func getVideoDuration(from url: URL) async throws -> Double {
        print("DEBUG: Getting video duration from: \(url)")
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        print("DEBUG: Video duration loaded: \(duration.seconds) seconds")
        return duration.seconds
    }
    
    @available(iOS, deprecated: 18.0, message: "Use async thumbnail generation instead")
    func generateThumbnail(from videoURL: URL) -> UIImage? {
        print("DEBUG: Generating thumbnail for video: \(videoURL)")
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            print("DEBUG: Successfully generated thumbnail")
            return UIImage(cgImage: cgImage)
        } catch {
            print("DEBUG: Error generating thumbnail: \(error)")
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
                    print("Failed to generate thumbnail: \(error?.localizedDescription ?? "Unknown error")")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    
    func trimVideo(from url: URL, startTime: Double, endTime: Double) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let composition = AVMutableComposition()
        
        // Use new iOS 16+ APIs
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        
        guard let videoTrack = videoTracks.first,
              let audioTrack = audioTracks.first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create composition tracks"])
        }
        
        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let end = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: start, end: end)
        
        try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        
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
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
