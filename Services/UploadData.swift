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
        let db = Firestore.firestore()
        
        // First delete existing data
        deleteCollectionIfExists(db: db, collectionName: "constituencies") { error in
            if let error = error {
                print("❌ Error deleting existing constituency data: \(error)")
                return
            }
            
            // After deletion, proceed with upload
            guard let url = Bundle.main.url(forResource: "Karnataka_Complete_Constituency_Details", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                print("❌ Karnataka_Complete_Constituency_Details.json file not found or unreadable.")
                return
            }
            
            do {
                let constituencyArray = try JSONDecoder().decode([ConstituencyDetails].self, from: data)
                let collectionRef = db.collection("constituencies")
                
                for constituency in constituencyArray {
                    let uuid = UUID().uuidString  // Generate UUID
                    
                    var updatedConstituency = constituency
                    updatedConstituency.id = uuid
                    updatedConstituency.documentId = uuid  // Store document ID as field for easy fetching
                    
                    let docRef = collectionRef.document(uuid) // Use UUID as doc ID
                    
                    do {
                        try docRef.setData(from: updatedConstituency)
                        print("✅ Uploaded constituency: \(constituency.constituencyName) with ID: \(uuid)")
                    } catch {
                        print("❌ Failed to upload constituency \(constituency.constituencyName): \(error)")
                    }
                }
                
                print("✅ Uploaded \(constituencyArray.count) constituencies to Firestore using UUIDs.")
            } catch {
                print("❌ Error decoding Karnataka_Complete_Constituency_Details.json: \(error)")
            }
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

