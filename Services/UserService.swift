//
//  UserService.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//

import FirebaseFirestore

struct FetchCurrencyUser{
    static func fetchCurrentUser(_ uid: String) async throws -> User {
        let docRef = Firestore.firestore().collection("users").document(uid)
        let snapshot = try await docRef.getDocument()
        guard let user = try? snapshot.data(as: User.self) else {
            throw NSError(domain: "PostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode current user"])
        }
        return user
    }

}
