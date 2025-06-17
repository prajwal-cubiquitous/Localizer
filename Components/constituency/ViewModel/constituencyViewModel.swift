//
//  constituencyViewMOdel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/17/25.
//
import Foundation
import FirebaseFirestore
import Combine

@MainActor
class constituencyViewModel: ObservableObject {
    func fetchConstituency(forPincode pincode: String) async -> [ConstituencyDetails] {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("constituencies")
                .whereField("associatedPincodes", arrayContains: pincode)
                .getDocuments()
            
            let result = try snapshot.documents.compactMap {
                try $0.data(as: ConstituencyDetails.self)
            }
            return result
        } catch {
            print("❌ Error fetching constituency: \(error)")
            return []
        }
    }
}
