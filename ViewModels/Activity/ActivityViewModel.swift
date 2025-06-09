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
    
    func fetchNews(postalCode: String) async throws{
        newsItems = []
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let user = try await FetchCurrencyUser.fetchCurrentUser(uid)
        let db = Firestore.firestore()
        
        db.collection("news")
            .whereField("ownerUid", isEqualTo: uid)
            .whereField("postalCode", isEqualTo: postalCode)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching news: \(error.localizedDescription)")
                    return
                }
                let NewsItemsFromFirebase = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: News.self)
                } ?? []
                
                for item in NewsItemsFromFirebase {
                    self.newsItems.append(LocalNews.from(news: item, user: LocalUser.from(user: user)))
                }
            }
    }
    
    func fetchLikedNews() async throws{
        newsItems = [DummyLocalNews.News2]
    }
    
    func fetchSavedNews() async throws{
        newsItems = [DummyLocalNews.News3]
    }
    func commentedNews() async throws{
        newsItems = [DummyLocalNews.News1]
    }
}
