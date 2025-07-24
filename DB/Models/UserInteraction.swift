import Foundation
import FirebaseFirestore

// Firestore model for tracking user votes on posts
struct UserVote: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let postId: String
    var voteType: Int // 1 for upvote, -1 for downvote
    let timestamp: Date
}

// Firestore model for tracking user likes on comments
struct CommentLike: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let commentId: String
    let timestamp: Date
}

// Firestore model for tracking saved posts
struct SavedPost: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let postId: String
    let timestamp: Date
}

// Firestore model for post reports
struct PostReport: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let postId: String
    let reason: String
    let timestamp: Date
}

// Enum for post feed filter types
enum PostFeedFilter: String, CaseIterable {
    case local = "Local"
    case saved = "Saved"
    case liked = "Liked"
    case commented = "Commented"
    case all = "All"
}
