import Foundation

struct Reply: Identifiable, Hashable {
    let id = UUID()
    var username: String
    var text: String
    var profileImageName: String // For placeholder system images
    var timestamp: Date = Date()
}

struct Comment: Identifiable, Hashable {
    var id = UUID()
    var userId: String
    var username: String
    var text: String
    var profileImageName: String // For placeholder system images
    var timestamp: Date = Date()
    var likes: Int = 0
    var isLikedByCurrentUser: Bool = false
    var replies: [Reply] = []
    var areRepliesVisible: Bool = false // New property to control reply visibility
}


func getSampleComments() -> [Comment] {
    return [
        Comment(userId: "ldhgfoivdjfhojgdf", username: "NatureLover", text: "Beautiful shot! Where was this taken?", profileImageName: "leaf.fill", likes: 15, replies: [
            Reply(username: "TravelBug", text: "I think it's near the Rockies!", profileImageName: "airplane", timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!),
            Reply(username: "NatureLover", text: "Oh, good to know! Thanks @TravelBug", profileImageName: "leaf.fill", timestamp: Calendar.current.date(byAdding: .minute, value: -2, to: Date())!)
        ]),
        Comment(userId: "ldhgfoivdjfhojgdf", username: "TravelBug", text: "Wow, adding this to my travel list! 😍", profileImageName: "airplane", timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, likes: 22, isLikedByCurrentUser: true),
        Comment(userId: "ldhgfoivdjfhojgdf" , username: "FoodieGal", text: "Looks delicious! Recipe please? 😋", profileImageName: "fork.knife", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, likes: 5, replies: [
            Reply(username: "ChefJohn", text: "Coming right up!", profileImageName: "figure.cook", timestamp: Calendar.current.date(byAdding: .minute, value: -10, to: Date())!)
        ]),
        Comment(userId: "ldhgfoivdjfhojgdf" , username: "PhotoDave", text: "Great composition and lighting. Keep it up!", profileImageName: "camera.fill", timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, likes: 8, replies: [])
    ]
}
