//
//  constituencyViewMOdel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/17/25.
//
import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

@MainActor
class constituencyViewModel: ObservableObject {
    @Published var constituencies: [ConstituencyDetails] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var wards: [Ward] = []
    
    func fetchConstituency(forPincode pincode: String) async -> [ConstituencyDetails] {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("constituencies")
                .whereField("Associated Pincodes (Compiled, Non-Official)", arrayContains: pincode)
                .getDocuments()
            
            var result = try snapshot.documents.compactMap {
                try $0.data(as: ConstituencyDetails.self)
            }
            
            guard let userId = Auth.auth().currentUser?.uid else { return [] }
            
            let constituencyIDs = try await fetchConstituencyIDs(userDocumentID: userId)
            
            for constituencyid in constituencyIDs {
                if let constituencydetail = await fetchConstituency(byDocumentId: constituencyid) {
                    result.append(constituencydetail)
                }
            }
            
            constituencies = result
            isLoading = false
            return result
        } catch {
            print("❌ Error fetching constituency: \(error)")
            errorMessage = "Failed to fetch constituency data: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
    
    func fetchConstituencyIDs(userDocumentID: String) async throws -> [String] {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userDocumentID)
        let document = try await docRef.getDocument()
        if document.exists,
           let ids = document.data()?["constituencyIDs"] as? [String] {
            return ids
        } else {
            return []
        }
    }
    
    func fetchAllConstituencies() async -> [ConstituencyDetails] {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("constituencies")
                .order(by: "constituencyNumber")
                .getDocuments()
            
            let result = try snapshot.documents.compactMap {
                try $0.data(as: ConstituencyDetails.self)
            }
            
            constituencies = result
            isLoading = false
            return result
        } catch {
            print("❌ Error fetching all constituencies: \(error)")
            errorMessage = "Failed to fetch constituencies: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
    
    func fetchConstituency(byName name: String) async -> ConstituencyDetails? {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("constituencies")
                .whereField("constituencyName", isEqualTo: name)
                .limit(to: 1)
                .getDocuments()
            
            let result = try snapshot.documents.first?.data(as: ConstituencyDetails.self)
            isLoading = false
            return result
        } catch {
            print("❌ Error fetching constituency by name: \(error)")
            errorMessage = "Failed to fetch constituency: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    func fetchConstituency(byDocumentId documentId: String) async -> ConstituencyDetails? {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        do {
            // Direct document fetch using document ID for fastest access
            let document = try await db.collection("constituencies")
                .document(documentId)
                .getDocument()
            
            let result = try document.data(as: ConstituencyDetails.self)
            isLoading = false
            return result
        } catch {
            print("❌ Error fetching constituency by document ID: \(error)")
            errorMessage = "Failed to fetch constituency: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    func fetchConstituency(byDocumentIdField documentId: String) async -> ConstituencyDetails? {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        do {
            // Alternative method using documentId field for querying
            let snapshot = try await db.collection("constituencies")
                .whereField("documentId", isEqualTo: documentId)
                .limit(to: 1)
                .getDocuments()
            
            let result = try snapshot.documents.first?.data(as: ConstituencyDetails.self)
            isLoading = false
            return result
        } catch {
            print("❌ Error fetching constituency by documentId field: \(error)")
            errorMessage = "Failed to fetch constituency: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    func searchConstituencies(by searchTerm: String) async -> [ConstituencyDetails] {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        do {
            // Search by constituency name or MLA name
            let nameSnapshot = try await db.collection("constituencies")
                .whereField("constituencyName", isGreaterThanOrEqualTo: searchTerm)
                .whereField("constituencyName", isLessThan: searchTerm + "\u{f8ff}")
                .getDocuments()
            
            let mlaSnapshot = try await db.collection("constituencies")
                .whereField("currentMLAName", isGreaterThanOrEqualTo: searchTerm)
                .whereField("currentMLAName", isLessThan: searchTerm + "\u{f8ff}")
                .getDocuments()
            
            var results: [ConstituencyDetails] = []
            
            // Combine results and remove duplicates
            let nameResults = try nameSnapshot.documents.compactMap {
                try $0.data(as: ConstituencyDetails.self)
            }
            
            let mlaResults = try mlaSnapshot.documents.compactMap {
                try $0.data(as: ConstituencyDetails.self)
            }
            
            results.append(contentsOf: nameResults)
            results.append(contentsOf: mlaResults)
            
            // Remove duplicates based on constituency number
            let uniqueResults = Array(Set(results.map { $0.constituencyNumber }))
                .compactMap { number in
                    results.first { $0.constituencyNumber == number }
                }
                .sorted { $0.constituencyNumber < $1.constituencyNumber }
            
            constituencies = uniqueResults
            isLoading = false
            return uniqueResults
        } catch {
            print("❌ Error searching constituencies: \(error)")
            errorMessage = "Failed to search constituencies: \(error.localizedDescription)"
            isLoading = false
            return []
        }
    }
    
    func fetchWards(for constituencyId: String) {
        let db = Firestore.firestore()
        let wardsRef = db.collection("constituencies")
                         .document(constituencyId)
                         .collection("wards")
        
        wardsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching wards: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No wards subcollection found or it's empty.")
                return
            }
            
            self.wards = documents.compactMap {
                try? $0.data(as: Ward.self)
            }
        }
    }

}
