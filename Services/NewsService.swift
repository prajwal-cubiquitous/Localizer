import Foundation
import Firebase
import FirebaseFirestore

struct NewsService {
    static func uploadNews(_ news: News, constituencyID: String) async throws -> String {
        let db = Firestore.firestore()
        do {
            let newsData = try Firestore.Encoder().encode(news)
            let documentRef = try await db.collection("constituencies").document(constituencyID).collection("news").addDocument(data: newsData)
            
            // Return the auto-generated document ID
            return documentRef.documentID
        } catch {
            throw error
        }
    }
} 
