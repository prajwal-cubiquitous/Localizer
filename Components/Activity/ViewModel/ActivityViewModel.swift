//
//  ActivityViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//

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
    @Published var UserItems: [User] = []
    
    // Helper method to add news item only if it doesn't already exist
    private func addUniqueNewsItem(_ localNews: LocalNews) {
        if !newsItems.contains(where: { $0.id == localNews.id }) {
            newsItems.append(localNews)
        }
    }
    
    func fetchNews(constituencyId: String) async throws {
        self.newsItems = []
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(uid)
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
            let localNews = await LocalNews.from(news: item, user: LocalUser.from(user: user))
            addUniqueNewsItem(localNews)
        }
    }
    
    func fetchLikedNews(constituencyId: String) async throws{
        newsItems = []
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
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
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }

    }
    
    
    func fetchSavedNews(constituencyId: String) async throws {
        newsItems = []
        print(1)
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
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
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    
    func commentedNews(constituencyId: String) async throws{
        newsItems = []
        print(1)
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
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
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    func fetchDisLikedNews(constituencyId: String) async throws{
        newsItems = []
        print(1)
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
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
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    
    func fetchDontRecommendNews(constituencyId: String) async throws{
        newsItems = []
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(userId)
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            
            guard let data = userDoc.data(),
                  let savedNewsIds = data["DontRecommendNews"] as? [String] else {
                print("No DontRecommendNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    
    func fetchDontRecommendUsers() async throws{
        UserItems = []
        print(1)
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        print(2)
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            print(3)
            guard let data = userDoc.data(),
                  let savedUserIds = data["DontRecommendUser"] as? [String] else {
                print("No DontRecommendUser array found")
                return
            }
            print(4)
            for singleuserId in savedUserIds {
                print(singleuserId)
                let snapshot = try await db.collection("users").document(singleuserId).getDocument()
                guard snapshot.exists else { return }
                let SavedUserFromFirestore = try snapshot.data(as: User.self)
                print("User is appending to the user items \(SavedUserFromFirestore.name)")
                self.UserItems.append(SavedUserFromFirestore)
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
}
