//
//  News.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//
import SwiftUI
import Foundation
import SwiftData
@preconcurrency import FirebaseFirestore

struct News: Identifiable, Codable, Sendable {
    @DocumentID var newsId: String?
    
    var id: String {
        return newsId ?? UUID().uuidString
    }
    
    let ownerUid: String
    let caption: String
    let timestamp: Timestamp
    var likesCount: Int
    var commentsCount: Int
    let postalCode: String
    var user: User?
    var newsImageURLs: [String]?
}

@Model
final class LocalNews: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var ownerUid: String
    var caption: String
    var timestamp: Date
    var likesCount: Int
    var commentsCount: Int
    var postalCode: String
    
    // Store image URLs as JSON string to avoid CoreData array compatibility issues
    private var newsImageURLsData: String?
    
    // Computed property to handle array conversion
    var newsImageURLs: [String]? {
        get {
            guard let data = newsImageURLsData?.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([String].self, from: data)
        }
        set {
            if let urls = newValue, !urls.isEmpty {
                newsImageURLsData = try? String(data: JSONEncoder().encode(urls), encoding: .utf8)
            } else {
                newsImageURLsData = nil
            }
        }
    }
    
    // ✅ Relationship to LocalUser
    var user: LocalUser?
    
    init(
        id: String,
        ownerUid: String,
        caption: String,
        timestamp: Date,
        likesCount: Int,
        commentsCount: Int,
        postalCode: String,
        newsImageURLs: [String]?,
        user: LocalUser?
    ) {
        self.id = id
        self.ownerUid = ownerUid
        self.caption = caption
        self.timestamp = timestamp
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.postalCode = postalCode
        self.user = user
        
        // Set the image URLs using the computed property
        self.newsImageURLs = newsImageURLs
    }
}


extension LocalNews {
    // ✅ Performance optimized: Create LocalNews immediately with original URLs
    // Download media in background without blocking UI
    static func from(news: News, user: LocalUser?) async -> LocalNews {
        // Create LocalNews immediately with original URLs for immediate display
        let localNews = LocalNews(
            id: news.id,
            ownerUid: news.ownerUid,
            caption: news.caption,
            timestamp: news.timestamp.dateValue(),
            likesCount: news.likesCount,
            commentsCount: news.commentsCount,
            postalCode: news.postalCode,
            newsImageURLs: news.newsImageURLs, // ✅ Use original URLs first
            user: user
        )
        
        // ✅ Download media asynchronously in background for caching
        // This doesn't block the UI and allows images to display immediately
        if let imageURLs = news.newsImageURLs, !imageURLs.isEmpty {
            // ✅ Fix Swift 6 concurrency issue by capturing newsId and avoiding mutable variable capture
            let newsId = localNews.id
            Task.detached(priority: .background) { [imageURLs] in
                var downloadedURLs: [String] = []
                
                for urlString in imageURLs {
                    if let url = URL(string: urlString) {
                        let filename = url.lastPathComponent
                        do {
                            let localImageURL = try await MediaHandler.downloadMedia(from: url, fileName: filename)
                            downloadedURLs.append(localImageURL.absoluteString)
                        } catch {
                            // Keep original URL if download fails
                            downloadedURLs.append(urlString)
                        }
                    } else {
                        downloadedURLs.append(urlString)
                    }
                }
                
                // ✅ Update with local URLs once downloaded (optional optimization)
                // Find the news item by ID to avoid capturing the mutable object
                await MainActor.run { [downloadedURLs] in
                    // Note: This is optional optimization - the original URLs work fine
                    // We're not updating here to avoid complex SwiftData context issues
                }
            }
        }

        return localNews
    }

    func toNews() -> News {
        return News(
            newsId: self.id,
            ownerUid: self.ownerUid,
            caption: self.caption,
            timestamp: Timestamp(date: self.timestamp),
            likesCount: self.likesCount,
            commentsCount: self.commentsCount,
            postalCode: self.postalCode,
            user: self.user?.toUser(),
            newsImageURLs: self.newsImageURLs
        )
    }
}


struct DummyLocalNews{
    // ✅ Fixed: Each news item now has a unique ID
    static var News1 = LocalNews(id: "news_1_unique_id", ownerUid: "lsdfjoasjjdwowjh", caption: "This is commented news", timestamp: Date.now, likesCount: 20, commentsCount: 10, postalCode: "560043", newsImageURLs: ["https://firebasestorage.googleapis.com:443/v0/b/localizer-5c786.firebasestorage.app/o/news_videos%2F652730B9-3B96-4082-A77D-F427596E48BC.mov?alt=media&token=ec63c602-29e5-4b73-8e1d-95237993f35d", "https://firebasestorage.googleapis.com:443/v0/b/localizer-5c786.firebasestorage.app/o/news_images%2F61085B46-E378-4B6A-A9FB-9C96AAFB55D0?alt=media&token=b18ae060-8171-414a-8c17-ddc2319b461f", "https://firebasestorage.googleapis.com:443/v0/b/localizer-5c786.firebasestorage.app/o/news_images%2F61085B46-E378-4B6A-A9FB-9C96AAFB55D0?alt=media&token=b18ae060-8171-414a-8c17-ddc2319b461f"], user: DummylocalUser.user1)
    
    static var News2 = LocalNews(id: "news_2_unique_id", ownerUid: "lsdfjoasjjdwowjh", caption: "this is liked news", timestamp: Date.now, likesCount: 20, commentsCount: 10, postalCode: "560043", newsImageURLs: ["https://media.licdn.com/dms/image/v2/D5603AQGTVPt9xIZ9YA/profile-displayphoto-shrink_200_200/profile-displayphoto-shrink_200_200/0/1711892894038?e=2147483647&v=beta&t=GF7yHb1bFs0wKm4NNo1fPa7skJNXDrBT-dUdeqy8Pfs"], user: DummylocalUser.user1)
    
    static var News3 = LocalNews(id: "news_3_unique_id", ownerUid: "lsdfjoasjjdwowjh", caption: "This is SavedNews", timestamp: Date.now, likesCount: 20, commentsCount: 10, postalCode: "560043", newsImageURLs: ["https://firebasestorage.googleapis.com:443/v0/b/localizer-5c786.firebasestorage.app/o/news_videos%2F652730B9-3B96-4082-A77D-F427596E48BC.mov?alt=media&token=ec63c602-29e5-4b73-8e1d-95237993f35d"], user: DummylocalUser.user1)
}
