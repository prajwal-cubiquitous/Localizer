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
/// from Firestore for the currently selected pincode.
///
/// – Fetches **at most** `maxNewsItems` (100) ordered by newest first.
/// – Replaces any cached items for the same pincode inside SwiftData to keep the
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
    /// supplied `pincode`.
    func fetchAndCacheNews(for pincode: String, context: ModelContext) async {
        guard !pincode.isEmpty else { return }
        isLoading = true
        do {
            let remoteNews = try await fetchNewsFromFirestore(pincode: pincode)
            await cache(remoteNews, pincode: pincode, context: context)
        } catch {
            // Prefer logging over crashing – surface this to UI if needed.
            print("[NewsFeedVM] Failed to fetch news: \(error)")
        }
        isLoading = false
    }
    
    /// Convenience wrapper used by pull-to-refresh.
    func refresh(for pincode: String, context: ModelContext) async {
        await fetchAndCacheNews(for: pincode, context: context)
    }
    
    // MARK: ‑ Firestore
    private func fetchNewsFromFirestore(pincode: String) async throws -> [News] {
        let db = Firestore.firestore()
        let query = db.collection("news")
            .whereField("postalCode", isEqualTo: pincode)
            .order(by: "timestamp", descending: true)
            .limit(to: maxNewsItems)
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        }
    }
    
    // MARK: ‑ SwiftData caching
    private func cache(_ items: [News], pincode: String, context: ModelContext) async {
        do {
            // 1. Delete any existing cached items for this pincode.
            let fetchDescriptor = FetchDescriptor<LocalNews>(
                predicate: #Predicate { $0.postalCode == pincode }
            )
            let existing = try context.fetch(fetchDescriptor)
            for obj in existing {
                context.delete(obj)
            }
            
            // 2️⃣ Build an in-memory cache for LocalUser so we only fetch/insert once per user id.
            var userCache: [String: LocalUser] = [:]
            
            // 3. Insert the newly fetched items (capped at 100) **with their authors**.
            for news in items.prefix(maxNewsItems) {
                var localAuthor: LocalUser? = nil
                if let remoteAuthor = news.user {
                    if let cached = userCache[remoteAuthor.id] {
                        localAuthor = cached
                    } else {
                        let authorId = remoteAuthor.id
                        let userFetch = FetchDescriptor<LocalUser>(
                            predicate: #Predicate { $0.id == authorId },
//                            fetchLimit: 1
                        )
                        if let existingAuthor = try context.fetch(userFetch).first {
                            // Update basic mutable fields (fast, non-blocking)
                            existingAuthor.name = remoteAuthor.name
                            existingAuthor.username = remoteAuthor.username
                            existingAuthor.email = remoteAuthor.email
                            existingAuthor.profileImageUrl = remoteAuthor.profileImageUrl
                            existingAuthor.bio = remoteAuthor.bio
                            existingAuthor.postCount = remoteAuthor.postsCount
                            existingAuthor.likedCount = remoteAuthor.likedCount
                            existingAuthor.commentCount = remoteAuthor.commentsCount
                            localAuthor = existingAuthor
                        } else {
                            let newLocalAuthor = LocalUser.from(user: remoteAuthor)
                            context.insert(newLocalAuthor)
                            localAuthor = newLocalAuthor
                        }
                        userCache[authorId] = localAuthor
                    }
                }
                
                // Create and insert LocalNews linked to its LocalUser (if available)
                let localNews = LocalNews.from(news: news, user: localAuthor)
                context.insert(localNews)
            }
            
        } catch {
            print("[NewsFeedVM] Caching error: \(error)")
        }
    }
}
