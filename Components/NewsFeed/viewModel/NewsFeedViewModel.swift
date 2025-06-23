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
import FirebaseAuth

/// View-model responsible for keeping `LocalNews` in-sync with the latest items
/// from Firestore for the currently selected constituency with pagination support.
@MainActor
final class NewsFeedViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published private(set) var error: String?
    
    // MARK: - Private State
    private let pageSize = 20 // Load 20 items per page
    private var lastDocument: DocumentSnapshot?
    private var currentConstituencyId = ""
    private let maxLocalItems = 50 // Store 50 items locally as per requirements
    private let maxCachedMedia = 30 // Cache media for only 2 items
    
    // MARK: - Public API
    
    /// Legacy method for backward compatibility
    func fetchAndCacheNews(for constituencyId: String, context: ModelContext) async {
        await loadInitial(for: constituencyId, context: context)
    }
    
    /// Initial load of news for a constituency - replaces existing data
    func loadInitial(for constituencyId: String, context: ModelContext) async {
        guard !constituencyId.isEmpty else { return }
        
        isLoading = true
        error = nil
        currentConstituencyId = constituencyId
        lastDocument = nil
        hasMorePages = true
        
        do {
            let (remoteNews, lastDoc) = try await fetchNewsFromFirestore(
                constituencyId: constituencyId, 
                startAfter: nil
            )
            
            lastDocument = lastDoc
            hasMorePages = remoteNews.count == pageSize
            
            await replaceLocalNews(remoteNews, constituencyId: constituencyId, context: context)
            
        } catch {
            self.error = "Failed to load news: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load more news items for infinite scroll
    func loadMore(context: ModelContext) async {
        guard !isLoadingMore && hasMorePages && !currentConstituencyId.isEmpty else { return }
        
        isLoadingMore = true
        error = nil
        
        do {
            let (remoteNews, lastDoc) = try await fetchNewsFromFirestore(
                constituencyId: currentConstituencyId,
                startAfter: lastDocument
            )
            
            lastDocument = lastDoc
            hasMorePages = remoteNews.count == pageSize
            
            await appendToLocalNews(remoteNews, context: context)
            
        } catch {
            self.error = "Failed to load more news: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
    
    /// Convenience wrapper for pull-to-refresh
    func refresh(for constituencyId: String, context: ModelContext) async {
        await loadInitial(for: constituencyId, context: context)
    }
    
    // MARK: - Firestore Operations
    
    private func fetchNewsFromFirestore(
        constituencyId: String, 
        startAfter: DocumentSnapshot?
    ) async throws -> ([News], DocumentSnapshot?) {
        let db = Firestore.firestore()
        var query = db.collection("news")
            .whereField("cosntituencyId", isEqualTo: constituencyId)
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        // Add pagination cursor if provided
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        let snapshot = try await query.getDocuments()
        let news = snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        }
        
        let lastDoc = snapshot.documents.last
        return (news, lastDoc)
    }
    
    // MARK: - SwiftData Operations
    
    /// Replace all local news items (used for initial load)
    private func replaceLocalNews(_ items: [News], constituencyId: String, context: ModelContext) async {
        // 1. Clear existing items for this constituency
        await clearLocalNews(for: constituencyId, context: context)
        
        // 2. Insert new items (limited to maxLocalItems)
        let itemsToStore = Array(items.prefix(maxLocalItems))
        await insertLocalNews(itemsToStore, context: context)
    }
    
    /// Append new items to local news (used for load more)
    private func appendToLocalNews(_ items: [News], context: ModelContext) async {
        // 1. Insert new items
        await insertLocalNews(items, context: context)
        
        // 2. Get all items after insertion and maintain max limit
        await MainActor.run {
            do {
                let constituencyId = self.currentConstituencyId
                let fetchDescriptor = FetchDescriptor<LocalNews>(
                    predicate: #Predicate<LocalNews> { $0.constituencyId == constituencyId },
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                let allItems = try context.fetch(fetchDescriptor)
                if allItems.count > maxLocalItems {
                    let itemsToRemove = Array(allItems.suffix(allItems.count - maxLocalItems))
                    for item in itemsToRemove {
                        context.delete(item)
                    }
                    try context.save()
                }
            } catch {
                print("❌ Error managing local items limit: \(error)")
            }
        }
    }
    
    /// Clear all local news for a specific constituency
    private func clearLocalNews(for constituencyId: String, context: ModelContext) async {
        do {
            let fetchDescriptor = FetchDescriptor<LocalNews>(
                predicate: #Predicate { $0.constituencyId == constituencyId }
            )
            let existing = try context.fetch(fetchDescriptor)
            for item in existing {
                context.delete(item)
            }
        } catch {
            // Silent error handling for cleanup operations
        }
    }
    
    /// Insert news items into local storage
    private func insertLocalNews(_ items: [News], context: ModelContext) async {
        let currentUserId = getCurrentUserId()
        
        // Process all items on main thread to avoid race conditions
        await MainActor.run {
            do {
                // Get all existing news IDs for this constituency to check for duplicates
                let constituencyId = self.currentConstituencyId
                let existingDescriptor = FetchDescriptor<LocalNews>(
                    predicate: #Predicate<LocalNews> { $0.constituencyId == constituencyId }
                )
                let existingNews = try context.fetch(existingDescriptor)
                let existingIds = Set(existingNews.map { $0.id })
                
                // Process items sequentially to avoid conflicts
                for news in items {
                    // Skip if already exists
                    if existingIds.contains(news.id) {
                        print("⚠️ Skipping duplicate news item: \(news.id)")
                        continue
                    }
                    
                    // Process the news item synchronously
                    processNewsItemSync(news, currentUserId: currentUserId, context: context)
                }
                
                // Save context
                try context.save()
            } catch {
                print("❌ Error inserting local news: \(error)")
            }
        }
    }
    
    /// Process a single news item synchronously on main thread
    private func processNewsItemSync(_ news: News, currentUserId: String, context: ModelContext) {
        // Only create LocalUser relationship when news.ownerUid == currentUserId
        if news.ownerUid == currentUserId {
            processCurrentUserNewsSync(news, currentUserId: currentUserId, context: context)
        } else {
            processOtherUserNewsSync(news, context: context)
        }
    }
    
    /// Process news from current user synchronously
    private func processCurrentUserNewsSync(_ news: News, currentUserId: String, context: ModelContext) {
        // Check if LocalUser already exists
        let userDescriptor = FetchDescriptor<LocalUser>(
            predicate: #Predicate<LocalUser> { $0.id == currentUserId }
        )
        
        let userToUse: LocalUser?
        if let existingUser = (try? context.fetch(userDescriptor))?.first {
            userToUse = existingUser
        } else {
            // We'll create the user asynchronously later to avoid blocking
            userToUse = nil
        }
        
        // Create LocalNews without user relationship for now
        let localNews = LocalNews(
            id: news.id,
            ownerUid: news.ownerUid,
            caption: news.caption,
            timestamp: news.timestamp.dateValue(),
            likesCount: news.likesCount,
            commentsCount: news.commentsCount,
            constituencyId: news.cosntituencyId,
            newsImageURLs: news.newsImageURLs,
            user: userToUse
        )
        
        context.insert(localNews)
        
        // Cache user for UI display asynchronously
        Task {
            do {
                let user = try await FetchCurrencyUser.fetchCurrentUser(news.ownerUid)
                await cacheUser(user)
            } catch {
                print("❌ Error caching user data for news: \(news.id)")
            }
        }
    }
    
    /// Process news from other users synchronously
    private func processOtherUserNewsSync(_ news: News, context: ModelContext) {
        // Create LocalNews without LocalUser relationship
        let localNews = LocalNews(
            id: news.id,
            ownerUid: news.ownerUid,
            caption: news.caption,
            timestamp: news.timestamp.dateValue(),
            likesCount: news.likesCount,
            commentsCount: news.commentsCount,
            constituencyId: news.cosntituencyId,
            newsImageURLs: news.newsImageURLs,
            user: nil
        )
        
        context.insert(localNews)
        
        // Cache user for UI display asynchronously
        Task {
            do {
                let user = try await FetchCurrencyUser.fetchCurrentUser(news.ownerUid)
                await cacheUser(user)
            } catch {
                print("❌ Error caching user data for news: \(news.id)")
            }
        }
    }
    
    /// Get the current user's ID
    private func getCurrentUserId() -> String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    /// Cache user data for UI display
    private func cacheUser(_ user: User) async {
        let cachedUser = CachedUser(username: user.username, profilePictureUrl: user.profileImageUrl)
        // Cache the user for UI display
        UserCache.shared.cacheUser(userId: user.id, cachedUser: cachedUser)
    }
} 

