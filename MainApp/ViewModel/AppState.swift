//
//  AppState.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import FirebaseAuth

class AppState {
    
    static let shared = AppState()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var isLoading: Bool = false
    
    init(){
        self.userSession = Auth.auth().currentUser
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) async throws {
        isLoading = true
        
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            isLoading = false
        } catch {
//            print("isloading false")
            isLoading = false
            throw AuthError(error: error)
        }
        
    }
    
    @MainActor
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool) -> Void) async throws {
        isLoading = true
        
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
//            print("User created \(result.user.uid)")
            completion(true)
            isLoading = false
        }catch{
            print(error)
            isLoading = false
            throw AuthError(error: error)
        }
    }
    
    func signOut() {
        // Perform sign out logic here
        
        try? Auth.auth().signOut()
        self.userSession = nil
        
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError(error: error)
        }
    }
}
