//
//  NewsCellViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@MainActor
class NewsCellViewModel: ObservableObject {
    @Published var likesCount: Int = 0
    @Published var voteState: VoteState = .none
    @Published var savedByCurrentUser: Bool = false
    @Published var upvoteScale: CGFloat = 1.0
    @Published var downvoteScale: CGFloat = 1.0
    
    private let db = Firestore.firestore()
    
    enum VoteState {
        case none, upvoted, downvoted
    }
    
    // MARK: - Voting Functions
    func handleUpvote(postId: String) async {
        // Animate button
        withAnimation(.easeInOut(duration: 0.1)) {
            upvoteScale = 1.2
        }
        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
            upvoteScale = 1.0
        }
        
        switch voteState {
        case .none:
            // Upvote the post
            voteState = .upvoted
            likesCount += 1
            do {
                try await upvotePost(postId: postId)
                try await AddLikedNews(postId: postId)
            } catch {
                // Revert on error
                voteState = .none
                likesCount -= 1
            }
            
        case .upvoted:
            // Remove upvote
            voteState = .none
            likesCount -= 1
            do {
                try await removeUpvote(postId: postId)
                try await removeLikedNews(postId: postId)
            } catch {
                // Revert on error
                voteState = .upvoted
                likesCount += 1
            }
            
        case .downvoted:
            // Switch from downvote to upvote
            voteState = .upvoted
            likesCount += 2 // Remove downvote (-1) and add upvote (+1) = +2
            do {
                try await removeDownvote(postId: postId)
                try await upvotePost(postId: postId)
                try await AddLikedNews(postId: postId)
                try await removeDisLikedNews(postId: postId)
            } catch {
                // Revert on error
                voteState = .downvoted
                likesCount -= 2
            }
        }
    }
    
    func handleDownvote(postId: String) async {
        // Animate button
        withAnimation(.easeInOut(duration: 0.1)) {
            downvoteScale = 1.2
        }
        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
            downvoteScale = 1.0
        }
        
        switch voteState {
        case .none:
            // Downvote the post
            voteState = .downvoted
            likesCount -= 1
            do {
                try await downvotePost(postId: postId)
                try await AddDisLikedNews(postId: postId)
            } catch {
                // Revert on error
                voteState = .none
                likesCount += 1
            }
            
        case .downvoted:
            // Remove downvote
            voteState = .none
            likesCount += 1
            do {
                try await removeDownvote(postId: postId)
                try await removeDisLikedNews(postId: postId)
            } catch {
                // Revert on error
                voteState = .downvoted
                likesCount -= 1
            }
            
        case .upvoted:
            // Switch from upvote to downvote
            voteState = .downvoted
            likesCount -= 2 // Remove upvote (-1) and add downvote (-1) = -2
            do {
                try await removeUpvote(postId: postId)
                try await downvotePost(postId: postId)
                try await AddDisLikedNews(postId: postId)
                try await removeLikedNews(postId: postId)
            } catch {
                // Revert on error
                voteState = .upvoted
                likesCount += 2
            }
        }
    }
    
    // MARK: - Firestore Operations
    private func upvotePost(postId: String) async throws {
        try await db.collection("news").document(postId).updateData([
            "likesCount": FieldValue.increment(Int64(1))
        ])
    }
    
    private func downvotePost(postId: String) async throws {
        try await db.collection("news").document(postId).updateData([
            "likesCount": FieldValue.increment(Int64(-1))
        ])
    }
    
    private func removeUpvote(postId: String) async throws {
        try await db.collection("news").document(postId).updateData([
            "likesCount": FieldValue.increment(Int64(-1))
        ])
    }
    
    private func removeDownvote(postId: String) async throws {
        try await db.collection("news").document(postId).updateData([
            "likesCount": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Fetch Vote Status
    func fetchVotesStatus(postId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Fetch the post to get current likes count
            let postDoc = try await db.collection("news").document(postId).getDocument()
            if let data = postDoc.data(), let likes = data["likesCount"] as? Int {
                self.likesCount = likes
            }
            
            // Check user's vote status
            let userVoteDoc = try await db.collection("users")
                .document(userId)
                .collection("votes")
                .document(postId)
                .getDocument()
            
            if let voteData = userVoteDoc.data(), let vote = voteData["vote"] as? String {
                self.voteState = vote == "upvote" ? .upvoted : .downvoted
            } else {
                self.voteState = .none
            }
        } catch {
            // Silent error handling
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
            
            let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)

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
                    "DislikedCount": FieldValue.increment(Int64(1))
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
                    "DislikedCount": FieldValue.increment(Int64(-1))
                ])

        } catch {
            throw error
        }
    }
}
