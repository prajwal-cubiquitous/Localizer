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
            self.newsItems.append(await LocalNews.from(news: item, user: LocalUser.from(user: user)))
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
                    self.newsItems.append(await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user)))
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }

    }
    
    
    func fetchSavedNews(constituencyId: String) async throws {
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
                  let savedNewsIds = data["savedNews"] as? [String] else {
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    self.newsItems.append(await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user)))
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    
    func commentedNews(constituencyId: String) async throws{
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
                  let savedNewsIds = data["CommentedNews"] as? [String] else {
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    self.newsItems.append(await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user)))
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    func fetchDisLikedNews(constituencyId: String) async throws{
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
                  let savedNewsIds = data["DisLikedNews"] as? [String] else {
                print("No savedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { return }
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    self.newsItems.append(await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user)))
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
                    self.newsItems.append(await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user)))
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
}
