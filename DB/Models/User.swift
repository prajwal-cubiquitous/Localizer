//
//  User.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/30/25.
//

import Foundation
import SwiftData
import FirebaseFirestore

enum UserRole: String, Codable, CaseIterable, Sendable {
    case endUser = "EndUser"
    case admin = "Admin"
    case authority = "Authority"
}

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
    var role: UserRole = .endUser
    var constituencyIDs: [String]? = ["","",""]
    @ServerTimestamp var lastUpdated: Date?
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
    var role: String
    var constituencyIDs: [String]?
    
    // Inverse relationship to LocalNews - this will help with cascade delete
    @Relationship(deleteRule: .cascade, inverse: \LocalNews.user) 
    var newsItems: [LocalNews] = []
    
    init(id: String, name: String,username: String, email: String, bio: String, profileImageUrl: String, postCount: Int, likedCount: Int,dislikedCount: Int, SavedPostsCount: Int, commentCount: Int, role: String = UserRole.endUser.rawValue, constituencyIDs: [String]? = nil) {
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
        self.role = role
        self.constituencyIDs = constituencyIDs
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
            commentCount: user.commentsCount,
            role: user.role.rawValue,
            constituencyIDs: user.constituencyIDs
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
            commentCount: user.commentsCount,
            role: user.role.rawValue,
            constituencyIDs: user.constituencyIDs
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
            commentsCount: self.commentCount,
            role: UserRole(rawValue: self.role) ?? .endUser,
            constituencyIDs: self.constituencyIDs
        )
    }
}

struct DummylocalUser{
    static var user1 = LocalUser(id: "kfjiehoi342", name: "Parthik", username: "padda", email: "padda@gmail.com", bio: "i am padda", profileImageUrl: "klodsfjlds", postCount: 20, likedCount: 10, dislikedCount: 10, SavedPostsCount: 0, commentCount: 5, role: UserRole.endUser.rawValue, constituencyIDs: ["560043", "560001"])
}


// MARK :- For creating temp Dictionary for storing the user detials like username and profilePictureURL


struct CachedUser {
    let username: String
    let profilePictureUrl: String
    let role: String
}

class UserCache {
    static let shared = UserCache()
    
    private init() {
    }  // Prevent instantiation

    // ✅ Simple actor-based thread-safe implementation
    private actor CacheActor {
        private var cache: [String: CachedUser] = [:]
        
        func getUser(for userId: String) -> CachedUser? {
            return cache[userId]
        }
        
        func setUser(_ user: CachedUser, for userId: String) {
            cache[userId] = user
        }
        
        func clearAll() {
            cache.removeAll()
        }
        
        func getAllUsers() -> [String: CachedUser] {
            return cache
        }
    }
    
    private let cacheActor = CacheActor()
    
    // ✅ Thread-safe access to cache
    var cacheusers: [String: CachedUser] {
        get {
            Task {
                return await cacheActor.getAllUsers()
            }
            // Fallback for synchronous access
            return [:]
        }
        set {
            // This setter is kept for backward compatibility but not recommended
            Task {
                await cacheActor.clearAll()
                for (key, value) in newValue {
                    await cacheActor.setUser(value, for: key)
                }
            }
        }
    }
    
    // ✅ Simple and safe user fetching
    func getUser(userId: String) async -> CachedUser? {
        // First check if user is already cached
        if let cachedUser = await cacheActor.getUser(for: userId) {
            return cachedUser
        }
        
        // If not cached, fetch from Firestore
        do {
            let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
            let newCachedUser = CachedUser(username: user.username, profilePictureUrl: user.profileImageUrl, role: user.role.rawValue)
            
            // Cache the user for future use
            await cacheActor.setUser(newCachedUser, for: userId)
            
            return newCachedUser
        } catch {
            print("❌ Failed to fetch user \(userId): \(error)")
            return nil
        }
    }
    
    // ✅ Simplified batch fetch - no complex concurrency
    func getUsers(userIds: [String]) async -> [String: CachedUser] {
        var result: [String: CachedUser] = [:]
        
        // Process each user ID one by one to avoid concurrency issues
        for userId in userIds {
            if let cachedUser = await getUser(userId: userId) {
                result[userId] = cachedUser
            }
        }
        
        return result
    }
    
    // ✅ Safe cache clearing
    func clearCache() {
        Task {
            await cacheActor.clearAll()
        }
    }
    
    // ✅ Safe individual user caching
    func cacheUser(userId: String, cachedUser: CachedUser) {
        Task {
            await cacheActor.setUser(cachedUser, for: userId)
        }
    }
}

struct UserNewsActivity: Codable, Identifiable {
    var id: String = UUID().uuidString
    var savedNews: [String]
    var likedNews: [String]
    var commentedNews: [String]
}
