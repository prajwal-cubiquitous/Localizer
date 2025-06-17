//
//  User.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/30/25.
//

import Foundation
import SwiftData

struct User: Identifiable, Codable, Sendable {
    var id : String
    var name: String
    let email: String
    var username: String
    var bio: String = ""
    var profileImageUrl: String = ""
    var postsCount: Int = 0
    var likedCount: Int = 0
    var dislikedCount: Int = 0
    var SavedPostsCount: Int = 0
    var commentsCount: Int = 0
}

@Model
final class LocalUser: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var username: String
    var bio: String
    var profileImageUrl: String
    var postCount: Int
    var likedCount: Int
    var dislikedCount: Int
    var SavedPostsCount: Int
    var commentCount: Int
    
    // Inverse relationship to LocalNews - this will help with cascade delete
    @Relationship(deleteRule: .cascade, inverse: \LocalNews.user) 
    var newsItems: [LocalNews] = []
    
    init(id: String, name: String,username: String, email: String, bio: String, profileImageUrl: String, postCount: Int, likedCount: Int,dislikedCount: Int, SavedPostsCount: Int, commentCount: Int) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.postCount = postCount
        self.likedCount = likedCount
        self.dislikedCount = dislikedCount
        self.SavedPostsCount = SavedPostsCount
        self.commentCount = commentCount
    }
}

extension LocalUser {
    static func fromCurrentUser(user: User, currentUserId: String) -> LocalUser? {
        // Only create LocalUser for the current logged-in user
        guard user.id == currentUserId else {
            print("⚠️ Attempted to create LocalUser for non-current user: \(user.id)")
            return nil
        }
        
        return LocalUser(
            id: user.id,
            name: user.name,
            username: user.username,
            email: user.email,
            bio: user.bio,
            profileImageUrl: user.profileImageUrl,
            postCount: user.postsCount,
            likedCount: user.likedCount, 
            dislikedCount: user.dislikedCount, 
            SavedPostsCount: user.SavedPostsCount,
            commentCount: user.commentsCount
        )
    }
    
    static func from(user: User) -> LocalUser {
        print("⚠️ WARNING: Creating LocalUser for potentially non-current user: \(user.id)")
        return LocalUser(
            id: user.id,
            name: user.name,
            username: user.username,
            email: user.email,
            bio: user.bio,
            profileImageUrl: user.profileImageUrl,
            postCount: user.postsCount,
            likedCount: user.likedCount, 
            dislikedCount: user.dislikedCount, 
            SavedPostsCount: user.SavedPostsCount,
            commentCount: user.commentsCount
        )
    }
    
    func toUser() -> User {
        return User(
            id: self.id,
            name: self.name,
            email: self.email,
            username: self.username,
            bio: self.bio,
            profileImageUrl: self.profileImageUrl,
            postsCount: self.postCount,
            likedCount: self.likedCount,
            SavedPostsCount: self.SavedPostsCount,
            commentsCount: self.commentCount
        )
    }
}

struct DummylocalUser{
    static var user1 = LocalUser(id: "kfjiehoi342", name: "Parthik", username: "padda", email: "padda@gmail.com", bio: "i am padda", profileImageUrl: "klodsfjlds", postCount: 20, likedCount: 10, dislikedCount: 10, SavedPostsCount: 0, commentCount: 5)
}


// MARK :- For creating temp Dictionary for storing the user detials like username and profilePictureURL


struct CachedUser {
    let username: String
    let profilePictureUrl: String
}

class UserCache {
    static let shared = UserCache()
    
    private init() {
    }  // Prevent instantiation

    // Temp in-memory dictionary: [userId: CachedUser]
    var cacheusers: [String: CachedUser] = [:]
    
    // ✅ Enhanced user fetching with caching
    func getUser(userId: String) async -> CachedUser? {
        // First check if user is already cached
        if let cachedUser = cacheusers[userId] {
            return cachedUser
        }
        
        // If not cached, fetch from Firestore
        do {
            let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
            let cachedUser = CachedUser(username: user.username, profilePictureUrl: user.profileImageUrl)
            
            // Cache the user for future use
            cacheusers[userId] = cachedUser
            return cachedUser
        } catch {
            print("❌ Failed to fetch user \(userId): \(error)")
            return nil
        }
    }
    
    // ✅ Batch fetch multiple users efficiently
    func getUsers(userIds: [String]) async -> [String: CachedUser] {
        var result: [String: CachedUser] = [:]
        var usersToFetch: [String] = []
        
        // First, get cached users
        for userId in userIds {
            if let cachedUser = cacheusers[userId] {
                result[userId] = cachedUser
            } else {
                usersToFetch.append(userId)
            }
        }
        
        // Fetch remaining users concurrently
        await withTaskGroup(of: (String, CachedUser?).self) { group in
            for userId in usersToFetch {
                group.addTask {
                    let cachedUser = await self.getUser(userId: userId)
                    return (userId, cachedUser)
                }
            }
            
            for await (userId, cachedUser) in group {
                if let cachedUser = cachedUser {
                    result[userId] = cachedUser
                }
            }
        }
        
        return result
    }
    
    // ✅ Clear cache when needed
    func clearCache() {
        cacheusers.removeAll()
    }
}

struct UserNewsActivity: Codable, Identifiable {
    var id: String = UUID().uuidString
    var savedNews: [String]
    var likedNews: [String]
    var commentedNews: [String]
}
