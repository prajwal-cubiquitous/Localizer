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
            guard var constituencyIds = document.data()?["constituencyIDs"] as? [String] else { return }
            
            if constituencyIds.count > index {
                constituencyIds[index] = constituencyID
            } else {
                while constituencyIds.count < index {
                    constituencyIds.append("")
                }
                constituencyIds.append(constituencyID)
            }
            
            try await userRef.updateData([
                "constituencyIDs": constituencyIds
            ])
            print("ConstituencyID inserted at index \(index) successfully")
        } catch {
            print("Error updating constituencyIDs array: \(error.localizedDescription)")
        }
    }
}
