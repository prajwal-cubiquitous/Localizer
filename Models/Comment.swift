import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    let postId: String
    let userId: String
    let content: String
    let timestamp: Timestamp
    var likesCount: Int
    var user: User?
}
