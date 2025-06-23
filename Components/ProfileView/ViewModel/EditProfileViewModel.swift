//
//  ProfileViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/11/25.
//

import Foundation
import PhotosUI
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class EditProfileViewModel : ObservableObject {
    
    /// Uploads a new profile image and deletes the old one
    /// - Parameters:
    ///   - profileImage: The new UIImage to upload
    ///   - oldImageUrl: Optional URL of the current profile image to delete
    func uploadProfileImage(profileImage: UIImage, oldImageUrl: String? = nil) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { 
            throw NSError(domain: "EditProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        
        do {
            // Upload new image and delete old one
            let newProfileUrl = try await ImageUploaderForProfile.uploadImage(profileImage, oldImageUrl: oldImageUrl)
            
            // Update Firestore with new image URL
            try await db.collection("users").document(uid).updateData(["profileImageUrl": newProfileUrl])
            
            print("✅ Profile image updated successfully for user: \(uid)")
        } catch {
            print("❌ Failed to update profile image: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Deletes the current profile image without uploading a new one
    /// - Parameter imageUrl: The URL of the image to delete
    func deleteProfileImage(imageUrl: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EditProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        
        do {
            // Delete the image from Storage
            await ImageUploaderForProfile.deleteOldImage(from: imageUrl)
            
            // Remove the image URL from Firestore
            try await db.collection("users").document(uid).updateData(["profileImageUrl": FieldValue.delete()])
            
            print("✅ Profile image deleted successfully for user: \(uid)")
        } catch {
            print("❌ Failed to delete profile image: \(error.localizedDescription)")
            throw error
        }
    }
}
