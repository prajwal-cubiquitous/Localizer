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
        
        let commentRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document()
        
        try await commentRef.setData([
            "userId": uid,
            "text": commentText,
            "timestamp": Date(),
            "likes": 0
        ])
        
        Task{
            try await AddCommentedNews(postId: newsId)
        }
        
        // Refresh comments instead of manually appending
        try await fetchComments(forNewsId: newsId)
        
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
            
            print("DEBUG: Fetched \(snapshot.documents.count) comment documents for newsId: \(newsId)")
            
            let fetchedComments = snapshot.documents.compactMap { doc in
                do {
                    var comment = try doc.data(as: Comment.self)
                    print("DEBUG: Successfully decoded comment: \(comment.text)")
                    print("DEBUG: Comment ID from @DocumentID: \(comment.id ?? "nil")")
                    print("DEBUG: Document ID from doc: \(doc.documentID)")
                    print("DEBUG: Comment documentId field: \(comment.documentId ?? "nil")")
                    
                    // If both IDs are nil, set the documentId field
                    if comment.actualId == nil {
                        comment = Comment(
                            id: nil, // Don't set @DocumentID manually
                            documentId: doc.documentID, // Use the regular field
                            userId: comment.userId,
                            username: comment.username,
                            text: comment.text,
                            profileImageName: comment.profileImageName,
                            timestamp: comment.timestamp,
                            likes: comment.likes,
                            replies: comment.replies
                        )
                        print("DEBUG: Set documentId field to: \(doc.documentID)")
                    }
                    
                    print("DEBUG: Final comment actualId: \(comment.actualId ?? "nil")")
                    return comment
                } catch {
                    print("DEBUG: Failed to decode comment from document \(doc.documentID): \(error)")
                    print("DEBUG: Document data: \(doc.data())")
                    return nil
                }
            }
            
            print("DEBUG: Successfully decoded \(fetchedComments.count) comments")
            
            await MainActor.run {
                self.comments = fetchedComments
            }
            
            for comment in comments {
                let FetchedUser = try await fetchCurrentUser(comment.userId)

                UserCache.shared.cacheusers[comment.userId] = CachedUser(username: FetchedUser.username, profilePictureUrl: FetchedUser.profileImageUrl)
            }
        } catch {
            print("DEBUG: Error in fetchComments: \(error)")
            throw error
        }
    }
    
    func toggleLike(for comment: Comment, inNews newsId: String) async  {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let commentId = comment.actualId else { return }

        let commentRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(commentId)

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
                    if let index = comments.firstIndex(where: { $0.actualId == comment.actualId }) {
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
                    if let index = comments.firstIndex(where: { $0.actualId == comment.actualId }) {
                        comments[index].likes += 1
                    }
                }
            }
        } catch {
        }
    }

    func checkIfLiked(comment: Comment, newsId: String) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        guard let commentId = comment.actualId else { return false }

        let likeRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(commentId)
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

        let db = Firestore.firestore()
        let replyRef = db
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document(commentId)
            .collection("replies")
            .document() // Let Firestore auto-generate the document ID
            
        try await replyRef.setData([
            "userId": currentUser.uid,
            "text": replyText,
            "timestamp": Date()
        ])
        
        // Refresh comments to show the new reply
        try await fetchComments(forNewsId: newsId)
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
    
    func AddCommentedNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)
        
        do {
            
            try await docRef.setData([
                "CommentedNews": FieldValue.arrayUnion([postId])
            ], merge: true)
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "commentsCount": FieldValue.increment(Int64(1))
                ])
            
        } catch {
            throw error
        }
    }
    
    func removeCommentedNews(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(userId).collection("userNewsActivity").document(userId)

        do {
            // First check if actually saved
            let document = try await docRef.getDocument()
            
            if let data = document.data(),
               let LikedNews = data["CommentedNews"] as? [String],
               !LikedNews.contains(postId) {
                return
            }
            
            try await docRef.setData([
                "CommentedNews": FieldValue.arrayRemove([postId])
            ], merge: true)
            
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "commentsCount": FieldValue.increment(Int64(-1))
                ])

        } catch {
            throw error
        }
    }
    
}
