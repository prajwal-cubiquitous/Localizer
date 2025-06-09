//
//  commentsViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/5/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class CommentsViewModel: ObservableObject {
    
    @Published var comments: [Comment] = []
    private let db = Firestore.firestore()
    
    
    func addComment(toNewsId newsId: String, commentText: String) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
                
        let comment = Comment(userId: uid, text: commentText)
        
        let commentRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(comment.id.uuidString)
        
        try commentRef.setData(from: comment)
        comments.append(comment)
        try await incrementLikesCount(forPostId: newsId, by: 1)
    }
    
    func incrementLikesCount(forPostId postId: String, by amount: Int) async throws {
        try await db.collection("news")
            .document(postId)
            .updateData([
                "commentsCount": FieldValue.increment(Int64(amount))
            ])
    }
    
    func fetchComments(forNewsId newsId: String) async throws {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("news")
                .document(newsId)
                .collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            let fetchedComments = snapshot.documents.compactMap { doc in
                try? doc.data(as: Comment.self)
            }
            
            self.comments = fetchedComments
            
            for comment in comments {
                let FetchedUser = try await fetchCurrentUser(comment.userId)

                UserCache.shared.cacheusers[comment.userId] = CachedUser(username: FetchedUser.username, profilePictureUrl: FetchedUser.profileImageUrl)
            }
        } catch {
            print("❌ Failed to fetch comments: \(error.localizedDescription)")
             throw error
        }
    }
    
    func toggleLike(for comment: Comment, inNews newsId: String) async  {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let commentRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(comment.id.uuidString)

        let likeRef = commentRef
            .collection("likes")
            .document(uid)

        do {
            let docSnapshot = try await likeRef.getDocument()

            if docSnapshot.exists {
                // User has already liked → remove like
                try await likeRef.delete()
                try await commentRef.updateData([
                    "likes": FieldValue.increment(Int64(-1))
                ])

                await MainActor.run {
                    if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                        comments[index].likes -= 1
                    }
                }

            } else {
                // Add new like
                try await likeRef.setData([
                    "userId": uid,
                    "timestamp": Date()
                ])
                try await commentRef.updateData([
                    "likes": FieldValue.increment(Int64(1))
                ])

                await MainActor.run {
                    if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                        comments[index].likes += 1
                    }
                }
            }
        } catch {
            print("❌ Failed to toggle like: \(error.localizedDescription)")
        }
    }

    func checkIfLiked(comment: Comment, newsId: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }

        let likeRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(comment.id.uuidString)
            .collection("likes")
            .document(uid)

        do {
            let snapshot = try await likeRef.getDocument()
            return snapshot.exists
        } catch {
            return false
        }
    }
    
    func addReply(toNewsId newsId: String, commentId: String, replyText: String) async throws {
        guard let currentUser = Auth.auth().currentUser else { return }

        let reply = Reply(
            userId: currentUser.uid,
            text: replyText,
            timestamp: Date()
        )

        let db = Firestore.firestore()
        let replyRef = db
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(commentId)
            .collection("replies")
            .document(reply.id.uuidString)

        try replyRef.setData(from: reply)
    }


    func fetchReplies(forNewsId newsId: String, commentId: String) async throws -> [Reply] {
        let snapshot = try await Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(commentId)
            .collection("replies")
            .order(by: "timestamp", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Reply.self)
        }
    }
    
    func fetchCurrentUser(_ uid: String) async throws -> User {
        let docRef = Firestore.firestore().collection("users").document(uid)
        let snapshot = try await docRef.getDocument()
        guard let user = try? snapshot.data(as: User.self) else {
            throw NSError(domain: "PostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode current user"])
        }
        return user
    }
    
}
