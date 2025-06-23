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
        // First delete existing data
        deleteCollectionIfExists(db: db, collectionName: "hospitals") { error in
            if let error = error {
                print("❌ Error deleting existing hospital data: \(error)")
                return
            }
            
            // After deletion, proceed with upload
            guard let url = Bundle.main.url(forResource: "Hospital", withExtension: "json") else {
                print("❌ Hospital.json file not found.")
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let hospitals = try decoder.decode([Hospital].self, from: data)
                
                for hospital in hospitals {
                    do {
                        _ = try db.collection("hospitals").addDocument(from: hospital)
                        print("✅ Uploaded hospital: \(hospital.name)")
                    } catch {
                        print("❌ Failed to upload hospital \(hospital.name): \(error)")
                    }
                }
                print("✅ Uploaded \(hospitals.count) hospitals to Firestore.")
            } catch {
                print("❌ Error decoding Hospital.json: \(error)")
            }
        }
    }
    
    static func uploadSchools() {
        // First delete existing data
        deleteCollectionIfExists(db: db, collectionName: "schools") { error in
            if let error = error {
                print("❌ Error deleting existing school data: \(error)")
                return
            }
            
            // After deletion, proceed with upload
            guard let url = Bundle.main.url(forResource: "school", withExtension: "json") else {
                print("❌ school.json file not found.")
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let schools = try decoder.decode([School].self, from: data)
                
                for school in schools {
                    do {
                        _ = try db.collection("schools").addDocument(from: school)
                        print("✅ Uploaded school: \(school.schoolName)")
                    } catch {
                        print("❌ Failed to upload school \(school.schoolName): \(error)")
                    }
                }
                print("✅ Uploaded \(schools.count) schools to Firestore.")
            } catch {
                print("❌ Error decoding school.json: \(error)")
            }
        }
    }
    
    static func uploadPoliceStations() {
        // First delete existing data
        deleteCollectionIfExists(db: db, collectionName: "policeStations") { error in
            if let error = error {
                print("❌ Error deleting existing police station data: \(error)")
                return
            }
            
            // After deletion, proceed with upload
            guard let url = Bundle.main.url(forResource: "PoliceStation", withExtension: "json") else {
                print("❌ PoliceStation.json file not found.")
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
                        print("✅ Uploaded police station: \(policeStation.name)")
                    } catch {
                        print("❌ Failed to upload police station \(policeStation.name): \(error)")
                    }
                }
                print("✅ Uploaded \(policeStations.count) police stations to Firestore.")
            } catch {
                print("❌ Error decoding PoliceStation.json: \(error)")
            }
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

