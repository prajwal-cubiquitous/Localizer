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
    
    func fetchNews(constituencyId: String) async throws {
        self.newsItems = []
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let snapshot = try await db.collection("news")
            .whereField("ownerUid", isEqualTo: uid)
            .whereField("cosntituencyId", isEqualTo: constituencyId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let newsItemsFromFirebase = snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        }
        
        for item in newsItemsFromFirebase {
            // ✅ Fetch user data and create LocalUser
            let newsUser = try await fetchCurrentUser(item.ownerUid)
            let newsUserLocal = LocalUser.from(user: newsUser)
            
            // ✅ Create LocalNews with proper user relationship
            let localNews = LocalNews(
                id: item.id,
                ownerUid: item.ownerUid,
                caption: item.caption,
                timestamp: item.timestamp.dateValue(),
                likesCount: item.likesCount,
                commentsCount: item.commentsCount,
                constituencyId: item.cosntituencyId,
                newsImageURLs: item.newsImageURLs,
                user: newsUserLocal // ✅ Proper LocalUser relationship
            )
            
            self.newsItems.append(localNews)
        }
    }
    
    @MainActor
    func fetchLikedNews(constituencyId: String) async throws{
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
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    // ✅ Fetch user data and create LocalUser
                    let newsUser = try await fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    let newsUserLocal = LocalUser.from(user: newsUser)
                    
                    // ✅ Create LocalNews with proper user relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        constituencyId: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: newsUserLocal // ✅ Proper LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch liked news: \(error)")
        }
    }
    
    @MainActor
    func fetchSavedNews(constituencyId: String) async throws{
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
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    // ✅ Fetch user data and create LocalUser
                    let newsUser = try await fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    let newsUserLocal = LocalUser.from(user: newsUser)
                    
                    // ✅ Create LocalNews with proper user relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        constituencyId: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: newsUserLocal // ✅ Proper LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch saved news: \(error)")
        }
    }
    
    @MainActor
    func fetchDisLikedNews(constituencyId: String) async throws{
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
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    // ✅ Fetch user data and create LocalUser
                    let newsUser = try await fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    let newsUserLocal = LocalUser.from(user: newsUser)
                    
                    // ✅ Create LocalNews with proper user relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        constituencyId: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: newsUserLocal // ✅ Proper LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch disliked news: \(error)")
        }
    }
    
    @MainActor
    func commentedNews(constituencyId: String) async throws{
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
                  let savedNewsIds = data["commentedNews"] as? [String] else {
                return
            }
            
            for newsId in savedNewsIds.reversed() {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    // ✅ Fetch user data and create LocalUser
                    let newsUser = try await fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    let newsUserLocal = LocalUser.from(user: newsUser)
                    
                    // ✅ Create LocalNews with proper user relationship
                    let localNews = LocalNews(
                        id: SavedNewsFromFirestore.id,
                        ownerUid: SavedNewsFromFirestore.ownerUid,
                        caption: SavedNewsFromFirestore.caption,
                        timestamp: SavedNewsFromFirestore.timestamp.dateValue(),
                        likesCount: SavedNewsFromFirestore.likesCount,
                        commentsCount: SavedNewsFromFirestore.commentsCount,
                        constituencyId: SavedNewsFromFirestore.cosntituencyId,
                        newsImageURLs: SavedNewsFromFirestore.newsImageURLs,
                        user: newsUserLocal // ✅ Proper LocalUser relationship
                    )
                    
                    self.newsItems.append(localNews)
                }
            }
        } catch {
            print("❌ Failed to fetch commented news: \(error)")
        }
    }
    
    // ✅ Helper method to fetch user data from Firestore
    private func fetchCurrentUser(_ uid: String) async throws -> User {
        let docRef = Firestore.firestore().collection("users").document(uid)
        let snapshot = try await docRef.getDocument()
        guard let user = try? snapshot.data(as: User.self) else {
            throw NSError(domain: "ActivityViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode user"])
        }
        return user
    }
}
