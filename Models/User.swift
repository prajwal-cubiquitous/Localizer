//
//  User.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/30/25.
//

import Foundation
import SwiftData

struct User: Identifiable, Codable{
    var id : String
    var name: String
    let email: String
    var username: String
    var bio: String = ""
    var profileImageUrl: String = ""
    var postsCount: Int = 0
    var likedCount: Int = 0
    var commentsCount: Int = 0
}

@Model
class LocalUser {
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var username: String
    var bio: String?
    var profileImageUrl: String?
    var postCount: Int
    var likedCount: Int
    var commentCount: Int
    
    init(id: String, name: String,username: String, email: String, bio: String, profileImageUrl: String, postCount: Int, likedCount: Int, commentCount: Int) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.postCount = postCount
        self.likedCount = likedCount
        self.commentCount = commentCount
    }
}

extension LocalUser {
    static func from(user: User) -> LocalUser {
        return LocalUser(
            id: user.id,
            name: user.name,
            username: user.username,
            email: user.email,
            bio: user.bio,
            profileImageUrl: user.profileImageUrl,
            postCount: user.postsCount,
            likedCount: user.likedCount,
            commentCount: user.commentsCount
        )
    }
    
    func toUser() -> User {
        return User(
            id: self.id,
            name: self.name,
            email: self.email,
            username: self.username,
            bio: self.bio ?? "",
            profileImageUrl: self.profileImageUrl ?? "",
            postsCount: self.postCount,
            likedCount: self.likedCount,
            commentsCount: self.commentCount
        )
    }
}

struct DummylocalUser{
    static var user1 = LocalUser(id: "kfjiehoi342", name: "Parthik", username: "padda", email: "padda@gmail.com", bio: "i am padda", profileImageUrl: "klodsfjlds", postCount: 20, likedCount: 10, commentCount: 5)
}
