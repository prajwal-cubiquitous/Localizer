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
    
    @Published var voteState: VoteState = VoteState.none
    @Published var likesCount: Int = 0
    @Published var showingMenu: Bool = false
    // Animation states for button scaling
    @Published var upvoteScale: CGFloat = 1.0
    @Published var downvoteScale: CGFloat = 1.0
    @Published var savedByCurrentUser: Bool = false
    
    // ✅ Add vote state caching and operation tracking
    private static var voteStateCache: [String: VoteState] = [:]
    private static var likesCountCache: [String: Int] = [:]
    private static var savedStateCache: [String: Bool] = [:]
    private var isVoteOperationInProgress = false
    
    private let db = Firestore.firestore()
    private let postId: String
    
    // ✅ Constructor that accepts LocalNews
    init(localNews: LocalNews) {
        self.postId = localNews.id
        self.likesCount = localNews.likesCount
        
        // ✅ Load from cache if available
        if let cachedVoteState = Self.voteStateCache[postId] {
            self.voteState = cachedVoteState
        }
        if let cachedLikesCount = Self.likesCountCache[postId] {
            self.likesCount = cachedLikesCount
        }
        if let cachedSavedState = Self.savedStateCache[postId] {
            self.savedByCurrentUser = cachedSavedState
        }
    }
    
    // ✅ Default constructor for cases where LocalNews isn't available
    init() {
        self.postId = ""
        self.likesCount = 0
    }
    
    // ✅ Static method to clear cache (call on refresh)
    nonisolated static func clearCache() {
        Task { @MainActor in
            voteStateCache.removeAll()
            likesCountCache.removeAll()
            savedStateCache.removeAll()
        }
    }
    
    // ✅ Optimized fetch - only fetch if not in cache
    func fetchVotesStatusIfNeeded(postId: String) async {
        // Only fetch if not in cache
        if Self.voteStateCache[postId] != nil && Self.savedStateCache[postId] != nil {
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("news").document(postId)
        
        do {
            // Fetch likes count
            let document = try await docRef.getDocument()
            if let data = document.data(),
               let count = data["likesCount"] as? Int {
                await MainActor.run {
                    self.likesCount = count
                    Self.likesCountCache[postId] = count
                }
            }
            
            // Fetch vote state
            let snapshot = try await docRef.collection("votes").document(uid).getDocument()
            if let data = snapshot.data(), let voteType = data["voteType"] as? Int {
                let newVoteState: VoteState = switch voteType {
                case 1: .upvoted
                case -1: .downvoted
                default: VoteState.none
                }
                await MainActor.run {
                    self.voteState = newVoteState
                    Self.voteStateCache[postId] = newVoteState
                }
            } else {
                await MainActor.run {
                    self.voteState = VoteState.none
                    Self.voteStateCache[postId] = VoteState.none
                }
            }
            
            // Fetch saved state
            await checkIfNewsIsSaved1(postId: postId)
            
        } catch {
            await MainActor.run {
                self.voteState = VoteState.none
                Self.voteStateCache[postId] = VoteState.none
            }
        }
    }

    /// Saves or updates a vote in the subcollection `votes` under the specific `news` document
    func saveVote(postId: String, voteType: Int, PostLikeCount: Int) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let vote = Vote(postId: postId, userId: uid, voteType: voteType, timestamp: Date.now)
        let docRef = db.collection("news")
            .document(vote.postId)
            .collection("votes")
            .document(vote.userId) // each user has one vote per post
        
        try docRef.setData(from: vote)
        
        try await incrementLikesCount(forPostId: postId, by: PostLikeCount)
    }
    
    func incrementLikesCount(forPostId postId: String, by amount: Int) async throws {
        try await db.collection("news")
            .document(postId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(amount))
            ])
        
        // ✅ Update cache
        let newCount = max(0, likesCount + amount)
        Self.likesCountCache[postId] = newCount
    }
    
    func handleUpvote(postId: String) async {
        // ✅ Prevent concurrent operations
        guard !isVoteOperationInProgress else { return }
        isVoteOperationInProgress = true
        defer { isVoteOperationInProgress = false }
        
        // Scale animation
        withAnimation(.easeInOut(duration: 0.1)) {
            upvoteScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.upvoteScale = 1.0
            }
        }
        
        // ✅ Store previous state for rollback on error
        let previousVoteState = voteState
        let previousLikesCount = likesCount
        
        // Vote logic with optimistic updates
        switch voteState {
        case .none:
            voteState = .upvoted
            likesCount += 1
            Self.voteStateCache[postId] = .upvoted
            Self.likesCountCache[postId] = likesCount
            
            do {
                try await saveVote(postId: postId, voteType: 1, PostLikeCount: 1)
                // ✅ Sequential execution to prevent race conditions
                try await AddLikedNews(postId: postId)
            } catch {
                // ✅ Rollback on error
                voteState = previousVoteState
                likesCount = previousLikesCount
                Self.voteStateCache[postId] = previousVoteState
                Self.likesCountCache[postId] = previousLikesCount
                print("Error handling upvote: \(error.localizedDescription)")
            }
            
        case .upvoted:
            voteState = VoteState.none
            likesCount -= 1
            Self.voteStateCache[postId] = VoteState.none
            Self.likesCountCache[postId] = likesCount
            
            do {
                try await saveVote(postId: postId, voteType: 0, PostLikeCount: -1)
                try await removeLikedNews(postId: postId)
            } catch {
                voteState = previousVoteState
                likesCount = previousLikesCount
                Self.voteStateCache[postId] = previousVoteState
                Self.likesCountCache[postId] = previousLikesCount
                print("Error handling upvote removal: \(error.localizedDescription)")
            }
            
        case .downvoted:
            voteState = .upvoted
            likesCount += 2
            Self.voteStateCache[postId] = .upvoted
            Self.likesCountCache[postId] = likesCount
            
            do {
                try await saveVote(postId: postId, voteType: 1, PostLikeCount: 2)
                // ✅ Sequential execution
                try await removeDisLikedNews(postId: postId)
                try await AddLikedNews(postId: postId)
            } catch {
                voteState = previousVoteState
                likesCount = previousLikesCount
                Self.voteStateCache[postId] = previousVoteState
                Self.likesCountCache[postId] = previousLikesCount
                print("Error handling vote change: \(error.localizedDescription)")
            }
        }
    }
    
    func handleDownvote(postId: String) async {
        // ✅ Prevent concurrent operations
        guard !isVoteOperationInProgress else { return }
        isVoteOperationInProgress = true
        defer { isVoteOperationInProgress = false }
        
        // Scale animation
        withAnimation(.easeInOut(duration: 0.1)) {
            downvoteScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.downvoteScale = 1.0
            }
        }
        
        // ✅ Store previous state for rollback on error
        let previousVoteState = voteState
        let previousLikesCount = likesCount
        
        // Vote logic with optimistic updates
        switch voteState {
        case .none:
            voteState = .downvoted
            likesCount -= 1
            Self.voteStateCache[postId] = .downvoted
            Self.likesCountCache[postId] = likesCount
            
            do {
                try await saveVote(postId: postId, voteType: -1, PostLikeCount: -1)
                try await AddDisLikedNews(postId: postId)
            } catch {
                voteState = previousVoteState
                likesCount = previousLikesCount
                Self.voteStateCache[postId] = previousVoteState
                Self.likesCountCache[postId] = previousLikesCount
                print("Error handling downvote: \(error.localizedDescription)")
            }
            
        case .downvoted:
            voteState = VoteState.none
            likesCount += 1
            Self.voteStateCache[postId] = VoteState.none
            Self.likesCountCache[postId] = likesCount
            
            do {
                try await saveVote(postId: postId, voteType: 0, PostLikeCount: 1)
                try await removeDisLikedNews(postId: postId)
            } catch {
                voteState = previousVoteState
                likesCount = previousLikesCount
                Self.voteStateCache[postId] = previousVoteState
                Self.likesCountCache[postId] = previousLikesCount
                print("Error handling downvote removal: \(error.localizedDescription)")
            }
            
        case .upvoted:
            voteState = .downvoted
            likesCount -= 2 // Remove upvote (+1) and add downvote (-1) = -2
            Self.voteStateCache[postId] = .downvoted
            Self.likesCountCache[postId] = likesCount
            
            do {
                try await saveVote(postId: postId, voteType: -1, PostLikeCount: -2)
                // ✅ Sequential execution
                try await removeLikedNews(postId: postId)
                try await AddDisLikedNews(postId: postId)
            } catch {
                voteState = previousVoteState
                likesCount = previousLikesCount
                Self.voteStateCache[postId] = previousVoteState
                Self.likesCountCache[postId] = previousLikesCount
                print("Error handling vote change: \(error.localizedDescription)")
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
                
                // Update local state and cache
                await MainActor.run {
                    self.savedByCurrentUser = true
                    Self.savedStateCache[postId] = true
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
            // ✅ Return cached value if available
            if let cachedState = Self.savedStateCache[postId] {
                await MainActor.run {
                    self.savedByCurrentUser = cachedState
                }
                return
            }
            
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let docRef = db
                .collection("users")
                .document(userId)
                .collection("userNewsActivity")
                .document(userId)

            do {
                let document = try await docRef.getDocument()

                if let data = document.data(),
                   let savedNews = data["savedNews"] as? [String] {
                    let isSaved = savedNews.contains(postId)
                    await MainActor.run {
                        self.savedByCurrentUser = isSaved
                        Self.savedStateCache[postId] = isSaved
                    }
                } else {
                    await MainActor.run {
                        self.savedByCurrentUser = false
                        Self.savedStateCache[postId] = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.savedByCurrentUser = false
                    Self.savedStateCache[postId] = false
                }
            }
        }
        
        // MARK: - Remove Saved News
        func removeSavedNews1(postId: String) async throws {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let docRef = db
                .collection("users")
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
                
                // Update local state and cache
                await MainActor.run {
                    self.savedByCurrentUser = false
                    Self.savedStateCache[postId] = false
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
            // ✅ Check if already in liked array to prevent duplicates
            let document = try await docRef.getDocument()
            if let data = document.data(),
               let likedNews = data["LikedNews"] as? [String],
               likedNews.contains(postId) {
                return // Already liked
            }
            
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
            // First check if actually in liked array
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
            // ✅ Check if already in disliked array to prevent duplicates
            let document = try await docRef.getDocument()
            if let data = document.data(),
               let dislikedNews = data["DisLikedNews"] as? [String],
               dislikedNews.contains(postId) {
                return // Already disliked
            }
            
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
            // First check if actually in disliked array
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
}
enum VoteState {
    case upvoted, downvoted, none
}

