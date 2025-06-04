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
