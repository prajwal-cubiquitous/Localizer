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
    func uploadProfileImage(profileImage: UIImage) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        do{
            let profileUrl = try await ImageUploaderForProfile.uploadImage(profileImage)
            try await db.collection("users").document(uid).updateData(["profileImageUrl": profileUrl])
        }catch{
            throw error
        }
    }
}
