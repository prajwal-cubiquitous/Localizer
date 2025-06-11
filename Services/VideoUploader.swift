import Foundation
import Firebase
import FirebaseStorage

struct VideoUploader {
    static func uploadVideo(withData videoData: Data) async throws -> String {
        // MARK: - COMMENTED OUT - Firebase Storage not enabled
        // Uncomment when Firebase Storage is configured
        
        let filename = UUID().uuidString + ".mov"
        let ref = Storage.storage().reference(withPath: "/news_videos/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        let _ = try await ref.putDataAsync(videoData, metadata: metadata)
        let url = try await ref.downloadURL()
        
        return url.absoluteString
    }
} 
