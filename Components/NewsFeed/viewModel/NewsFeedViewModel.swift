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

/// I am `Prajwal S S Reddy` is the greatest of all time

/// View-model responsible for keeping `LocalNews` in-sync with the latest items
/// from Firestore for the currently selected constituency with pagination support.
/// 
@MainActor
final class NewsFeedViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    @Published private(set) var error: String?
    @Published var cityID: String = ""
    
    // MARK: - Private State
    let pageSize = 20 // Load 20 items per page
    private var lastDocument: DocumentSnapshot?
    private var currentConstituencyId = ""
    private var currentCategory: NewsTab = .latest
    let maxLocalItems = 100 // Increased for better caching
    private var isInitialLoad = true
    
    // MARK: - Public API
    
    
    /// Legacy method for backward compatibility
    func fetchAndCacheNews(for constituencyId: String, context: ModelContext, category: NewsTab) async {
        await loadInitial(for: constituencyId, context: context, category: category)
    }
    
    /// Initial load of news for a constituency - replaces existing data
    func loadInitial(for constituencyId: String, context: ModelContext, category: NewsTab) async {
        guard !constituencyId.isEmpty else { return }
        
        // Only clear if switching constituencies or categories
        if currentConstituencyId != constituencyId || currentCategory != category {
            await clearLocalNewsForCategory(category: category, context: context)
        }
        
        isLoading = true
        error = nil
        currentConstituencyId = constituencyId
        currentCategory = category
        lastDocument = nil
        hasMorePages = true
        isInitialLoad = true
        
        do {
            let (remoteNews, lastDoc) = try await fetchNewsFromFirestore(
                constituencyId: constituencyId,
                startAfter: nil,
                descending: true,
                category: category
            )
            
            lastDocument = lastDoc
            hasMorePages = remoteNews.count == pageSize
            
            await replaceLocalNews(remoteNews, constituencyId: constituencyId, context: context)
            
        } catch {
            self.error = "Failed to load news: \(error.localizedDescription)"
        }
        
        isLoading = false
        isInitialLoad = false
    }
    
    /// Load more news items for infinite scroll
    func loadMore(context: ModelContext, category: NewsTab) async {
        guard !isLoadingMore && hasMorePages && !currentConstituencyId.isEmpty && category == currentCategory else { return }
        
        isLoadingMore = true
        error = nil
        
        do {
            let (remoteNews, lastDoc) = try await fetchNewsFromFirestore(
                constituencyId: currentConstituencyId,
                startAfter: lastDocument,
                descending: true,
                category: category
            )
            
            lastDocument = lastDoc
            hasMorePages = remoteNews.count == pageSize
            
            await appendToLocalNews(remoteNews, context: context)
            
        } catch {
            self.error = "Failed to load more news: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
    
    /// Refresh news feed (pull-to-refresh)
    func refresh(context: ModelContext, category: NewsTab) async {
        guard !isLoading && !currentConstituencyId.isEmpty else { return }
        
        // Reset pagination state
        lastDocument = nil
        hasMorePages = true
        
        // Load fresh data
        await loadInitial(for: currentConstituencyId, context: context, category: category)
    }
    

    
    // MARK: - Firestore Operations
    
    private func fetchNewsFromFirestore(
        constituencyId: String,
        startAfter: DocumentSnapshot?,
        descending: Bool,
        category: NewsTab
    ) async throws -> ([News], DocumentSnapshot?) {
        
        let db = Firestore.firestore()
        var news: [News] = []
        var lastDoc: DocumentSnapshot? = nil
        var query: Query
        
        switch category {
        case .trending:
            query = db.collection("constituencies").document(constituencyId)
                .collection("news")
                .order(by: "likesCount", descending: descending)
                .limit(to: pageSize)
            
        case .City:
            // Fetch the city asynchronously
            await fetchConstituencyId(for: constituencyId)
            let citySnapshot = try await db.collection("city").document(cityID).getDocument()
            let city = try citySnapshot.data(as: City.self)
            
            // Loop through constituencyIds and fetch news
            for cid in city.constituencyIds {
                query = db.collection("constituencies").document(cid)
                    .collection("news")
                    .order(by: "timestamp", descending: descending)
                    .limit(to: pageSize)
                
                if let startAfter = startAfter {
                    query = query.start(afterDocument: startAfter)
                }
                
                let snapshot = try await query.getDocuments()
                
                let fetchedNews = snapshot.documents.compactMap { doc -> News? in
                    do {
                        var newsItem = try doc.data(as: News.self)
                        if newsItem.documentId == nil && newsItem.newsId == nil {
                            newsItem = News(
                                newsId: nil,
                                documentId: doc.documentID,
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
                        return nil
                    }
                }
                
                news.append(contentsOf: fetchedNews)
                
                // Update the lastDoc for pagination
                if let last = snapshot.documents.last {
                    lastDoc = last
                }
            }
            
            return (news, lastDoc)
            
        default:
            query = db.collection("constituencies").document(constituencyId)
                .collection("news")
                .order(by: "timestamp", descending: descending)
                .limit(to: pageSize)
        }
        
        // Pagination for non-city categories
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        let snapshot = try await query.getDocuments()
        let fetchedNews = snapshot.documents.compactMap { doc -> News? in
            do {
                var newsItem = try doc.data(as: News.self)
                if newsItem.documentId == nil && newsItem.newsId == nil {
                    newsItem = News(
                        newsId: nil,
                        documentId: doc.documentID,
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
                return nil
            }
        }
        
        let lastNonCityDoc = snapshot.documents.last
        return (fetchedNews, lastNonCityDoc)
    }

    
    
    // MARK: - SwiftData Operations
    
    /// Replace all local news items (used for initial load)
    private func replaceLocalNews(_ items: [News], constituencyId: String, context: ModelContext) async {
        // 1. Clear existing items for this constituency
        await clearAllLocalNews(context: context)
        
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
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                let allItems = try context.fetch(fetchDescriptor)
                if allItems.count > maxLocalItems {
                    print("Deleting the ecxtra oldest news items")
                    let itemsToRemove = Array(allItems.suffix(allItems.count - maxLocalItems))
                    for item in itemsToRemove {
                        context.delete(item)
                    }
                    try context.save()
                    print("Done deleting")
                }
            } catch {
                // Silently handle local items limit errors
            }
        }
    }
    

    
    /// Clear local news for a specific category
    private func clearLocalNewsForCategory(category: NewsTab, context: ModelContext) async {
        do {
            let fetchDescriptor = FetchDescriptor<LocalNews>()
            let allNews = try context.fetch(fetchDescriptor)
            
            // For now, clear all news when switching categories
            // In the future, we could add category field to LocalNews model
            for item in allNews {
                context.delete(item)
            }
            try context.save()
        } catch {
            // Silent error handling for cleanup operations
        }
    }
    
    /// Clear all local news
    private func clearAllLocalNews(context: ModelContext) async {
        do {
            let fetchDescriptor = FetchDescriptor<LocalNews>()
            let allNews = try context.fetch(fetchDescriptor)
            for item in allNews {
                context.delete(item)
            }
            try context.save()
        } catch {
            // Silent error handling for cleanup
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
                let existingDescriptor = FetchDescriptor<LocalNews>()
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
            category: news.category,
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
            category: news.category,
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
        let cachedUser = CachedUser(username: user.username, profilePictureUrl: user.profileImageUrl, role: user.role.rawValue)
        // Cache the user for UI display
        UserCache.shared.cacheUser(userId: user.id, cachedUser: cachedUser)
    }
    
    func fetchConstituencyId(for documentId: String) async {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("constituencies")
                .document(documentId)
                .getDocument()
            
            // The constituencyId field in Firestore contains the pincode
            if let id = snapshot.data()?["constituencyId"] as? String {
                await MainActor.run {
                    self.cityID = id
                }
            } else {
                print("constituencyId not found for document: \(documentId)")
            }
        } catch {
            print("Error fetching document: \(error.localizedDescription)")
        }
    }
}

