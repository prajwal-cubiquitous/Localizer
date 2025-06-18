//
//  ActivityViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ActivityViewModel : ObservableObject{
    
    @Published var newsItems: [LocalNews] = []
    
    func fetchNews(postalCode: String) async throws {
        self.newsItems = []
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let snapshot = try await db.collection("news")
            .whereField("ownerUid", isEqualTo: uid)
            .whereField("postalCode", isEqualTo: postalCode)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let newsItemsFromFirebase = snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        }
        
        for item in newsItemsFromFirebase {
            // ✅ For current user's own posts, also use UserCache for consistency
            _ = await UserCache.shared.getUser(userId: item.ownerUid)
            
            // ✅ Create LocalNews without LocalUser relationship
            let localNews = LocalNews(
                id: item.id,
                ownerUid: item.ownerUid,
                caption: item.caption,
                timestamp: item.timestamp.dateValue(),
                likesCount: item.likesCount,
                commentsCount: item.commentsCount,
                postalCode: item.cosntituencyId,
                newsImageURLs: item.newsImageURLs,
                user: nil // ✅ No LocalUser relationship
            )
            
            self.newsItems.append(localNews)
        }
    }
    
    @MainActor
    func fetchLikedNews(postalCode: String) async throws{
        newsItems = []
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            
            guard let data = userDoc.data(),
                  let savedNewsIds = data["LikedNews"] as? [String] else {
                return
            }
            
            for newsId in savedNewsIds.reversed() {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == postalCode {
                    // ✅ Cache user data instead of creating LocalUser
                    _ = await UserCache.shared.getUser(userId: SavedNewsFromFirestore.ownerUid)
                    
                    // ✅ Create LocalNews without LocalUser relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        postalCode: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: nil // ✅ No LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch liked news: \(error)")
        }
    }
    
    @MainActor
    func fetchSavedNews(postalCode: String) async throws{
        newsItems = []
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            
            guard let data = userDoc.data(),
                  let savedNewsIds = data["savedNews"] as? [String] else {
                return
            }
            
            for newsId in savedNewsIds.reversed() {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == postalCode {
                    // ✅ Cache user data instead of creating LocalUser
                    _ = await UserCache.shared.getUser(userId: SavedNewsFromFirestore.ownerUid)
                    
                    // ✅ Create LocalNews without LocalUser relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        postalCode: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: nil // ✅ No LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch saved news: \(error)")
        }
    }
    
    @MainActor
    func fetchDisLikedNews(postalCode: String) async throws{
        newsItems = []
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            
            guard let data = userDoc.data(),
                  let savedNewsIds = data["DisLikedNews"] as? [String] else {
                return
            }
            
            for newsId in savedNewsIds.reversed() {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == postalCode {
                    // ✅ Cache user data instead of creating LocalUser
                    _ = await UserCache.shared.getUser(userId: SavedNewsFromFirestore.ownerUid)
                    
                    // ✅ Create LocalNews without LocalUser relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        postalCode: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: nil // ✅ No LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch disliked news: \(error)")
        }
    }
    
    @MainActor
    func commentedNews(postalCode: String) async throws{
        newsItems = []
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            
            guard let data = userDoc.data(),
                  let savedNewsIds = data["CommentedNews"] as? [String] else {
                return
            }
            
            for newsId in savedNewsIds.reversed() {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == postalCode {
                    // ✅ Cache user data instead of creating LocalUser
                    _ = await UserCache.shared.getUser(userId: SavedNewsFromFirestore.ownerUid)
                    
                    // ✅ Create LocalNews without LocalUser relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        postalCode: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: nil // ✅ No LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch commented news: \(error)")
        }
    }
}
