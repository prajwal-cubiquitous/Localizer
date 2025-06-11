//
//  AuthViewModel.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import Combine
import FirebaseFirestore
import SwiftData

// Make AuthViewModel a singleton to ensure it stays alive during async operations
class AuthViewModel: ObservableObject {
    // Shared instance that will persist throughout the app's lifecycle
    static let shared = AuthViewModel()
    
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var authState: AuthState = .login
    
    @Published var errorMessage: AuthError?
    let db = Firestore.firestore()
    
    // model context for swift data - only one instance needed
    var modelContext: ModelContext?
    
    // Private init for singleton pattern
    private init() {
    }
    
    // Method to set the modelContext when it becomes available
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Computed property for form validation
    var isSignupFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        !fullName.isEmpty
    }
    
    var isLoginFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var isLoading: Bool {
        AppState.shared.isLoading
    }
    
    @MainActor
    func login() async throws{
        guard isLoginFormValid else { return }
        
        withAnimation {
            errorMessage = nil
        }
        
        do{
            try await AppState.shared.signIn(email: email, password: password) { success in
                self.fetchAndStoreUser(userId: success)
            }
        }catch let error as AuthError{
            errorMessage = error
        }catch{
            errorMessage = AuthError.custom(message: "Failed to login")
        }
    }
    
    @MainActor
    func signup()  async throws {
        guard isSignupFormValid else { return }
        
        withAnimation {
            errorMessage = nil
        }
        
        
        do{
            try await AppState.shared.signUp(name: fullName, email: email, password: password) { success in
                self.uploadUserData(user: User(id: success, name: self.fullName, email: self.email, username: self.username))
                self.authState = .login
            }
        }catch let error as AuthError{
            errorMessage = error
        }catch{
            errorMessage = AuthError.custom(message: "Failed to Create Account")
        }
    }
    
    func resetFields() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        errorMessage = nil
        username = ""
    }
    
    @MainActor
    func resetPassword() async throws {
        do{
            try await AppState.shared.resetPassword(email: email)
        }catch let error as AuthError{
            errorMessage = error
        }catch{
            errorMessage = AuthError.custom(message: "Failed to reset Password")
        }
    }
    
    func uploadUserData(user: User){
        do{
            try db.collection("users").document(user.id).setData(from: user)
            //            fetchAndStoreUser(userId: user.id)
        }catch{
            errorMessage = AuthError.custom(message: "Failed to upload user data")
        }
    }
    
    func fetchAndStoreUser(userId: String) {
        
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                return
            }
            
            if let error = error {
                errorMessage = AuthError.custom(message: error.localizedDescription)
                return
            }
            
            
            do {
                // Decode Firestore data to User struct
                let firestoreUser = try snapshot?.data(as: User.self)
                
                // Convert to LocalUser and store in SwiftData
                if let firestoreUser = firestoreUser {
                    self.storeUserLocally(firestoreUser: firestoreUser)
                } else {
                    // Create fallback user if data is missing
                    let mockUser = User(id: userId, name: "Demo User", email: "demo@example.com", username: "demouser")
                    self.storeUserLocally(firestoreUser: mockUser)
                }
            } catch {
                errorMessage = AuthError.custom(message: error.localizedDescription)
                
                // Create mock user as fallback
                let mockUser = User(id: userId, name: "Demo User", email: "demo@example.com", username: "demouser")
                self.storeUserLocally(firestoreUser: mockUser)
            }
        }
    }
    private func storeUserLocally(firestoreUser: User) {
        // Ensure we have a valid modelContext
        guard let modelContext = self.modelContext else {
            print("ERROR: modelContext is nil in storeUserLocally. Cannot save user data.")
            errorMessage = AuthError.custom(message: "Failed to save local user: No database context available")
            return
        }
        
        
        do {
            let fetchDescriptor = FetchDescriptor<LocalUser>(predicate: #Predicate { user in
                user.id == firestoreUser.id
            })
            let existingUsers = try modelContext.fetch(fetchDescriptor)
            
            if let existingUser = existingUsers.first {
                existingUser.name = firestoreUser.name
                existingUser.email = firestoreUser.email
                existingUser.username = firestoreUser.username
                existingUser.bio = firestoreUser.bio
                existingUser.profileImageUrl = firestoreUser.profileImageUrl
                existingUser.postCount = firestoreUser.postsCount
                existingUser.likedCount = firestoreUser.likedCount
                existingUser.commentCount = firestoreUser.commentsCount
            } else {
                let localUser = LocalUser(
                    id: firestoreUser.id,
                    name: firestoreUser.name,
                    username: firestoreUser.username,
                    email: firestoreUser.email,
                    bio: firestoreUser.bio,
                    profileImageUrl: firestoreUser.profileImageUrl,
                    postCount: firestoreUser.postsCount,
                    likedCount: firestoreUser.likedCount,
                    dislikedCount: firestoreUser.dislikedCount,
                    SavedPostsCount: firestoreUser.SavedPostsCount,
                    commentCount: firestoreUser.commentsCount
                )
                modelContext.insert(localUser)
            }
            try modelContext.save()
        } catch {
            errorMessage = AuthError.custom(message: "Failed to save local user")
            // Try again with simplified approach if the first attempt failed
            do {
                let localUser = LocalUser(
                    id: firestoreUser.id,
                    name: firestoreUser.name,
                    username: firestoreUser.username,
                    email: firestoreUser.email,
                    bio: firestoreUser.bio,
                    profileImageUrl: firestoreUser.profileImageUrl,
                    postCount: firestoreUser.postsCount,
                    likedCount: firestoreUser.likedCount,
                    dislikedCount: firestoreUser.dislikedCount,
                    SavedPostsCount: firestoreUser.SavedPostsCount,
                    commentCount: firestoreUser.commentsCount
                )
                
                // Delete any existing user with same ID to avoid conflicts
                if let existingUsers = try? modelContext.fetch(FetchDescriptor<LocalUser>()), !existingUsers.isEmpty {
                    for user in existingUsers {
                        modelContext.delete(user)
                    }
                }
                
                modelContext.insert(localUser)
                try modelContext.save()
            } catch {
                errorMessage = AuthError.custom(message: "Failed to save local user after multiple attempts")
            }
        }
    }
    
    // Instance method that uses the stored modelContext
    func clearLocalUser() {
        guard let modelContext = self.modelContext else {
            print("ERROR: No modelContext available in clearLocalUser")
            // Create a temporary context as fallback
            do {
                let container = try ModelContainer(for: LocalUser.self)
                let tempContext = ModelContext(container)
                clearUserData(using: tempContext)
            } catch {
                print("ERROR: Failed to create temporary context: \(error)")
            }
            return
        }
        
        clearUserData(using: modelContext)
    }
    
    // Static method for backwards compatibility
    static func clearLocalUser() {
        AuthViewModel.shared.clearLocalUser()
    }
    
    // Helper method to clear user data with a specific context
    private func clearUserData(using context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<LocalUser>()
        
        // Retry logic for robustness
        let maxRetries = 3
        var currentRetry = 0
        var success = false
        
        while !success && currentRetry < maxRetries {
            do {
                // Fetch all users
                let users = try context.fetch(fetchDescriptor)
                
                // Delete each user
                for user in users {
                    context.delete(user)
                }
                
                // Save changes
                try context.save()
                success = true
                
            } catch {
                currentRetry += 1
                
                // Wait briefly before retrying
                if currentRetry < maxRetries {
                    Thread.sleep(forTimeInterval: 0.5)
                } else {
                    errorMessage = AuthError.custom(message: "Failed to clear local user after multiple attempts")
                }
            }
            print("Recovery attempt also failed: ")
        }
    }
    
    func updateUserProfile(userID: String, name: String, bio: String) async {
        
        let data: [String: Any] = [
            "name": name,
            "bio": bio,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        do{
            try await AppState.shared.updateUserData(userID: userID, data: data)
        }catch{
            self.errorMessage = AuthError.custom(message: error.localizedDescription)
        }
    }
}

enum AuthState {
    case login
    case signup
}
