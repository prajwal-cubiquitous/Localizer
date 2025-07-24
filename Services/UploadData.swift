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
    static let dbsqlite = DBManager.shared
    
    // MARK: - Async versions with completion handlers for UI
    
    static func uploadHospitalsAsync() {
        // First delete existing data
        dbsqlite.clearAllHospitals()
        
        // After deletion, proceed with upload
        guard let url = Bundle.main.url(forResource: "Hospital", withExtension: "json") else {
            let error = NSError(domain: "UploadData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hospital.json file not found."])
            print(error.localizedDescription)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let hospitals = try decoder.decode([Hospital].self, from: data)
            
            for hospital in hospitals {
                dbsqlite.insert(hospital: hospital)
                print("Hospital \(hospital.name) uploaded successfully to the sqlite database")
            }
            print("Hospital data uploaded successfully to the sqlite database")
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    static func uploadSchoolsAsync() {
        // First delete existing data
        dbsqlite.clearAllSchools()
        
        // After deletion, proceed with upload
        guard let url = Bundle.main.url(forResource: "school", withExtension: "json") else {
            let error = NSError(domain: "UploadData", code: -1, userInfo: [NSLocalizedDescriptionKey: "school.json file not found."])
            print(error.localizedDescription)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let schools = try decoder.decode([School].self, from: data)
            
            for school in schools {
                dbsqlite.insert(school: school)
                print("School \(school.schoolName) uploaded successfully to the sqlite database")
            }
            print("School data uploaded successfully to the sqlite database")
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func uploadPoliceStationsAsync() {
        // First delete existing data
        dbsqlite.clearAllPoliceStations()
        
        // After deletion, proceed with upload
        guard let url = Bundle.main.url(forResource: "PoliceStation", withExtension: "json") else {
            let error = NSError(domain: "UploadData", code: -1, userInfo: [NSLocalizedDescriptionKey: "PoliceStation.json file not found."])
            print(error.localizedDescription)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let policeStations = try decoder.decode([PoliceStation].self, from: data)
            var successCount = 0
            
            for policeStation in policeStations {
                dbsqlite.insert(station: policeStation)
                print("Police Station \(policeStation.name) uploaded successfully to the sqlite database")
            }
            print("Police Station data uploaded successfully to the sqlite database")
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func uploadConstituencyJSONAsync(completion: @escaping (Result<Int, Error>) -> Void) {
        // First delete existing data
        deleteCollectionIfExists(db: db, collectionName: "constituencies") { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // After deletion, proceed with upload
            guard let url = Bundle.main.url(forResource: "Karnataka_Complete_Constituency_Details", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                let error = NSError(domain: "UploadData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Karnataka_Complete_Constituency_Details.json file not found or unreadable."])
                completion(.failure(error))
                return
            }
            
            do {
                let constituencyArray = try JSONDecoder().decode([ConstituencyDetails].self, from: data)
                let collectionRef = db.collection("constituencies")
                
                let dispatchGroup = DispatchGroup()
                var uploadErrors: [Error] = []
                var successCount = 0
                
                for constituency in constituencyArray {
                    dispatchGroup.enter()
                    let uuid = UUID().uuidString  // Generate UUID
                    
                    var updatedConstituency = constituency
                    updatedConstituency.id = uuid
                    updatedConstituency.documentId = uuid  // Store document ID as field for easy fetching
                    
                    let docRef = collectionRef.document(uuid) // Use UUID as doc ID
                    
                    do {
                        try docRef.setData(from: updatedConstituency) { error in
                            if let error = error {
                                uploadErrors.append(error)
                            } else {
                                successCount += 1
                            }
                            dispatchGroup.leave()
                        }
                    } catch {
                        uploadErrors.append(error)
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    if uploadErrors.isEmpty {
                        completion(.success(successCount))
                    } else {
                        let combinedError = NSError(domain: "UploadData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload \(uploadErrors.count) constituencies"])
                        completion(.failure(combinedError))
                    }
                }
            } catch {
                completion(.failure(error))
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

