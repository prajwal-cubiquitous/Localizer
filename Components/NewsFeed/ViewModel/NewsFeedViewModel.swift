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

/// Instagram-style paginated news feed view-model with smart caching and performance optimization.
/// 
/// Features:
/// - ✅ Pagination with cursor-based loading (like Instagram)
/// - ✅ Smart caching with limited local storage (50 items max)
/// - ✅ Load-on-demand when scrolling near bottom
/// - ✅ Only fetch on app start and pull-to-refresh
/// - ✅ Optimized Firebase usage with proper query limits
@MainActor
final class NewsFeedViewModel: ObservableObject {
    // MARK: ‑ Public state
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreContent = true
    @Published private(set) var lastFetchTime: Date?
    
    // MARK: ‑ Private state
    private let pageSize = 10 // Instagram-like page size
    private let maxCachedItems = 50 // Limit local storage for performance
    private let cacheExpiryMinutes = 30 // Cache validity duration
    private var lastDocument: DocumentSnapshot?
    private var currentPincode: String = ""
    private var hasInitialLoad = false
    
    // MARK: ‑ API
    /// Initial load - only called on app start or when pincode changes
    func initialLoad(for pincode: String, context: ModelContext) async {
        guard !pincode.isEmpty else { return }
        
        // ✅ Check AppState to avoid unnecessary loading
        let appState = AppState.shared
        let shouldLoad = !appState.isNewsFeedInitialized(for: pincode) || 
                        appState.shouldRefreshNewsFeed(for: pincode, cacheExpiryMinutes: cacheExpiryMinutes)
        
        if shouldLoad {
            currentPincode = pincode
            lastDocument = nil
            hasMoreContent = true
            hasInitialLoad = false
            
            await loadFirstPage(for: pincode, context: context)
            
            // ✅ Mark as initialized in AppState
            appState.markNewsFeedInitialized(for: pincode)
        }
        
        hasInitialLoad = true
    }
    
    /// Pull-to-refresh - clears cache and loads fresh data
    func refresh(for pincode: String, context: ModelContext) async {
        MediaHandler.clearTemporaryMedia()
        NewsCellViewModel.clearCache()
        
        // Reset pagination state
        currentPincode = pincode
        lastDocument = nil
        hasMoreContent = true
        hasInitialLoad = false
        
        await loadFirstPage(for: pincode, context: context)
        
        // ✅ Update AppState refresh time
        AppState.shared.markNewsFeedInitialized(for: pincode)
    }
    
    /// Load more content when scrolling near bottom (Instagram-style)
    func loadMoreIfNeeded(for pincode: String, context: ModelContext, currentItem: LocalNews, allItems: [LocalNews]) async {
        // Only load more if we're near the end and have more content
        guard hasMoreContent,
              !isLoadingMore,
              hasInitialLoad,
              pincode == currentPincode else { return }
        
        // Check if current item is near the end (last 3 items)
        if let currentIndex = allItems.firstIndex(where: { $0.id == currentItem.id }),
           currentIndex >= allItems.count - 3 {
            await loadNextPage(for: pincode, context: context)
        }
    }
    
    // MARK: ‑ Private Methods
    private func shouldLoadFreshData(for pincode: String) -> Bool {
        // Load fresh data if:
        // 1. Different pincode
        // 2. No previous fetch
        // 3. Cache expired
        // 4. No initial load yet
        
        guard pincode == currentPincode,
              let lastFetch = lastFetchTime else {
            return true
        }
        
        let cacheExpired = Date().timeIntervalSince(lastFetch) > TimeInterval(cacheExpiryMinutes * 60)
        return cacheExpired || !hasInitialLoad
    }
    
