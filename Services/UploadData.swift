//
//  UploadData.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//


import SwiftUI
import FirebaseFirestore

struct UploadData {
    static let db = Firestore.firestore()
    
    static func uploadHospitals() {
        guard let url = Bundle.main.url(forResource: "Hospital", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let hospitals = try decoder.decode([Hospital].self, from: data)
            
            for hospital in hospitals {
                do {
                    _ = try db.collection("hospitals").addDocument(from: hospital)
                } catch {
                }
            }
        } catch {
        }
    }
    
    static func uploadSchools() {
        guard let url = Bundle.main.url(forResource: "school", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let schools = try decoder.decode([School].self, from: data)
            
            for school in schools {
                do {
                    _ = try db.collection("schools").addDocument(from: school)
                } catch {
                }
            }
        } catch {
        }
    }
    
    static func uploadPoliceStations() {
        guard let url = Bundle.main.url(forResource: "PoliceStation", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let policeStations = try decoder.decode([PoliceStation].self, from: data)
            
            for policeStation in policeStations {
                do {
                    // Add each police station document to the "policeStations" collection
                    _ = try db.collection("policeStations").addDocument(from: policeStation)
                } catch {
                }
            }
        } catch {
        }
    }
    
    static func uploadConstituencyJSON() {
        guard let url = Bundle.main.url(forResource: "Constituency_detials", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ JSON file not found or unreadable.")
            return
        }
        do {
            let db = Firestore.firestore()
            let rawArray = try JSONDecoder().decode([RawConstituency].self, from: data)
            let collectionRef = db.collection("constituencies")
            
            for raw in rawArray {
                let uuid = UUID().uuidString  // Generate UUID
                
                let item = ConstituencyDetails(
                    id: uuid,
                    constituencyName: raw.constituencyName,
                    currentMLAName: raw.currentMLAName,
                    politicalParty: raw.politicalParty,
                    associatedPincodes: raw.pincodeString
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                )
                
                let docRef = collectionRef.document(uuid) // Use UUID as doc ID
                
                do {
                    try docRef.setData(from: item)
                } catch {
                    print("❌ Failed to upload item with UUID: \(error)")
                }
            }
            
            print("✅ Uploaded \(rawArray.count) constituencies to Firestore using UUIDs.")
        } catch {
            print("❌ Error decoding JSON: \(error)")
        }
    }
}


func deleteCollectionIfExists(db : Firestore ,collectionName: String, completion: @escaping (Error?) -> Void) {
    let collectionRef = db.collection(collectionName)
    
    collectionRef.getDocuments { snapshot, error in
        if let error = error {
            print("❌ Error fetching documents: \(error.localizedDescription)")
            completion(error)
            return
        }
        
        guard let documents = snapshot?.documents, !documents.isEmpty else {
            print("✅ Collection '\(collectionName)' is empty or does not exist. Skipping deletion.")
            completion(nil)
            return
        }
        
        let batch = db.batch()
        
        for document in documents {
            batch.deleteDocument(document.reference)
        }
        
        batch.commit { batchError in
            if let batchError = batchError {
                print("❌ Error deleting documents in collection: \(batchError.localizedDescription)")
            } else {
                print("✅ Collection '\(collectionName)' deleted successfully.")
            }
            completion(batchError)
        }
    }
}

