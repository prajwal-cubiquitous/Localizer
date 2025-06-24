import Foundation
import Firebase
import FirebaseFirestore

struct NewsService {
    static func uploadNews(_ news: News) async throws -> String {
        let db = Firestore.firestore()
        do {
            let newsData = try Firestore.Encoder().encode(news)
            let documentRef = try await db.collection("news").addDocument(data: newsData)
            
            // ✅ Update the document with its own ID so it can be retrieved later
            try await documentRef.updateData([
                "newsId": documentRef.documentID
            ])
            
            print("✅ News uploaded with document ID: \(documentRef.documentID)")
            
            // Return the auto-generated document ID
            return documentRef.documentID
        } catch {
            throw error
        }
    }
} 
