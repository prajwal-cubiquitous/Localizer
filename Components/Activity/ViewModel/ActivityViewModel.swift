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
        UserItems = [] // Clear user items
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
        UserItems = [] // Clear user items
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
                print("No LikedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching liked news: \(error.localizedDescription)")
        }
    }
    
    
    func fetchSavedNews(constituencyId: String) async throws {
        newsItems = []
        UserItems = [] // Clear user items
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
                guard snapshot.exists else { continue } // Use continue instead of return
                do {
                    var SavedNewsFromFirestore = try snapshot.data(as: News.self)
                    // Ensure the newsId is set to the document ID if it's not already set
                    if SavedNewsFromFirestore.newsId == nil {
                        SavedNewsFromFirestore = News(
                            newsId: snapshot.documentID,
                            ownerUid: SavedNewsFromFirestore.ownerUid,
                            caption: SavedNewsFromFirestore.caption,
                            timestamp: SavedNewsFromFirestore.timestamp,
                            likesCount: SavedNewsFromFirestore.likesCount,
                            commentsCount: SavedNewsFromFirestore.commentsCount,
                            cosntituencyId: SavedNewsFromFirestore.cosntituencyId,
                            user: SavedNewsFromFirestore.user,
                            newsImageURLs: SavedNewsFromFirestore.newsImageURLs
                        )
                    }
                    if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                        let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                        addUniqueNewsItem(localNews)
                    }
                } catch {
                    print("❌ Error decoding saved news document \(newsId): \(error)")
                }
            }
        } catch {
            print("Error fetching saved news: \(error.localizedDescription)")
        }
    }
    
    func commentedNews(constituencyId: String) async throws{
        newsItems = []
        UserItems = [] // Clear user items
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
                print("No CommentedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching commented news: \(error.localizedDescription)")
        }
    }
    func fetchDisLikedNews(constituencyId: String) async throws{
        newsItems = []
        UserItems = [] // Clear user items
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
                print("No DisLikedNews array found")
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching disliked news: \(error.localizedDescription)")
        }
    }
    
    func fetchDontRecommendNews(constituencyId: String) async throws{
        newsItems = []
        UserItems = [] // Clear user items
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
                guard snapshot.exists else { continue } // Use continue instead of return
                let SavedNewsFromFirestore = try snapshot.data(as: News.self)
                if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                    let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                    addUniqueNewsItem(localNews)
                }
            }
        } catch {
            print("Error fetching DontRecommendNews: \(error.localizedDescription)")
        }
    }
    
    func fetchDontRecommendUsers() async throws{
        UserItems = []
        newsItems = [] // Clear news items
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userActivityDocRef = db
            .collection("users")
            .document(userId)
            .collection("userNewsActivity")
            .document(userId)
        
        do {
            let userDoc = try await userActivityDocRef.getDocument()
            
            if let data = userDoc.data() {
                if let savedUserIds = data["DontRecommendUser"] as? [String] {
                    for singleuserId in savedUserIds {
                        let snapshot = try await db.collection("users").document(singleuserId).getDocument()
                        
                        if snapshot.exists {
                            let SavedUserFromFirestore = try snapshot.data(as: User.self)
                            self.UserItems.append(SavedUserFromFirestore)
                        }
                    }
                } else {
                    print("No DontRecommendUser array found")
                }
            }
        } catch {
            print("Error fetching DontRecommendUsers: \(error.localizedDescription)")
        }
    }
}
