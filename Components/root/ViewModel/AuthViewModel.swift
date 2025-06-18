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
            clearAllLocalData()
            
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
        
        guard let currentUserId = AppState.shared.userSession?.uid else {
            print("❌ No current user session - cannot store user locally")
            return
        }
        
        // ✅ Only store if this is the current user
        guard firestoreUser.id == currentUserId else {
            print("⚠️ Attempted to store non-current user in SwiftData: \(firestoreUser.id)")
            return
        }
        
        do {
            // ✅ First, find and update existing current user OR create new one
            let existingUsersFetch = FetchDescriptor<LocalUser>(
                predicate: #Predicate<LocalUser> { $0.id == currentUserId }
            )
            let existingUsers = try modelContext.fetch(existingUsersFetch)
            
            if let existingUser = existingUsers.first {
                // Update existing user
                existingUser.name = firestoreUser.name
                existingUser.username = firestoreUser.username
                existingUser.email = firestoreUser.email
                existingUser.bio = firestoreUser.bio
                existingUser.profileImageUrl = firestoreUser.profileImageUrl
                existingUser.postCount = firestoreUser.postsCount
                existingUser.likedCount = firestoreUser.likedCount
                existingUser.dislikedCount = firestoreUser.dislikedCount
                existingUser.SavedPostsCount = firestoreUser.SavedPostsCount
                existingUser.commentCount = firestoreUser.commentsCount
                
                print("✅ Updated existing current user locally: \(firestoreUser.name)")
            } else {
                // Create new user - but first clear any existing users to avoid conflicts
                let allUsersFetch = FetchDescriptor<LocalUser>()
                let allUsers = try modelContext.fetch(allUsersFetch)
                for user in allUsers {
                    print("🗑️ Removing old user from SwiftData: \(user.name)")
                    modelContext.delete(user)
                }
                
                // Create and insert the new current user
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
                print("✅ Created new current user locally: \(firestoreUser.name)")
            }
            
            try modelContext.save()
            
        } catch {
            print("❌ Failed to store user locally: \(error)")
            errorMessage = AuthError.custom(message: "Failed to save local user")
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


extension AuthViewModel {
    
    func clearAllLocalData() {
        guard let modelContext = self.modelContext else {
            print("❌ No modelContext available. Creating temporary context.")
            createTempContextAndClear()
            print(7)
            return
        }
        print(2)
        clearData(in: modelContext)
        print(5)
    }
    
    static func clearAllLocalData() {
        print(1)
        AuthViewModel.shared.clearAllLocalData()
        print(6)
    }
    
    private func createTempContextAndClear() {
        do {
            let container = try ModelContainer(for: LocalUser.self, LocalNews.self, LocalVote.self)
            let tempContext = ModelContext(container)
            clearData(in: tempContext)
        } catch {
            print("❌ Failed to create temp context: \(error)")
        }
    }
    
    private func clearData(in context: ModelContext) {
        do {
            print(3)
            // Delete LocalUser
            let users = try context.fetch(FetchDescriptor<LocalUser>())
            users.forEach { context.delete($0) }
            print("✅ Cleared LocalUser")

            // Delete LocalNews
            let newsItems = try context.fetch(FetchDescriptor<LocalNews>())
            newsItems.forEach { context.delete($0) }
            print("✅ Cleared LocalNews")

            // Delete LocalVote
            let votes = try context.fetch(FetchDescriptor<LocalVote>())
            votes.forEach { context.delete($0) }
            print("✅ Cleared LocalVote")

            // ✅ Clear UserCache
            UserCache.shared.clearCache()
            print("✅ Cleared UserCache")
            
            // ✅ Clear news feed state from AppState
            AppState.shared.clearNewsFeedState()
            print("✅ Cleared NewsFeed state")

            // Optional: Clear temporary media
            MediaHandler.clearTemporaryMedia()

            try context.save()
            print("✅ All data cleared and saved.")
            print(4)
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
}

