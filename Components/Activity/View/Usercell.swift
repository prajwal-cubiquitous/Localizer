//
//  Usercell.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/20/25.
//

import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

struct Usercell: View {
    let user: User
    @StateObject private var viewModel = UserCellViewModel()
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            ProfilePictureView(userProfileUrl: user.profileImageUrl, width: 44, height: 44)
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Three Dots
            Menu{
                Button("Recommend User"){
                    Task{
                        try await viewModel.removeNOTRecommendUser(userId: user.id)
                    }
                }
            }label:{
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding()
    }
}

#Preview {
    Usercell(user: DummylocalUser.user1.toUser())
}


class UserCellViewModel: ObservableObject {
    func removeNOTRecommendUser(userId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        // Fixed: Use consistent collection name "users" (lowercase)
        let docRef = db
            .collection("users")  // Changed from "Users" to "users"
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)

        do {
            // First check if actually saved
            let document = try await docRef.getDocument()
            
            if let data = document.data(),
               let savedNews = data["DontRecommendUser"] as? [String],
               !savedNews.contains(userId) {
                return
            }
            
            try await docRef.setData([
                "DontRecommendUser": FieldValue.arrayRemove([userId])
            ], merge: true)
            
        } catch {
            throw error
        }
    }
}
