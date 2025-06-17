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
        }
        isLoading = false
    }
    
    /// Convenience wrapper used by pull-to-refresh.
    func refresh(for pincode: String, context: ModelContext) async {
        MediaHandler.clearTemporaryMedia()
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
            
            // ✅ 2. Batch fetch all unique user IDs for caching
            let uniqueUserIds = Array(Set(items.map { $0.ownerUid }))
            let cachedUsers = await UserCache.shared.getUsers(userIds: uniqueUserIds)
            
            // ✅ 3. Insert the newly fetched items WITHOUT creating LocalUser objects
            for news in items.prefix(maxNewsItems) {
                // Create LocalNews without LocalUser relationship
                let localNews = LocalNews(
                    id: news.id,
                    ownerUid: news.ownerUid,
                    caption: news.caption,
                    timestamp: news.timestamp.dateValue(),
                    likesCount: news.likesCount,
                    commentsCount: news.commentsCount,
                    postalCode: news.postalCode,
                    newsImageURLs: news.newsImageURLs,
                    user: nil // ✅ No LocalUser relationship for news feed users
                )
                
                context.insert(localNews)
                
                // ✅ Ensure user is cached in UserCache for UI display
                if cachedUsers[news.ownerUid] == nil {
                    // If user wasn't cached in batch, cache individually
                    _ = await UserCache.shared.getUser(userId: news.ownerUid)
                }
            }
            
            try context.save()
            print("✅ Cached \(items.count) news items for pincode: \(pincode)")
            
        } catch {
            print("❌ Failed to cache news items: \(error)")
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