    private func loadFirstPage(for pincode: String, context: ModelContext) async {
        isLoading = true
        
        do {
            let (result, duration) = try await measureTime {
                try await fetchFirstPageFromFirestore(pincode: pincode)
            }
            
            let (remoteNews, lastDoc) = result
            lastDocument = lastDoc
            hasMoreContent = remoteNews.count == pageSize
            
            // Clear old cache and insert new data
            await replaceCache(with: remoteNews, pincode: pincode, context: context)
            lastFetchTime = Date()
            
            logPerformanceMetrics(operation: "First Page Load", itemCount: remoteNews.count, duration: duration)
            
        } catch {
            print("❌ Failed to load first page: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadNextPage(for pincode: String, context: ModelContext) async {
        guard let lastDoc = lastDocument else { return }
        
        isLoadingMore = true
        
        do {
            let (result, duration) = try await measureTime {
                try await fetchNextPageFromFirestore(pincode: pincode, startAfter: lastDoc)
            }
            
            let (remoteNews, lastDocument) = result
            self.lastDocument = lastDocument
            hasMoreContent = remoteNews.count == pageSize
            
            // Append to existing cache with size limit
            await appendToCache(remoteNews, pincode: pincode, context: context)
            
            logPerformanceMetrics(operation: "Next Page Load", itemCount: remoteNews.count, duration: duration)
            
        } catch {
            print("❌ Failed to load next page: \(error)")
        }
        
        isLoadingMore = false
    }
    
    // MARK: ‑ Firestore Queries
    private func fetchFirstPageFromFirestore(pincode: String) async throws -> ([News], DocumentSnapshot?) {
        let db = Firestore.firestore()
        let query = db.collection("news")
            .whereField("postalCode", isEqualTo: pincode)
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        let snapshot = try await query.getDocuments()
        let news = snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        }
        
        return (news, snapshot.documents.last)
    }
    
    private func fetchNextPageFromFirestore(pincode: String, startAfter: DocumentSnapshot) async throws -> ([News], DocumentSnapshot?) {
        let db = Firestore.firestore()
        let query = db.collection("news")
            .whereField("postalCode", isEqualTo: pincode)
            .order(by: "timestamp", descending: true)
            .start(afterDocument: startAfter)
            .limit(to: pageSize)
        
        let snapshot = try await query.getDocuments()
        let news = snapshot.documents.compactMap { doc in
            try? doc.data(as: News.self)
        }
        
        return (news, snapshot.documents.last)
    }
    
    // MARK: ‑ SwiftData Caching with Size Limits
    private func replaceCache(with items: [News], pincode: String, context: ModelContext) async {
        do {
            // 1. Delete existing cached items for this pincode
            let fetchDescriptor = FetchDescriptor<LocalNews>(
                predicate: #Predicate { $0.postalCode == pincode }
            )
            let existing = try context.fetch(fetchDescriptor)
            for obj in existing {
                context.delete(obj)
            }
            
            // 2. Cache users efficiently
            await cacheUsersForNews(items)
            
            // 3. Insert new items
            for news in items {
                let localNews = createLocalNews(from: news)
                context.insert(localNews)
            }
            
            try context.save()
            print("✅ Cached \(items.count) news items for pincode: \(pincode)")
            
        } catch {
            print("❌ Failed to replace cache: \(error)")
        }
    }
    
    private func appendToCache(_ items: [News], pincode: String, context: ModelContext) async {
        do {
            // 1. Cache users for new items
            await cacheUsersForNews(items)
            
            // 2. Insert new items
            for news in items {
                let localNews = createLocalNews(from: news)
                context.insert(localNews)
            }
            
            // 3. Enforce cache size limit
            await enforceCacheSizeLimit(for: pincode, context: context)
            
            try context.save()
            print("✅ Appended \(items.count) news items for pincode: \(pincode)")
            
        } catch {
            print("❌ Failed to append to cache: \(error)")
        }
    }
    
    private func enforceCacheSizeLimit(for pincode: String, context: ModelContext) async {
        do {
            let fetchDescriptor = FetchDescriptor<LocalNews>(
                predicate: #Predicate { $0.postalCode == pincode },
                sortBy: [SortDescriptor(\LocalNews.timestamp, order: .reverse)]
            )
            
            let allItems = try context.fetch(fetchDescriptor)
            
            // Remove oldest items if we exceed the limit
            if allItems.count > maxCachedItems {
                let itemsToRemove = allItems.suffix(allItems.count - maxCachedItems)
                for item in itemsToRemove {
                    context.delete(item)
                }
                print("🗑️ Removed \(itemsToRemove.count) old items to maintain cache size limit")
            }
            
        } catch {
            print("❌ Failed to enforce cache size limit: \(error)")
        }
    }
    
    private func cacheUsersForNews(_ newsItems: [News]) async {
        let uniqueUserIds = Array(Set(newsItems.map { $0.ownerUid }))
        _ = await UserCache.shared.getUsers(userIds: uniqueUserIds)
    }
    
    private func createLocalNews(from news: News) -> LocalNews {
        return LocalNews(
            id: news.id,
            ownerUid: news.ownerUid,
            caption: news.caption,
            timestamp: news.timestamp.dateValue(),
            likesCount: news.likesCount,
            commentsCount: news.commentsCount,
            postalCode: news.cosntituencyId,
            newsImageURLs: news.newsImageURLs,
            user: nil // ✅ No LocalUser relationship for optimal performance
        )
    }
    
    // MARK: ‑ Legacy Support (deprecated)
    @available(*, deprecated, message: "Use initialLoad instead")
    func fetchAndCacheNews(for pincode: String, context: ModelContext) async {
        await initialLoad(for: pincode, context: context)
    }
    
    // MARK: ‑ Performance Monitoring
    private func logPerformanceMetrics(operation: String, itemCount: Int, duration: TimeInterval) {
        #if DEBUG
        print("📊 \(operation): \(itemCount) items in \(String(format: "%.2f", duration))s")
        #endif
    }
    
    private func measureTime<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
}
