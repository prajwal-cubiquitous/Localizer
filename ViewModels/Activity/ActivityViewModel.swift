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
            let newsUser = try await FetchCurrencyUser.fetchCurrentUser(item.ownerUid)
            await self.newsItems.append(LocalNews.from(news: item, user: LocalUser.from(user: newsUser)))
        }
    }
    
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
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.postalCode == postalCode {
                    let newsUser = try await FetchCurrencyUser.fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    await self.newsItems.append(LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: newsUser)))
                }
            }
        } catch {
        }

    }
    
    
    func fetchSavedNews(postalCode: String) async throws {
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
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.postalCode == postalCode {
                    let newsUser = try await FetchCurrencyUser.fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    await self.newsItems.append(LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: newsUser)))
                }
            }
        } catch {
        }
    }
    
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
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.postalCode == postalCode {
                    let newsUser = try await FetchCurrencyUser.fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    await self.newsItems.append(LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: newsUser)))
                }
            }
        } catch {
        }
    }
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
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.postalCode == postalCode {
                    let newsUser = try await FetchCurrencyUser.fetchCurrentUser(SavedNewsFromFirestore.ownerUid)
                    await self.newsItems.append(LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: newsUser)))
                }
            }
        } catch {
        }
    }
}
