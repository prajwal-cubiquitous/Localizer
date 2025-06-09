//
//  News.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//
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
class LocalNews {
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
    static func from(news: News, user: LocalUser?) -> LocalNews {
        return LocalNews(
            id: news.id,
            ownerUid: news.ownerUid,
            caption: news.caption,
            timestamp: news.timestamp.dateValue(), // ✅ Convert Firestore Timestamp -> Date
            likesCount: news.likesCount,
            commentsCount: news.commentsCount,
            postalCode: news.postalCode,
            newsImageURLs: news.newsImageURLs,
            user: user
        )
    }

    func toNews() -> News {
        return News(
            newsId: self.id,
            ownerUid: self.ownerUid,
            caption: self.caption,
            timestamp: Timestamp(date: self.timestamp), // ✅ Convert Date -> Firestore Timestamp
            likesCount: self.likesCount,
            commentsCount: self.commentsCount,
            postalCode: self.postalCode,
            user: self.user?.toUser(), // ✅ Convert LocalUser? to User?
            newsImageURLs: self.newsImageURLs,
        )
    }
}

struct DummyLocalNews{
    static var News1 = LocalNews(id: "kodsfjojf", ownerUid: "lsdfjoasjjdwowjh", caption: "This is commented news", timestamp: Date.now, likesCount: 20, commentsCount: 10, postalCode: "560043", newsImageURLs: ["https://media.licdn.com/dms/image/v2/D5603AQGTVPt9xIZ9YA/profile-displayphoto-shrink_200_200/profile-displayphoto-shrink_200_200/0/1711892894038?e=2147483647&v=beta&t=GF7yHb1bFs0wKm4NNo1fPa7skJNXDrBT-dUdeqy8Pfs"], user: DummylocalUser.user1)
    static var News2 = LocalNews(id: "kodsfjojf", ownerUid: "lsdfjoasjjdwowjh", caption: "this is liked news", timestamp: Date.now, likesCount: 20, commentsCount: 10, postalCode: "560043", newsImageURLs: ["https://media.licdn.com/dms/image/v2/D5603AQGTVPt9xIZ9YA/profile-displayphoto-shrink_200_200/profile-displayphoto-shrink_200_200/0/1711892894038?e=2147483647&v=beta&t=GF7yHb1bFs0wKm4NNo1fPa7skJNXDrBT-dUdeqy8Pfs"], user: DummylocalUser.user1)
    static var News3 = LocalNews(id: "kodsfjojf", ownerUid: "lsdfjoasjjdwowjh", caption: "This is SavedNews", timestamp: Date.now, likesCount: 20, commentsCount: 10, postalCode: "560043", newsImageURLs: ["https://media.licdn.com/dms/image/v2/D5603AQGTVPt9xIZ9YA/profile-displayphoto-shrink_200_200/profile-displayphoto-shrink_200_200/0/1711892894038?e=2147483647&v=beta&t=GF7yHb1bFs0wKm4NNo1fPa7skJNXDrBT-dUdeqy8Pfs"], user: DummylocalUser.user1)
}
