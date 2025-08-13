//
//  NewsCellViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/5/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class NewsCellViewModel: ObservableObject{
    
    @Published var voteState: VoteState = .none
    @Published var likesCount: Int = 0
    @Published var showingMenu: Bool = false
    // Animation states for button scaling
    @Published var upvoteScale: CGFloat = 1.0
    @Published var downvoteScale: CGFloat = 1.0
    @Published var savedByCurrentUser: Bool = false
    
    
    private let db = Firestore.firestore()
    
    
    /// Saves or updates a vote in the subcollection `votes` under the specific `news` document
    func saveVote(postId: String, voteType: Int, PostLikeCount: Int, constituencyId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("constituencies").document(constituencyId).collection("news")
            .document(postId)
            .collection("votes")
            .document(uid) // Use userId as document ID to ensure uniqueness
        
        if voteType == 0 {
            // Remove the vote document when voteType is 0 (neutral)
            try await docRef.delete()
        } else {
            // Create or update the vote document
            try await docRef.setData([
                "postId": postId,
                "userId": uid,
                "voteType": voteType,
                "timestamp": Date()
            ], merge: true)
        }
        
        // Update the likes count on the main news document
        try await incrementLikesCount(forPostId: postId, by: PostLikeCount, constituencyId: constituencyId)
    }
    
    func fetchVotesStatus(postId: String, constituencyId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("constituencies").document(constituencyId).collection("news")
            .document(postId)
        
        do {
            let document = try await docRef.getDocument()
            if let data = document.data(),
               let count = data["likesCount"] as? Int {
                await MainActor.run {
                    self.likesCount = count
                }
            }
            
            // Check user's vote status
            let voteSnapshot = try await docRef.collection("votes")
                .document(uid).getDocument()
                
            if let voteData = voteSnapshot.data(), 
               let voteType = voteData["voteType"] as? Int {
                await MainActor.run {
                    switch voteType {
                    case 1:
                        self.voteState = .upvoted
                    case -1:
                        self.voteState = .downvoted
                    default:
                        self.voteState = .none
                    }
                }
            } else {
                await MainActor.run {
                    self.voteState = .none
                }
            }
        } catch {
            await MainActor.run {
                self.voteState = .none
            }
        }
    }
    
    
    func incrementLikesCount(forPostId postId: String, by amount: Int, constituencyId: String) async throws {
        try await db.collection("constituencies").document(constituencyId).collection("news")
            .document(postId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(amount))
            ])
    }
    
    func handleUpvote(postId: String, constituencyId: String) async {
        // Scale animation
        
        withAnimation(.easeInOut(duration: 0.1)) {
            upvoteScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.upvoteScale = 1.0
            }
        }
        
        // Vote logic
        switch voteState {
        case .none:
            voteState = .upvoted
            likesCount += 1
            do{
                try await saveVote(postId: postId, voteType: 1, PostLikeCount: 1, constituencyId: constituencyId)
                Task{ try await AddLikedNews(postId: postId) }
            }catch{
                print(error.localizedDescription)
            }
        case .upvoted:
            voteState = .none
            likesCount -= 1
            do{
                try await saveVote(postId: postId, voteType: 0, PostLikeCount: -1, constituencyId: constituencyId)
                Task{ try await removeLikedNews(postId: postId) }
            }catch{
                print(error.localizedDescription)
            }
        case .downvoted:
            voteState = .upvoted
            likesCount += 2
            do{
                try await saveVote(postId: postId, voteType: 1, PostLikeCount: 2, constituencyId: constituencyId)
                Task{ try await removeDisLikedNews(postId: postId) }
                Task{ try await AddLikedNews(postId: postId) }
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func handleDownvote(postId: String, constituencyId: String) async {
        // Scale animation
        withAnimation(.easeInOut(duration: 0.1)) {
            downvoteScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.downvoteScale = 1.0
            }
        }
        
        // Vote logic
        switch voteState {
        case .none:
            voteState = .downvoted
            likesCount -= 1
            do{
                try await saveVote(postId: postId, voteType: -1, PostLikeCount: -1, constituencyId: constituencyId)
                Task{ try await AddDisLikedNews(postId: postId) }
            }catch{
                print(error.localizedDescription)
            }
        case .downvoted:
            voteState = .none
            likesCount += 1
            do{
                try await saveVote(postId: postId, voteType: 0, PostLikeCount: 1, constituencyId: constituencyId)
                Task{ try await removeDisLikedNews(postId: postId) }
            }catch{
                print(error.localizedDescription)
            }
        case .upvoted:
            voteState = .downvoted
            likesCount -= 2 // Remove upvote (+1) and add downvote (-1) = -2
            do{
                try await saveVote(postId: postId, voteType: -1, PostLikeCount: -2, constituencyId: constituencyId)
                Task{ try await removeLikedNews(postId: postId) }
                Task{ try await AddDisLikedNews(postId: postId) }
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Save Post Function
        func savePost1(postId: String) async throws {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)
            
            do {
                // First check if already saved to avoid duplicates
                let document = try await docRef.getDocument()
                
                if let data = document.data(),
                   let savedNews = data["savedNews"] as? [String],
                   savedNews.contains(postId) {
                    return
                }
                
                try await docRef.setData([
                    "savedNews": FieldValue.arrayUnion([postId])
                ], merge: true)
                
                // Update local state
                await MainActor.run {
                    self.savedByCurrentUser = true
                }
                try await db.collection("users")
                    .document(userId)
                    .updateData([
                        "SavedPostsCount": FieldValue.increment(Int64(1))
                    ])
                
                
            } catch {
                throw error
            }
        }
        
        // MARK: - Check If News Is Saved
        func checkIfNewsIsSaved1(postId: String) async {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            // Fixed: Use consistent collection name "users" (lowercase)
            let docRef = db
                .collection("users")  // Changed from "Users" to "users"
                .document(userId)
                .collection("userNewsActivity")
                .document(userId)

            do {
                let document = try await docRef.getDocument()

                if let data = document.data(),
                   let savedNews = data["savedNews"] as? [String] {
                    await MainActor.run {
                        self.savedByCurrentUser = savedNews.contains(postId)
                    }
                } else {
                    await MainActor.run {
                        self.savedByCurrentUser = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.savedByCurrentUser = false
                }
            }
        }
        
        // MARK: - Remove Saved News
        func removeSavedNews1(postId: String) async throws {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
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
                   let savedNews = data["savedNews"] as? [String],
                   !savedNews.contains(postId) {
                    return
                }
                
                try await docRef.setData([
                    "savedNews": FieldValue.arrayRemove([postId])
                ], merge: true)
                
                // Update local state
                await MainActor.run {
                    self.savedByCurrentUser = false
                }
                try await db.collection("users")
                    .document(userId)
                    .updateData([
                        "SavedPostsCount": FieldValue.increment(Int64(-1))
                    ])

                
            } catch {
                throw error
            }
        }
    
    func AddLikedNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)
        
        do {
            
            try await docRef.setData([
                "LikedNews": FieldValue.arrayUnion([postId])
            ], merge: true)
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "likedCount": FieldValue.increment(Int64(1))
                ])
            
        } catch {
            throw error
        }
    }
    
    func removeLikedNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)

        do {
            // First check if actually saved
            let document = try await docRef.getDocument()
            
            if let data = document.data(),
               let LikedNews = data["LikedNews"] as? [String],
               !LikedNews.contains(postId) {
                return
            }
            
            try await docRef.setData([
                "LikedNews": FieldValue.arrayRemove([postId])
            ], merge: true)
            
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "likedCount": FieldValue.increment(Int64(-1))
                ])

        } catch {
            throw error
        }
    }
    
    func AddDisLikedNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)
        
        do {
            
            try await docRef.setData([
                "DisLikedNews": FieldValue.arrayUnion([postId])
            ], merge: true)
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "dislikedCount": FieldValue.increment(Int64(1))
                ])
            
        } catch {
            throw error
        }
    }
    
    func removeDisLikedNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)

        do {
            // First check if actually saved
            let document = try await docRef.getDocument()
            
            if let data = document.data(),
               let DisLikedNews = data["DisLikedNews"] as? [String],
               !DisLikedNews.contains(postId) {
                return
            }
            
            try await docRef.setData([
                "DisLikedNews": FieldValue.arrayRemove([postId])
            ], merge: true)
            
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "dislikedCount": FieldValue.increment(Int64(-1))
                ])

        } catch {
            throw error
        }
    }
    
    func DontRecommendNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)
        
        do {
            // First check if already saved to avoid duplicates
            let document = try await docRef.getDocument()
            
            if let data = document.data(),
               let savedNews = data["DontRecommendNews"] as? [String],
               savedNews.contains(postId) {
                return
            }
            
            try await docRef.setData([
                "DontRecommendNews": FieldValue.arrayUnion([postId])
            ], merge: true)
            
        } catch {
            throw error
        }
    }
    
    func DontRecommendUsers(newsUserId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)
        
        do {
            // First check if already saved to avoid duplicates
            let document = try await docRef.getDocument()
            
            if let data = document.data(),
               let savedNews = data["DontRecommendUser"] as? [String],
               savedNews.contains(newsUserId) {
                return
            }
            
            try await docRef.setData([
                "DontRecommendUser": FieldValue.arrayUnion([newsUserId])
            ], merge: true)
            
        } catch {
            throw error
        }
    }
    
    func removeNOTRecommendNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
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
               let savedNews = data["DontRecommendNews"] as? [String],
               !savedNews.contains(postId) {
                return
            }
            
            try await docRef.setData([
                "DontRecommendNews": FieldValue.arrayRemove([postId])
            ], merge: true)
            
        } catch {
            throw error
        }
    }
}

enum VoteState {
    case upvoted, downvoted, none
}
