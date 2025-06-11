import Foundation
import FirebaseFirestore

struct Reply: Identifiable, Codable, Hashable {
    var id = UUID()
    var userId: String
    var username: String?
    var text: String
    var profileImageName: String? // For placeholder system images
    var timestamp: Date
    
    init(id: UUID = UUID(), userId: String, username: String? = nil, text: String, profileImageName: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.username = username
        self.text = text
        self.profileImageName = profileImageName
        self.timestamp = timestamp
    }
}

struct Comment: Identifiable, Hashable, Codable {
    var id = UUID()
    var userId: String
    var username: String?
    var text: String
    var profileImageName: String? // For placeholder system images
    var timestamp: Date
    var likes: Int
    var replies: [Reply]
    
    init(id: UUID = UUID(), userId: String, username: String? = nil, text: String, profileImageName: String? = nil, timestamp: Date = Date(), likes: Int = 0, replies: [Reply] = []) {
        self.id = id
        self.userId = userId
        self.username = username
        self.text = text
        self.profileImageName = profileImageName
        self.timestamp = timestamp
        self.likes = likes
        self.replies = replies
    }
}


func getSampleComments() -> [Comment] {
    return [
        Comment(userId: "ldhgfoivdjfhojgdf", username: "NatureLover", text: "Beautiful shot! Where was this taken?", profileImageName: "leaf.fill", likes: 15, replies: [
            Reply(userId: "khdfihdsi", username: "TravelBug", text: "I think it's near the Rockies!", profileImageName: "airplane", timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!),
            Reply(userId: "bifsgds", username: "NatureLover", text: "Oh, good to know! Thanks @TravelBug", profileImageName: "leaf.fill", timestamp: Calendar.current.date(byAdding: .minute, value: -2, to: Date())!)
        ]),
        Comment(userId: "ldhgfoivdjfhojgdf", username: "TravelBug", text: "Wow, adding this to my travel list! 😍", profileImageName: "airplane", timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, likes: 22),
        Comment(userId: "ldhgfoivdjfhojgdf" , username: "FoodieGal", text: "Looks delicious! Recipe please? 😋", profileImageName: "fork.knife", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, likes: 5, replies: [
            Reply(userId: "sjhfihsidhf", username: "ChefJohn", text: "Coming right up!", profileImageName: "figure.cook", timestamp: Calendar.current.date(byAdding: .minute, value: -10, to: Date())!)
        ]),
        Comment(userId: "ldhgfoivdjfhojgdf" , username: "PhotoDave", text: "Great composition and lighting. Keep it up!", profileImageName: "camera.fill", timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, likes: 8, replies: [])
    ]
}


struct CommentForFirebase: Identifiable, Codable, Hashable {
    @DocumentID var id: String?  // Firestore will auto-generate this if nil
    var userId: String
    var text: String
    var timestamp: Date
    var likes: Int
    
    // Optional initializer if you want to create comments manually
    init(id: String? = nil, userId: String , text: String, timestamp: Date = Date.now, likes: Int = 0) {
        self.id = id
        self.userId = userId
        self.text = text
        self.timestamp = timestamp
        self.likes = likes
    }
}
