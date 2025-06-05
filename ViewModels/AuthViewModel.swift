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
        print("DEBUG: AuthViewModel singleton initialized")
    }
    
    // Method to set the modelContext when it becomes available
    func setModelContext(_ context: ModelContext) {
        print("DEBUG: Setting model context in AuthViewModel: \(context)")
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
                print("DEBUG: Login successful for user ID: \(success)")
                
                // Clear any existing user data before loading new user
                if let context = self.modelContext {
                    do {
                        let existingUsers = try context.fetch(FetchDescriptor<LocalUser>())
                        if !existingUsers.isEmpty {
                            print("DEBUG: Clearing \(existingUsers.count) existing users before login")
                            for user in existingUsers {
                                context.delete(user)
                            }
                            try context.save()
                        }
                    } catch {
                        print("DEBUG: Failed to clear existing users: \(error)")
                    }
                }
                
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
        
        print("Debug: Create user here...")
        
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
        print("DEBUG: Fetching user data for ID: \(userId)")
        
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                print("DEBUG: Self is nil in fetchAndStoreUser completion")
                return
            }
            
            if let error = error {
                print("DEBUG: Error fetching user: \(error.localizedDescription)")
                errorMessage = AuthError.custom(message: error.localizedDescription)
                return
            }
            
            print("DEBUG: Snapshot exists: \(snapshot?.exists ?? false)")
            
            do {
                // Decode Firestore data to User struct
                let firestoreUser = try snapshot?.data(as: User.self)
                print("DEBUG: Firestore user decoded: \(firestoreUser != nil)")
                
                // Convert to LocalUser and store in SwiftData
                if let firestoreUser = firestoreUser {
                    print("DEBUG: About to store user locally: \(firestoreUser.name)")
                    self.storeUserLocally(firestoreUser: firestoreUser)
                } else {
                    // Create fallback user if data is missing
                    print("DEBUG: No user data found, creating mock user")
                    let mockUser = User(id: userId, name: "Demo User", email: "demo@example.com", username: "demouser")
                    self.storeUserLocally(firestoreUser: mockUser)
                }
            } catch {
                print("DEBUG: Error decoding user: \(error.localizedDescription)")
                errorMessage = AuthError.custom(message: error.localizedDescription)
                
                // Create mock user as fallback
                print("DEBUG: Creating mock user after error")
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
        
        print("DEBUG: About to store user locally with valid modelContext")
        
        do {
            // ALWAYS clear all existing data first to ensure only one user
            clearAllLocalData(using: modelContext)
            
            // Verify that clearing worked
            let existingUsers = try modelContext.fetch(FetchDescriptor<LocalUser>())
            if !existingUsers.isEmpty {
                print("WARNING: Found \(existingUsers.count) users after clearing, force deleting")
                for user in existingUsers {
                    modelContext.delete(user)
                }
                try modelContext.save()
            }
            
            // Create and insert the new user
            print("DEBUG: Creating new local user \(firestoreUser.name) with ID: \(firestoreUser.id)")
            let localUser = LocalUser(
                id: firestoreUser.id,
                name: firestoreUser.name,
                username: firestoreUser.username,
                email: firestoreUser.email,
                bio: firestoreUser.bio,
                profileImageUrl: firestoreUser.profileImageUrl,
                postCount: firestoreUser.postsCount,
                likedCount: firestoreUser.likedCount,
                commentCount: firestoreUser.commentsCount
            )
            modelContext.insert(localUser)
            
            try modelContext.save()
            print("DEBUG: Successfully saved user to SwiftData")
            
            // Verify that only one user was saved
            let finalUsers = try modelContext.fetch(FetchDescriptor<LocalUser>())
            print("DEBUG: Final user count after save: \(finalUsers.count)")
            
            if finalUsers.count != 1 {
                print("ERROR: Expected 1 user but found \(finalUsers.count)")
                errorMessage = AuthError.custom(message: "Multiple users detected after save")
            }
            
        } catch {
            print("Error storing local user: \(error.localizedDescription)")
            print("Full error: \(error)")
            errorMessage = AuthError.custom(message: "Failed to save local user")
            
            // Recovery attempt with complete reset
            do {
                print("DEBUG: Attempting recovery with complete reset")
                
                // Nuclear option: delete everything
                try? modelContext.delete(model: LocalNews.self)
                try? modelContext.delete(model: LocalVote.self)
                try? modelContext.delete(model: LocalUser.self)
                try modelContext.save()
                
                // Now create the user
                let localUser = LocalUser(
                    id: firestoreUser.id,
                    name: firestoreUser.name,
                    username: firestoreUser.username,
                    email: firestoreUser.email,
                    bio: firestoreUser.bio,
                    profileImageUrl: firestoreUser.profileImageUrl,
                    postCount: firestoreUser.postsCount,
                    likedCount: firestoreUser.likedCount,
                    commentCount: firestoreUser.commentsCount
                )
                
                modelContext.insert(localUser)
                try modelContext.save()
                print("DEBUG: Recovery successful")
                
                // Verify recovery
                let recoveryUsers = try modelContext.fetch(FetchDescriptor<LocalUser>())
                print("DEBUG: Recovery user count: \(recoveryUsers.count)")
                
            } catch {
                print("Second attempt to store local user also failed: \(error.localizedDescription)")
                errorMessage = AuthError.custom(message: "Failed to save local user after multiple attempts")
            }
        }
    }
    
    // Helper method to clear all local data
    private func clearAllLocalData(using context: ModelContext) {
        do {
            print("DEBUG: Starting clearAllLocalData - preserving news items")
            
            // Only clear LocalUsers - preserve news and votes
            let usersFetch = FetchDescriptor<LocalUser>()
            let users = try context.fetch(usersFetch)
            print("DEBUG: Found \(users.count) users to clear")
            for user in users {
                // Break all relationships first
                user.newsItems.removeAll()
                context.delete(user)
            }
            
            // Force save to ensure everything is committed
            try context.save()
            print("DEBUG: Successfully cleared users while preserving news data")
            
            // Verify the clearing worked
            let verifyUsers = try context.fetch(FetchDescriptor<LocalUser>())
            let verifyNews = try context.fetch(FetchDescriptor<LocalNews>())
            let verifyVotes = try context.fetch(FetchDescriptor<LocalVote>())
            
            print("DEBUG: After clearing - Users: \(verifyUsers.count), News: \(verifyNews.count) (preserved), Votes: \(verifyVotes.count) (preserved)")
            
        } catch {
            print("Warning: Could not clear users: \(error.localizedDescription)")
            print("Full error: \(error)")
            
            // Last resort: try to delete only users using batch operations
            do {
                print("DEBUG: Attempting last resort user-only batch delete")
                try context.delete(model: LocalUser.self)
                try context.save()
                print("DEBUG: Last resort user batch delete successful")
            } catch {
                print("ERROR: Even user batch delete failed: \(error)")
            }
        }
    }
    
    // Complete clearing method (for logout or critical reset scenarios)
    private func clearAllLocalDataCompletely(using context: ModelContext) {
        do {
            print("DEBUG: Starting complete clearAllLocalData")
            
            // Clear all LocalNews first (including breaking relationships)
            let newsFetch = FetchDescriptor<LocalNews>()
            let newsItems = try context.fetch(newsFetch)
            print("DEBUG: Found \(newsItems.count) news items to clear")
            for newsItem in newsItems {
                // Break the relationship first
                newsItem.user = nil
                context.delete(newsItem)
            }
            
            // Clear all LocalVotes
            let votesFetch = FetchDescriptor<LocalVote>()
            let voteItems = try context.fetch(votesFetch)
            print("DEBUG: Found \(voteItems.count) vote items to clear")
            for voteItem in voteItems {
                context.delete(voteItem)
            }
            
            // Clear all LocalUsers last
            let usersFetch = FetchDescriptor<LocalUser>()
            let users = try context.fetch(usersFetch)
            print("DEBUG: Found \(users.count) users to clear")
            for user in users {
                // Break all relationships first
                user.newsItems.removeAll()
                context.delete(user)
            }
            
            // Force save to ensure everything is committed
            try context.save()
            print("DEBUG: Successfully cleared all existing local data completely")
            
            // Verify the clearing worked
            let verifyUsers = try context.fetch(FetchDescriptor<LocalUser>())
            let verifyNews = try context.fetch(FetchDescriptor<LocalNews>())
            let verifyVotes = try context.fetch(FetchDescriptor<LocalVote>())
            
            print("DEBUG: After complete clearing - Users: \(verifyUsers.count), News: \(verifyNews.count), Votes: \(verifyVotes.count)")
            
            if verifyUsers.count > 0 || verifyNews.count > 0 || verifyVotes.count > 0 {
                print("WARNING: Some data was not cleared properly, attempting force clear")
                // Force delete using batch operations
                try context.delete(model: LocalNews.self)
                try context.delete(model: LocalVote.self)
                try context.delete(model: LocalUser.self)
                try context.save()
                print("DEBUG: Force clear completed")
            }
            
        } catch {
            print("Warning: Could not clear all local data: \(error.localizedDescription)")
            print("Full error: \(error)")
            
            // Last resort: try to delete everything using batch operations
            do {
                print("DEBUG: Attempting last resort batch delete")
                try context.delete(model: LocalNews.self)
                try context.delete(model: LocalVote.self)
                try context.delete(model: LocalUser.self)
                try context.save()
                print("DEBUG: Last resort batch delete successful")
            } catch {
                print("ERROR: Even batch delete failed: \(error)")
            }
        }
    }
    
    // Instance method that uses the stored modelContext
    func clearLocalUser(completely: Bool = false) {
        guard let modelContext = self.modelContext else {
            print("ERROR: No modelContext available in clearLocalUser")
            return
        }
        
        print("DEBUG: Clearing local user with valid modelContext (completely: \(completely))")
        if completely {
            clearAllLocalDataCompletely(using: modelContext)
        } else {
            clearUserData(using: modelContext)
        }
    }
    
    // Static method for backwards compatibility
    static func clearLocalUser(completely: Bool = false) {
        print("DEBUG: Static clearLocalUser called (completely: \(completely))")
        AuthViewModel.shared.clearLocalUser(completely: completely)
    }
    
    // Helper method to clear user data with a specific context (preserves news by default)
    private func clearUserData(using context: ModelContext) {
        do {
            print("DEBUG: Starting clearUserData process - preserving news")
            
            // Only clear LocalUsers - preserve news and votes
            let userFetchDescriptor = FetchDescriptor<LocalUser>()
            let users = try context.fetch(userFetchDescriptor)
            print("DEBUG: Found \(users.count) users to delete")
            
            for user in users {
                // Clear the inverse relationship first
                user.newsItems.removeAll()
                context.delete(user)
            }
            
            // Save all changes
            print("DEBUG: Saving cleared user data to context")
            try context.save()
            print("Successfully cleared local user data while preserving news")
            
        } catch {
            print("Failed to clear local user data: \(error.localizedDescription)")
            print("Full error: \(error)")
            
            // Recovery attempt: Try to delete users only forcefully
            do {
                print("DEBUG: Attempting recovery with user-only force clear")
                
                // Use deleteAll approach for users only
                try context.delete(model: LocalUser.self)
                try context.save()
                print("DEBUG: User-only recovery successful")
                
            } catch {
                print("Recovery attempt also failed: \(error.localizedDescription)")
                print("Recovery full error: \(error)")
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
