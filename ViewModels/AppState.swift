//
//  AppState.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AppState: ObservableObject {
    
    static let shared = AppState()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var isLoading: Bool = false
    @Published var userPincode: String = ""
    
    init(){
        self.userSession = Auth.auth().currentUser
    }
    var db = Firestore.firestore()
    
    func updatePincode(_ pincode: String) {
        self.userPincode = pincode
        print("DEBUG: AppState updated with pincode: \(pincode)")
    }
    
    func signIn(email: String, password: String, completion: @escaping (User.ID) -> Void) async throws {
        isLoading = true
        
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            isLoading = false
            completion(result.user.uid)
        } catch {
            isLoading = false
            throw AuthError(error: error)
        }
        
    }
    
    @MainActor
    func signUp(name: String, email: String, password: String, completion: @escaping (User.ID) -> Void) async throws {
        isLoading = true
        
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            //            print("User created \(result.user.uid)")
            self.signOut()
            isLoading = false
            completion(result.user.uid)
        }catch{
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
    
    func updateUserData(userID: String, data: [String: Any]) async throws {
        guard self.userSession != nil else {
            fatalError("No user signed in.")
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("users").document(userID).updateData(data) { error in
                if let error = error {
                    continuation.resume(throwing: AuthError(error: error))
                } else {
                    print("DEBUG: User profile successfully updated")
                    continuation.resume()
                }
            }
        }
    }

}
