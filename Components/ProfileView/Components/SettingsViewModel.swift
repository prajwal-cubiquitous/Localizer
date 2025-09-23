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
    
    func saveAllConstituencies(primary: String, secondary: String, third: String, constituencies: [ConstituencyDetails]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        do {
            var constituencyIds: [String] = []
            
            for constituency in constituencies {
                print(constituency.constituencyName)
                if let constituencyID = constituency.id{
                    constituencyIds.append(constituencyID)
                }
            }
            
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
    
    func fetchConstituency(byDocumentId documentId: String) async -> ConstituencyDetails? {
        
        let db = Firestore.firestore()
        do {
            // Direct document fetch using document ID for fastest access
            let document = try await db.collection("constituencies")
                .document(documentId)
                .getDocument()
            
            let result = try document.data(as: ConstituencyDetails.self)
            return result
        } catch {
            print("❌ Error fetching constituency by document ID: \(error)")
            return nil
        }
    }
    
    func swapConstituencyWithPrimary(constituencyID: String) async {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)
            
            do {
                let document = try await userRef.getDocument()
                var constituencyIds = document.data()?["constituencyIDs"] as? [String] ?? []
                
                // Check if constituency already exists in the list
                if let existingIndex = constituencyIds.firstIndex(of: constituencyID) {
                    // If it exists, swap with primary (index 0)
                    if existingIndex != 0 {
                        constituencyIds.swapAt(0, existingIndex)
                        print("Swapped constituency from index \(existingIndex) to primary position")
                    } else {
                        print("Constituency is already primary")
                        return
                    }
                } else {
                    // If it doesn't exist, add as primary and move others down
                    constituencyIds.insert(constituencyID, at: 0)
                    // Keep only first 3 constituencies
                    if constituencyIds.count > 3 {
                        constituencyIds = Array(constituencyIds.prefix(3))
                    }
                    print("Added new constituency as primary")
                }
                
                try await userRef.updateData([
                    "constituencyIDs": constituencyIds
                ])
                
                print("Constituency swap completed successfully")
                print("Updated array: \(constituencyIds)")
                
            } catch {
                print("Error swapping constituency: \(error.localizedDescription)")
            }
        }
}
