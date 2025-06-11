import Foundation
import Firebase
import FirebaseFirestore

struct NewsService {
    static func uploadNews(_ news: News) async throws {
        let db = Firestore.firestore()
        do{
            let newsData = try Firestore.Encoder().encode(news)
            try await db.collection("news").addDocument(data: newsData)
        }catch{
            throw error
        }
    }
} 
