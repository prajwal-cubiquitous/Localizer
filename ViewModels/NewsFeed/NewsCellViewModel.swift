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
    
    
    private let db = Firestore.firestore()
    
    
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
    
    func fetchVotesStatus(postId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("news")
            .document(postId)
        
        do {
            let document = try await docRef.getDocument()
            if let data = document.data(),
               let count = data["likesCount"] as? Int {
                await MainActor.run {
                    self.likesCount = count
                }
            }
            let snapshot = try await docRef.collection("votes")
                .document(uid).getDocument()
            if let data = snapshot.data(), let voteType = data["voteType"] as? Int {
                DispatchQueue.main.async {
                    switch voteType {
                    case 1:
                        self.voteState = .upvoted
                    case -1:
                        self.voteState = .downvoted
                    case 0:
                        self.voteState = .none
                    default:
                        self.voteState = .none
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.voteState = .none
                }
            }
        } catch {
            print("DEBUG: Unable to fetch the vote status: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.voteState = .none
            }
        }
    }
    
    
    func incrementLikesCount(forPostId postId: String, by amount: Int) async throws {
        try await db.collection("news")
            .document(postId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(amount))
            ])
    }
    
    func handleUpvote(postId: String) async {
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
                try await saveVote(postId: postId, voteType: 1, PostLikeCount: 1)
            }catch{
                print(error.localizedDescription)
            }
        case .upvoted:
            voteState = .none
            likesCount -= 1
            do{
                try await saveVote(postId: postId, voteType: 0, PostLikeCount: -1)
            }catch{
                print(error.localizedDescription)
            }
        case .downvoted:
            voteState = .upvoted
            likesCount += 2
            do{
                try await saveVote(postId: postId, voteType: 1, PostLikeCount: 2)
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func handleDownvote(postId: String) async {
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
                try await saveVote(postId: postId, voteType: -1, PostLikeCount: -1)
            }catch{
                print(error.localizedDescription)
            }
        case .downvoted:
            voteState = .none
            likesCount += 1
            do{
                try await saveVote(postId: postId, voteType: 0, PostLikeCount: 1)
            }catch{
                print(error.localizedDescription)
            }
        case .upvoted:
            voteState = .downvoted
            likesCount -= 2 // Remove upvote (+1) and add downvote (-1) = -2
            do{
                try await saveVote(postId: postId, voteType: -1, PostLikeCount: -2)
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    
}

enum VoteState {
    case upvoted, downvoted, none
}
