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

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published  var authState: AuthState = .login
    
    @Published var errorMessage: AuthError?
    let db = Firestore.firestore()
    
//    private var appState: AppState
//    
//    init(appState: AppState) {
//        self.appState = appState
//    }
    private var modelContext: ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
                if success{
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
            try db.collection("user").document(user.id).setData(from: user)
            fetchAndStoreUser(userId: user.id)
        }catch{
            errorMessage = AuthError.custom(message: "Failed to upload user data")
        }
    }
    
    func fetchAndStoreUser(userId: String) {
        
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            
            if let error = error {
//                self.error = error
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
//                self.error = error
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
            errorMessage = AuthError.custom(message: "Failed to save local user")
        }
    }
    
    func clearLocalUser() {
        let fetchDescriptor = FetchDescriptor<LocalUser>()
        do {
            let users = try modelContext.fetch(fetchDescriptor)
            for user in users {
                modelContext.delete(user)
            }
            try modelContext.save()
        } catch {
            errorMessage = AuthError.custom(message: "Failed to clear local user")
        }
    }


}

enum AuthState {
    case login
    case signup
}
