//
//  ImageUploaderForNews 2.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/11/25.
//
import Foundation
import Firebase
import FirebaseStorage
import UIKit

struct ImageUploaderForProfile {
    
    /// Uploads a new profile image and optionally deletes the old one
    /// - Parameters:
    ///   - image: The new UIImage to upload
    ///   - oldImageUrl: Optional URL of the old image to delete
    /// - Returns: URL string of the uploaded image
    static func uploadImage(_ image: UIImage, oldImageUrl: String? = nil) async throws -> String {
        // Delete old image first if provided
        if let oldUrl = oldImageUrl, !oldUrl.isEmpty {
            await deleteOldImage(from: oldUrl)
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(domain: "ImageUploader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/profile_images/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        
        print("✅ Successfully uploaded new profile image: \(url.absoluteString)")
        return url.absoluteString
    }
    
    /// Deletes an old profile image from Firebase Storage
    /// - Parameter imageUrl: The full URL of the image to delete
    static func deleteOldImage(from imageUrl: String) async {
        do {
            // Extract the file path from the full URL
            guard let url = URL(string: imageUrl),
                  let pathComponents = extractStoragePath(from: url) else {
                print("❌ Invalid image URL format: \(imageUrl)")
                return
            }
            
            let ref = Storage.storage().reference(withPath: pathComponents)
            try await ref.delete()
            print("✅ Successfully deleted old profile image: \(pathComponents)")
            
        } catch {
            // Don't throw error for deletion failures as it shouldn't block new uploads
            print("⚠️ Failed to delete old profile image: \(error.localizedDescription)")
            print("   URL: \(imageUrl)")
        }
    }
    
    /// Extracts the storage path from a Firebase Storage download URL
    /// - Parameter url: The full download URL
    /// - Returns: The storage path (e.g., "/profile_images/filename.jpg")
    private static func extractStoragePath(from url: URL) -> String? {
        // Firebase Storage URLs have format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?{params}
        // We need to extract the path part and decode it
        
        let pathComponents = url.pathComponents
        
        // Find the index of "o" in path components
        guard let oIndex = pathComponents.firstIndex(of: "o"),
              oIndex + 1 < pathComponents.count else {
            return nil
        }
        
        // Get the encoded path (everything after "/o/")
        let encodedPath = pathComponents[(oIndex + 1)...].joined(separator: "/")
        
        // Remove query parameters if present
        let pathWithoutQuery = encodedPath.components(separatedBy: "?").first ?? encodedPath
        
        // Decode the URL-encoded path
        guard let decodedPath = pathWithoutQuery.removingPercentEncoding else {
            return nil
        }
        
        // Ensure it starts with "/" for Storage reference
        return decodedPath.hasPrefix("/") ? decodedPath : "/\(decodedPath)"
    }
    
    /// Deletes all profile images for cleanup (admin function)
    static func deleteAllProfileImages() async throws {
        let ref = Storage.storage().reference().child("profile_images")
        
        do {
            let result = try await ref.listAll()
            
            for item in result.items {
                try await item.delete()
                print("✅ Deleted profile image: \(item.fullPath)")
            }
            
            print("✅ Successfully deleted all profile images (\(result.items.count) files)")
        } catch {
            print("❌ Error deleting profile images: \(error.localizedDescription)")
            throw error
        }
    }
} 
