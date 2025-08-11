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
    @Published var count : Int = 0
    
    // MARK: - Private State
    let pageSize = 10 // Load 20 items per page
    private var lastDocument: DocumentSnapshot?
    private var firstDocument: DocumentSnapshot?
    private var currentConstituencyId = ""
    let maxLocalItems = 20 // Store 50 items locally as per requirements
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
        count = 0
        
        do {
            let (remoteNews, lastDoc) = try await fetchNewsFromFirestore(
                constituencyId: constituencyId, 
                startAfter: nil,
                Descending: true
            )
            
            lastDocument = lastDoc
            hasMorePages = remoteNews.count == pageSize
            
            print("Started laoding the page")
            
            await replaceLocalNews(remoteNews, constituencyId: constituencyId, context: context)
            
            await fetchNewestDocumentSnapshot(context: context)
            
            
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
                startAfter: lastDocument,
                Descending: true
            )
            
            lastDocument = lastDoc
            hasMorePages = remoteNews.count == pageSize
            
            count += 1
            print("\(count) times pagesize has hitted")
            
            if count >= maxLocalItems/pageSize {
                await appendToLocalNewsandDeleteFirst(remoteNews, context: context)
            }
            
            await appendToLocalNews(remoteNews, context: context)
            
            await fetchNewestDocumentSnapshot(context: context)
            
        } catch {
            self.error = "Failed to load more news: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
    
    func loadMoreReverse(context: ModelContext) async {
        guard !isLoadingMore && hasMorePages && !currentConstituencyId.isEmpty else { return }
        print("starting reverse")
        isLoadingMore = true
        error = nil
        
        do {
            let (remoteNews, firstDoc) = try await fetchNewsFromFirestore(
                constituencyId: currentConstituencyId,
                startAfter: firstDocument,
                Descending: false
            )
            
            firstDocument = firstDoc
            hasMorePages = remoteNews.count == pageSize
            
            count -= 1
            print("\(count) times pagesize has hitted")
            
            if count >= maxLocalItems/pageSize {
                await addToLocalNewsandDeleteLast(remoteNews, context: context)
            }
            
            await appendToLocalNews(remoteNews, context: context)
            
            await fetchNewestDocumentSnapshot(context: context, reverse: true)
            
            
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
        startAfter: DocumentSnapshot?,
        Descending: Bool
    ) async throws -> ([News], DocumentSnapshot?) {
        let db = Firestore.firestore()
        var query = db.collection("news")
            .whereField("cosntituencyId", isEqualTo: constituencyId)
            .order(by: "timestamp", descending: Descending)
            .limit(to: pageSize)
        
        // Add pagination cursor if provided
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        let snapshot = try await query.getDocuments()
        let news = snapshot.documents.compactMap { doc in
            do {
                var newsItem = try doc.data(as: News.self)
                // Set the regular documentId field if it's not already set
                if newsItem.documentId == nil && newsItem.newsId == nil {
                    // Create a new News instance with the document ID in the regular field
                    newsItem = News(
                        newsId: nil, // Don't set @DocumentID manually
                        documentId: doc.documentID, // Use regular field
                        ownerUid: newsItem.ownerUid,
                        caption: newsItem.caption,
                        timestamp: newsItem.timestamp,
                        likesCount: newsItem.likesCount,
                        commentsCount: newsItem.commentsCount,
                        cosntituencyId: newsItem.cosntituencyId,
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
                // Silently handle local items limit errors
            }
        }
    }
    
    // Assuming 'pageSize' is a property available in this scope, e.g., self.pageSize
    private func appendToLocalNewsandDeleteFirst(_ items: [News], context: ModelContext) async {
        let constituencyId = self.currentConstituencyId

        // 1. NEW: Remove the oldest 'pageSize' items first
        await MainActor.run {
            do {
                // Create a descriptor to fetch the OLDEST items by sorting with .forward
                var oldItemsDescriptor = FetchDescriptor<LocalNews>(
                    predicate: #Predicate<LocalNews> { $0.constituencyId == constituencyId },
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)] // .forward gets oldest first
                )
                // Limit the fetch to only the number of items you want to remove
                oldItemsDescriptor.fetchLimit = self.pageSize

                let itemsToRemove = try context.fetch(oldItemsDescriptor)
                for item in itemsToRemove {
                    context.delete(item)
                }
            } catch {
                // It's good practice to log this error, even if you don't show it to the user
                print("Failed to remove the oldest page of news items: \(error.localizedDescription)")
            }
        }

        // 2. Insert the new items (your original code)
        await insertLocalNews(items, context: context)
        
        // 3. Maintain the overall max limit and save all changes
        await MainActor.run {
            do {
                // This descriptor gets the newest items first to trim any excess from the end
                let allItemsDescriptor = FetchDescriptor<LocalNews>(
                    predicate: #Predicate<LocalNews> { $0.constituencyId == constituencyId },
                    sortBy: [SortDescriptor(\.timestamp, order: .forward)]
                )
                let allItems = try context.fetch(allItemsDescriptor)
                
                // This check remains as a safety net to enforce the hard limit
                if allItems.count > maxLocalItems {
                    let excessItems = allItems.suffix(allItems.count - maxLocalItems)
                    for item in excessItems {
                        context.delete(item)
                    }
                }
                
                // Save all changes (new deletions and new insertions) in one transaction
                try context.save()
            } catch {
                // Silently handle final limit enforcement and save errors
            }
        }
    }
    
    private func addToLocalNewsandDeleteLast(_ items: [News], context: ModelContext) async {
        let constituencyId = self.currentConstituencyId

        // 1. NEW: Remove the oldest 'pageSize' items first
        await MainActor.run {
            do {
                // Create a descriptor to fetch the OLDEST items by sorting with .forward
                var oldItemsDescriptor = FetchDescriptor<LocalNews>(
                    predicate: #Predicate<LocalNews> { $0.constituencyId == constituencyId },
                    sortBy: [SortDescriptor(\.timestamp, order: .forward)] // .forward gets oldest first
                )
                // Limit the fetch to only the number of items you want to remove
                oldItemsDescriptor.fetchLimit = self.pageSize

                let itemsToRemove = try context.fetch(oldItemsDescriptor)
                for item in itemsToRemove {
                    context.delete(item)
                }
            } catch {
                // It's good practice to log this error, even if you don't show it to the user
                print("Failed to remove the oldest page of news items: \(error.localizedDescription)")
            }
        }

        // 2. Insert the new items (your original code)
        await insertLocalNews(items, context: context)
        
        // 3. Maintain the overall max limit and save all changes
        await MainActor.run {
            do {
                // This descriptor gets the newest items first to trim any excess from the end
                let allItemsDescriptor = FetchDescriptor<LocalNews>(
                    predicate: #Predicate<LocalNews> { $0.constituencyId == constituencyId },
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                let allItems = try context.fetch(allItemsDescriptor)
                
                // This check remains as a safety net to enforce the hard limit
                if allItems.count > maxLocalItems {
                    let excessItems = allItems.suffix(allItems.count - maxLocalItems)
                    for item in excessItems {
                        context.delete(item)
                    }
                }
                
                // Save all changes (new deletions and new insertions) in one transaction
                try context.save()
            } catch {
                // Silently handle final limit enforcement and save errors
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
                        // Skip duplicate news item
                        continue
                    }
                    
                    // Process the news item synchronously
                    processNewsItemSync(news, currentUserId: currentUserId, context: context)
                }
                
                // Save context
                try context.save()
                            } catch {
                    // Silently handle local news insertion errors
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
                // Silently handle user caching errors
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
                // Silently handle user caching errors
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
    
    func getNewestLocalNews(context: ModelContext, reverse: Bool) throws -> LocalNews? {
        // 1. Define the query using a FetchDescriptor.
        var fetchDescriptor = FetchDescriptor<LocalNews>()
        
        // 2. Set the sort order to place the newest item first.
        fetchDescriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        
        // 3. IMPORTANT: Set the fetch limit to 1 for maximum efficiency.
        // This tells the database to stop searching after finding the first item.
        fetchDescriptor.fetchLimit = maxLocalItems
        
        // 4. Execute the fetch and return the first item from the resulting array.
        // The array will contain either one item or be empty.
        let results = try context.fetch(fetchDescriptor)
        return reverse ? results.last : results.first
    }
    
    func fetchNewestDocumentSnapshot(context: ModelContext, reverse : Bool = false) async {
        // Assuming 'modelContext' is available in this scope
        
        do {
            // 1. Safely get the ID of your newest local news item
            guard let newestNewsId = try getNewestLocalNews(context: context, reverse: reverse)?.id else {
                print("No local news found. Cannot fetch snapshot.")
                return
            }
            
            // 2. Create the reference to the document in Firestore
            let documentRef = Firestore.firestore().collection("news").document(newestNewsId)
            
            // 3. Asynchronously fetch the DocumentSnapshot using the reference
            if reverse{
                self.lastDocument = try await documentRef.getDocument()
            }else{
                self.firstDocument = try await documentRef.getDocument()
            }
                        
        } catch {
            print("Failed to get document snapshot: \(error.localizedDescription)")
        }
    }
}

