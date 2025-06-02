
//
//  MainTabViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/2/25.
//

import Foundation
import SwiftData
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserDataManager: ObservableObject {
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    
    private var modelContext: ModelContext
    @Published var isLoading = false
    @Published var error: Error?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Authentication State Handling
    func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.fetchAndStoreUser(userId: user.uid)
            } else {
                self?.clearLocalUser()
            }
        }
    }
    
    // MARK: - Firestore Fetch & SwiftData Store
    func fetchAndStoreUser(userId: String) {
        isLoading = true
        error = nil
        
        firestore.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error
                return
            }
            
            do {
                // Decode Firestore data to User struct
                let firestoreUser = try snapshot?.data(as: User.self)
                
                // Convert to LocalUser and store in SwiftData
                if let firestoreUser = firestoreUser {
                    self.storeUserLocally(firestoreUser: firestoreUser)
                }
            } catch {
                self.error = error
            }
        }
    }

    
    private func storeUserLocally(firestoreUser: User) {
        // Delete existing user if any
        clearLocalUser()
        
        // Create new LocalUser from Firestore data
        let localUser = LocalUser(
            id: firestoreUser.id,
            name: firestoreUser.name,
            username: firestoreUser.username, email: firestoreUser.email,
            bio: firestoreUser.bio,
            profileImageUrl: firestoreUser.profileImageUrl,
            postCount: firestoreUser.postsCount,
            likedCount: firestoreUser.likedCount,
            commentCount: firestoreUser.commentsCount
        )
        
        modelContext.insert(localUser)
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Logout Cleanup
    func clearLocalUser() {
        let fetchDescriptor = FetchDescriptor<LocalUser>()
        do {
            let users = try modelContext.fetch(fetchDescriptor)
            for user in users {
                modelContext.delete(user)
            }
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
}


