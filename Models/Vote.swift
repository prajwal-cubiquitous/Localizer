import Foundation
import SwiftData

/// Local SwiftData model tracking a user's vote (upvote/downvote) on a post.
/// `voteType`: 1 for upvote, -1 for down-vote, 0 means no active vote (entry is deleted).
@Model
class LocalVote {
    /// Composite primary key: "{userId}_{postId}" so each user can vote once per post.
    @Attribute(.unique) var id: String
    var postId: String
    var userId: String
    var voteType: Int
    var timestamp: Date
    
    init(id: String, postId: String, userId: String, voteType: Int, timestamp: Date = .now) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.voteType = voteType
        self.timestamp = timestamp
    }
}


struct Vote: Identifiable, Codable {
    var id: String { "\(userId)_\(postId)" } // Composite key
    let postId: String
    let userId: String
    var voteType: Int // 1 = upvote, -1 = downvote, 0 = neutral
    var timestamp: Date
//
//    // Optional: Firestore requires this initializer if you want custom decoding/encoding
//    init(postId: String, userId: String, voteType: Int, timestamp: Date = .now) {
//        self.postId = postId
//        self.userId = userId
//        self.voteType = voteType
//        self.timestamp = timestamp
//    }
}
