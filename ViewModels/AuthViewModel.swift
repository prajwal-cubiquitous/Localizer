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
            // ✅ First clear any existing data to avoid conflicts
            clearLocalUser()
            
            try await AppState.shared.signIn(email: email, password: password) { success in
                // ✅ Fetch and store user data synchronously to ensure it's available immediately
                Task { @MainActor in
                    await self.fetchAndStoreUserAsync(userId: success)
                }
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
    
    // ✅ New async version of fetchAndStoreUser for better control
    @MainActor
    func fetchAndStoreUserAsync(userId: String) async {
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(userId).getDocument()
            
            let firestoreUser: User
            if let data = try? snapshot.data(as: User.self) {
                firestoreUser = data
            } else {
                // Create fallback user if data is missing
                firestoreUser = User(id: userId, name: "Demo User", email: "demo@example.com", username: "demouser")
            }
            
            // Store user locally on main thread
            await storeUserLocallyAsync(firestoreUser: firestoreUser)
            
        } catch {
            errorMessage = AuthError.custom(message: error.localizedDescription)
            
            // Create mock user as fallback
            let mockUser = User(id: userId, name: "Demo User", email: "demo@example.com", username: "demouser")
            await storeUserLocallyAsync(firestoreUser: mockUser)
        }
    }
    
    // ✅ Async version for better error handling and immediate availability
    @MainActor
    private func storeUserLocallyAsync(firestoreUser: User) async {
        guard let modelContext = self.modelContext else {
            print("ERROR: modelContext is nil in storeUserLocallyAsync")
            errorMessage = AuthError.custom(message: "Failed to save local user: No database context available")
            return
        }
        
        do {
            // First clear any existing users to avoid conflicts
            let existingUsersFetch = FetchDescriptor<LocalUser>()
            let existingUsers = try modelContext.fetch(existingUsersFetch)
            for user in existingUsers {
                modelContext.delete(user)
            }
            
            // Create and insert the new user
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
            try modelContext.save()
            
            print("✅ Successfully stored user locally: \(firestoreUser.name)")
            
        } catch {
            print("❌ Failed to store user locally: \(error)")
            errorMessage = AuthError.custom(message: "Failed to save local user")
        }
    }
    
    // Instance method that uses the stored modelContext
    func clearLocalUser() {
        guard let modelContext = self.modelContext else {
            print("ERROR: No modelContext available in clearLocalUser")
            // Create a temporary context as fallback
            do {
                let container = try ModelContainer(for: LocalUser.self, LocalNews.self, LocalVote.self)
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
        let maxRetries = 3
        var currentRetry = 0
        var success = false
        
        while !success && currentRetry < maxRetries {
            do {
                // ✅ Clear LocalUsers
                let userFetchDescriptor = FetchDescriptor<LocalUser>()
                let users = try context.fetch(userFetchDescriptor)
                for user in users {
                    context.delete(user)
                }
                
                // ✅ Clear LocalNews data
                let newsFetchDescriptor = FetchDescriptor<LocalNews>()
                let newsItems = try context.fetch(newsFetchDescriptor)
                for news in newsItems {
                    context.delete(news)
                }
                
                // ✅ Clear LocalVote data
                let voteFetchDescriptor = FetchDescriptor<LocalVote>()
                let votes = try context.fetch(voteFetchDescriptor)
                for vote in votes {
                    context.delete(vote)
                }
                
                // ✅ Clear temporary media files
                MediaHandler.clearTemporaryMedia()
                
                // Save changes
                try context.save()
                success = true
                print("✅ Successfully cleared all local user data, news, votes, and media")
                
            } catch {
                currentRetry += 1
                print("❌ Failed to clear local data (attempt \(currentRetry)): \(error)")
                
                // Wait briefly before retrying
                if currentRetry < maxRetries {
                    Thread.sleep(forTimeInterval: 0.5)
                } else {
                    errorMessage = AuthError.custom(message: "Failed to clear local data after multiple attempts")
                }
            }
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
