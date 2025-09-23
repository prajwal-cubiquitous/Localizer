//
//  SettingsViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 9/18/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SettingsViewModel: ObservableObject {
    
    func addConsituencyIdToProfile(constituencyID: String, index: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        do {
            let document = try await userRef.getDocument()
            var constituencyIds = document.data()?["constituencyIDs"] as? [String] ?? []
            
            // Ensure array has enough elements
            while constituencyIds.count <= index {
                constituencyIds.append("")
            }
            
            // Update the specific index
            constituencyIds[index] = constituencyID
            
            // Remove trailing empty strings to keep array clean
            while !constituencyIds.isEmpty && constituencyIds.last == "" {
                constituencyIds.removeLast()
            }
            
            try await userRef.updateData([
                "constituencyIDs": constituencyIds
            ])
            print("ConstituencyID '\(constituencyID)' saved at index \(index) successfully")
            print("Updated constituencyIDs array: \(constituencyIds)")
        } catch {
            print("Error updating constituencyIDs array: \(error.localizedDescription)")
        }
    }
    
    func saveAllConstituencies(primary: String, secondary: String, third: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        do {
            var constituencyIds: [String] = []
            
            // Add constituencies in order, only if they're not empty
            if !primary.isEmpty {
                constituencyIds.append(primary)
            }
            if !secondary.isEmpty {
                constituencyIds.append(secondary)
            }
            if !third.isEmpty {
                constituencyIds.append(third)
            }
            
            try await userRef.updateData([
                "constituencyIDs": constituencyIds
            ])
            
            print("All constituencies saved successfully:")
            print("Primary: \(primary.isEmpty ? "Not set" : primary)")
            print("Secondary: \(secondary.isEmpty ? "Not set" : secondary)")
            print("Third: \(third.isEmpty ? "Not set" : third)")
            print("Final array: \(constituencyIds)")
        } catch {
            print("Error saving all constituencies: \(error.localizedDescription)")
        }
    }
}
