//
//  NewsFeedViewModel.swift
//  Localizer
//
//  Created by Cascade AI on 06/04/25.
//

import Foundation
import SwiftData
@preconcurrency import FirebaseFirestore
import FirebaseFirestore

/// View-model responsible for keeping `LocalNews` in-sync with the latest items
/// from Firestore for the currently selected constituency.
///
/// – Fetches **at most** `maxNewsItems` (100) ordered by newest first.
/// – Replaces any cached items for the same constituency inside SwiftData to keep the
///   local cache small and fresh.
/// – Runs entirely on the MainActor so UI updates are always delivered on the
///   main thread.
@MainActor
final class NewsFeedViewModel: ObservableObject {
    // MARK: ‑ Public state
    @Published private(set) var isLoading = false
    
    // MARK: ‑ Private state
    private let maxNewsItems = 100
    
    // MARK: ‑ API
    /// Public entry point that downloads and caches the latest news for the
    /// supplied `constituencyId`.
    func fetchAndCacheNews(for constituencyId: String, context: ModelContext) async {
        guard !constituencyId.isEmpty else { return }
        isLoading = true
        do {
            let remoteNews = try await fetchNewsFromFirestore(constituencyId: constituencyId)
            await cache(remoteNews, constituencyId: constituencyId, context: context)
        } catch {
            // Prefer logging over crashing – surface this to UI if needed.
        }
        isLoading = false
    }
    
    /// Convenience wrapper used by pull-to-refresh.
    func refresh(for constituencyId: String, context: ModelContext) async {
        MediaHandler.clearTemporaryMedia()
        await fetchAndCacheNews(for: constituencyId, context: context)
    }
    
    // MARK: ‑ Firestore
    private func fetchNewsFromFirestore(constituencyId: String) async throws -> [News] {
        let db = Firestore.firestore()
        let query = db.collection("news")
            .whereField("cosntituencyId", isEqualTo: constituencyId)
            .order(by: "timestamp", descending: true)
            .limit(to: maxNewsItems)
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        } 
    }
    
    // MARK: ‑ SwiftData caching
    private func cache(_ items: [News], constituencyId: String, context: ModelContext) async {
        do {
            // 1. Delete any existing cached items for this constituencyId.
            let fetchDescriptor = FetchDescriptor<LocalNews>(
                predicate: #Predicate { $0.constituencyId == constituencyId }
            )
            let existing = try context.fetch(fetchDescriptor)
            for obj in existing {
                context.delete(obj)
            }
            // 3. Insert the newly fetched items (capped at 100) **with their authors**.
            for news in items.prefix(maxNewsItems) {
                let NewsUser : User = try await fetchCurrentUser(news.ownerUid)
                
                let NewsUserLocal : LocalUser? = LocalUser.from(user: NewsUser)
                
                
                
                // Create and insert LocalNews linked to its LocalUser (if available)
                let localNews = await LocalNews.from(news: news, user: NewsUserLocal)
                context.insert(localNews)
                
                // If we have a local author, add this news item to their newsItems relationship
                if let author = NewsUserLocal {
                    author.newsItems.append(localNews)
                }
            }
            
        } catch {
        }
    }
    
    private func fetchCurrentUser(_ uid: String) async throws -> User {
        let docRef = Firestore.firestore().collection("users").document(uid)
        let snapshot = try await docRef.getDocument()
        guard let user = try? snapshot.data(as: User.self) else {
            throw NSError(domain: "PostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode current user"])
        }
        return user
    }
}
