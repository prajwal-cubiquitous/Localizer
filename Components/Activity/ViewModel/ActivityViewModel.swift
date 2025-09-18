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
            do {
                var newsItem = try doc.data(as: News.self)
                // Set the regular documentId field if it's not already set
                if newsItem.documentId == nil && newsItem.newsId == nil {
                    newsItem = News(
                        newsId: nil, // Don't set @DocumentID manually
                        documentId: doc.documentID, // Use regular field
                        ownerUid: newsItem.ownerUid,
                        caption: newsItem.caption,
                        timestamp: newsItem.timestamp,
                        likesCount: newsItem.likesCount,
                        commentsCount: newsItem.commentsCount,
                        cosntituencyId: newsItem.cosntituencyId,
                        category: newsItem.category,
                        user: newsItem.user,
                        newsImageURLs: newsItem.newsImageURLs
                    )
                }
                return newsItem
            } catch {
                // Silently handle decoding errors
                return nil
            }
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
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                do {
                    var SavedNewsFromFirestore = try snapshot.data(as: News.self)
                    // Set the regular documentId field if it's not already set
                    if SavedNewsFromFirestore.documentId == nil && SavedNewsFromFirestore.newsId == nil {
                        SavedNewsFromFirestore = News(
                            newsId: nil, // Don't set @DocumentID manually
                            documentId: snapshot.documentID, // Use regular field
                            ownerUid: SavedNewsFromFirestore.ownerUid,
                            caption: SavedNewsFromFirestore.caption,
                            timestamp: SavedNewsFromFirestore.timestamp,
                            likesCount: SavedNewsFromFirestore.likesCount,
                            commentsCount: SavedNewsFromFirestore.commentsCount,
                            cosntituencyId: SavedNewsFromFirestore.cosntituencyId,
                            category: SavedNewsFromFirestore.category,
                            user: SavedNewsFromFirestore.user,
                            newsImageURLs: SavedNewsFromFirestore.newsImageURLs
                        )
                    }
                    if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                        let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                        addUniqueNewsItem(localNews)
                    }
                } catch {
                    // Silently handle decoding errors
                }
            }
        } catch {
            // Silently handle fetch errors
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
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                do {
                    var SavedNewsFromFirestore = try snapshot.data(as: News.self)
                    // Set the regular documentId field if it's not already set
                    if SavedNewsFromFirestore.documentId == nil && SavedNewsFromFirestore.newsId == nil {
                        SavedNewsFromFirestore = News(
                            newsId: nil, // Don't set @DocumentID manually
                            documentId: snapshot.documentID, // Use regular field
                            ownerUid: SavedNewsFromFirestore.ownerUid,
                            caption: SavedNewsFromFirestore.caption,
                            timestamp: SavedNewsFromFirestore.timestamp,
                            likesCount: SavedNewsFromFirestore.likesCount,
                            commentsCount: SavedNewsFromFirestore.commentsCount,
                            cosntituencyId: SavedNewsFromFirestore.cosntituencyId,
                            category: SavedNewsFromFirestore.category,
                            user: SavedNewsFromFirestore.user,
                            newsImageURLs: SavedNewsFromFirestore.newsImageURLs
                        )
                    }
                    if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                        let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                        addUniqueNewsItem(localNews)
                    }
                } catch {
                    // Silently handle decoding errors
                }
            }
        } catch {
            // Silently handle fetch errors
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
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                do {
                    var SavedNewsFromFirestore = try snapshot.data(as: News.self)
                    // Set the regular documentId field if it's not already set
                    if SavedNewsFromFirestore.documentId == nil && SavedNewsFromFirestore.newsId == nil {
                        SavedNewsFromFirestore = News(
                            newsId: nil, // Don't set @DocumentID manually
                            documentId: snapshot.documentID, // Use regular field
                            ownerUid: SavedNewsFromFirestore.ownerUid,
                            caption: SavedNewsFromFirestore.caption,
                            timestamp: SavedNewsFromFirestore.timestamp,
                            likesCount: SavedNewsFromFirestore.likesCount,
                            commentsCount: SavedNewsFromFirestore.commentsCount,
                            cosntituencyId: SavedNewsFromFirestore.cosntituencyId,
                            category: SavedNewsFromFirestore.category,
                            user: SavedNewsFromFirestore.user,
                            newsImageURLs: SavedNewsFromFirestore.newsImageURLs
                        )
                    }
                    if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                        let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                        addUniqueNewsItem(localNews)
                    }
                } catch {
                    // Silently handle decoding errors
                }
            }
        } catch {
            // Silently handle fetch errors
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
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                do {
                    var SavedNewsFromFirestore = try snapshot.data(as: News.self)
                    // Set the regular documentId field if it's not already set
                    if SavedNewsFromFirestore.documentId == nil && SavedNewsFromFirestore.newsId == nil {
                        SavedNewsFromFirestore = News(
                            newsId: nil, // Don't set @DocumentID manually
                            documentId: snapshot.documentID, // Use regular field
                            ownerUid: SavedNewsFromFirestore.ownerUid,
                            caption: SavedNewsFromFirestore.caption,
                            timestamp: SavedNewsFromFirestore.timestamp,
                            likesCount: SavedNewsFromFirestore.likesCount,
                            commentsCount: SavedNewsFromFirestore.commentsCount,
                            cosntituencyId: SavedNewsFromFirestore.cosntituencyId,
                            category: SavedNewsFromFirestore.category,
                            user: SavedNewsFromFirestore.user,
                            newsImageURLs: SavedNewsFromFirestore.newsImageURLs
                        )
                    }
                    if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                        let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                        addUniqueNewsItem(localNews)
                    }
                } catch {
                    // Silently handle decoding errors
                }
            }
        } catch {
            // Silently handle fetch errors
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
                return
            }
            
            for newsId in savedNewsIds {
                let snapshot = try await db.collection("news").document(newsId).getDocument()
                guard snapshot.exists else { continue } // Use continue instead of return
                do {
                    var SavedNewsFromFirestore = try snapshot.data(as: News.self)
                    // Set the regular documentId field if it's not already set
                    if SavedNewsFromFirestore.documentId == nil && SavedNewsFromFirestore.newsId == nil {
                        SavedNewsFromFirestore = News(
                            newsId: nil, // Don't set @DocumentID manually
                            documentId: snapshot.documentID, // Use regular field
                            ownerUid: SavedNewsFromFirestore.ownerUid,
                            caption: SavedNewsFromFirestore.caption,
                            timestamp: SavedNewsFromFirestore.timestamp,
                            likesCount: SavedNewsFromFirestore.likesCount,
                            commentsCount: SavedNewsFromFirestore.commentsCount,
                            cosntituencyId: SavedNewsFromFirestore.cosntituencyId,
                            category: SavedNewsFromFirestore.category,
                            user: SavedNewsFromFirestore.user,
                            newsImageURLs: SavedNewsFromFirestore.newsImageURLs
                        )
                    }
                    if SavedNewsFromFirestore.cosntituencyId == constituencyId {
                        let localNews = await LocalNews.from(news: SavedNewsFromFirestore, user: LocalUser.from(user: user))
                        addUniqueNewsItem(localNews)
                    }
                } catch {
                    // Silently handle decoding errors
                }
            }
        } catch {
            // Silently handle fetch errors
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
            // Silently handle fetch errors
        }
    }
}
