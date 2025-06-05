//
//  commentsViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/5/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    func addComment(toNewsId newsId: String, commentText: String) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let comment = CommentForFirebase(userId: uid ,text: commentText)
        
        let commentRef = Firestore.firestore()
            .collection("news")
            .document(newsId)
            .collection("comments")
            .document()

        var newComment = comment
        newComment.id = commentRef.documentID // Assign the auto-generated ID

        try commentRef.setData(from: newComment)
    }

}
