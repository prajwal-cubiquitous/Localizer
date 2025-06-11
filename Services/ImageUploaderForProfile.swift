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
    static func uploadImage(_ image: UIImage) async throws -> String {
        // MARK: - COMMENTED OUT - Firebase Storage not enabled
        // Uncomment when Firebase Storage is configured
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(domain: "ImageUploader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/profile_images/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        
        return url.absoluteString
    }
} 
