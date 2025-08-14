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
    
    static func uploadHospitalsAsync(ConstituencyId: String) {
        // First delete existing data
        dbsqlite.clearAllHospitals()
        
        db.collection("constituencies").document(ConstituencyId).collection("hospitals").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching hospitals: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No hospital documents found.")
                    return
                }
                
                do {
                    let hospitals: [Hospital] = try documents.compactMap { doc in
                        try doc.data(as: Hospital.self)
                    }
                    
                    for hospital in hospitals {
                        dbsqlite.insert(hospital: hospital)
                        print("Hospital \(hospital.phoneNumber) uploaded successfully to SQLite database")
                    }
                    
                    print("All hospital data uploaded successfully to SQLite database")
                    
                } catch {
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
        
    }
    
    static func uploadSchoolsAsync(ConstituencyId: String) {
        // First delete existing data
        dbsqlite.clearAllSchools()
        
        // After deletion, proceed with upload
        db.collection("constituencies").document(ConstituencyId).collection("schools").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching schools: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No school documents found.")
                return
            }
            
            do {
                // Decode each document into a School model
                let schools: [School] = try documents.compactMap { doc in
                    try doc.data(as: School.self)
                }
                
                // Store each school in local SQLite DB
                for school in schools {
                    dbsqlite.insert(school: school)
                    print("School \(school.schoolName) uploaded successfully to SQLite database")
                }
                
                print("All school data uploaded successfully to SQLite database")
                
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }
    }
    
    static func uploadSchoolsToFirestore() {
        guard let url = Bundle.main.url(forResource: "school", withExtension: "json") else {
            print("❌ school.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let schools = try decoder.decode([School].self, from: data)
            
            let db = Firestore.firestore()
            
            for school in schools {
                // Query constituencies containing this school's pincode
                db.collection("constituencies")
                    .whereField("Associated Pincodes (Compiled, Non-Official)", arrayContains: school.pincode)
                    .getDocuments { (snapshot, error) in
                        
                        if let error = error {
                            print("❌ Error finding constituency for \(school.schoolName): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents, !documents.isEmpty else {
                            print("⚠️ No constituency found for pincode \(school.pincode) - \(school.schoolName)")
                            return
                        }
                        
                        for doc in documents {
                            let constituencyRef = db.collection("constituencies").document(doc.documentID)
                            let schoolRef = constituencyRef.collection("schools").document(school.diseID) // Using DISE ID as doc ID
                            
                            do {
                                try schoolRef.setData(from: school) { error in
                                    if let error = error {
                                        print("❌ Error uploading \(school.schoolName): \(error.localizedDescription)")
                                    } else {
                                        print("✅ Uploaded \(school.schoolName) to constituency \(doc.documentID)")
                                    }
                                }
                            } catch {
                                print("❌ Encoding error for \(school.schoolName): \(error)")
                            }
                        }
                    }
            }
            
        } catch {
            print("❌ Decoding error: \(error.localizedDescription)")
        }
    }
    
    
    static func deleteAllSchoolsDataFromFirebase() {
        let constituenciesRef = db.collection("constituencies")
        
        constituenciesRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching constituencies: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            for constituencyDoc in documents {
                let schoolsRef = constituencyDoc.reference.collection("schools")
                
                schoolsRef.getDocuments { schoolSnapshot, error in
                    if let error = error {
                        print("Error fetching schools for \(constituencyDoc.documentID): \(error)")
                        return
                    }
                    
                    guard let schoolDocs = schoolSnapshot?.documents else { return }
                    
                    let batch = db.batch()
                    
                    for schoolDoc in schoolDocs {
                        batch.deleteDocument(schoolDoc.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            print("Error deleting schools for \(constituencyDoc.documentID): \(error)")
                        } else {
                            print("Deleted all schools for \(constituencyDoc.documentID)")
                        }
                    }
                }
            }
        }
    }
    
    static func uploadPoliceStationsAsync(ConstituencyId: String) {
        // First delete existing data
        dbsqlite.clearAllPoliceStations()
        
        // After deletion, proceed with upload
        db.collection("constituencies").document(ConstituencyId).collection("policeStations").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching police stations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No police station documents found.")
                    return
                }
                
                do {
                    let policeStations: [PoliceStation] = try documents.compactMap { doc in
                        try doc.data(as: PoliceStation.self)
                    }
                    
                    for station in policeStations {
                        dbsqlite.insert(station: station)
                        print("Police Station \(station.name) uploaded successfully to SQLite database")
                    }
                    
                    print("All police station data uploaded successfully to SQLite database")
                    
                } catch {
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
    }
    
    static func uploadPoliceStationsToFirestore() {
        guard let url = Bundle.main.url(forResource: "PoliceStation", withExtension: "json") else {
            print("❌ PoliceStation.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let policeStations = try decoder.decode([PoliceStation].self, from: data)
            
            let db = Firestore.firestore()
            
            for station in policeStations {
                // Find the constituency that matches the pincode
                db.collection("constituencies")
                    .whereField("Associated Pincodes (Compiled, Non-Official)", arrayContains: station.pincode)
                    .getDocuments { (snapshot, error) in
                        
                        if let error = error {
                            print("❌ Error finding constituency for \(station.name): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents, !documents.isEmpty else {
                            print("⚠️ No constituency found for pincode \(station.pincode) - \(station.name)")
                            return
                        }
                        
                        for doc in documents {
                            let constituencyRef = db.collection("constituencies").document(doc.documentID)
                            let stationRef = constituencyRef.collection("policeStations").document(station.id) // or station.name
                            
                            do {
                                try stationRef.setData(from: station) { error in
                                    if let error = error {
                                        print("❌ Error uploading \(station.name): \(error.localizedDescription)")
                                    } else {
                                        print("✅ Uploaded \(station.name) to constituency \(doc.documentID)")
                                    }
                                }
                            } catch {
                                print("❌ Encoding error for \(station.name): \(error)")
                            }
                        }
                    }
            }
            
        } catch {
            print("❌ Decoding error: \(error.localizedDescription)")
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
    
    static func uploadHospitalsToFirestore() {
        guard let url = Bundle.main.url(forResource: "Hospital", withExtension: "json") else {
            print("❌ Hospital.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let hospitals = try decoder.decode([Hospital].self, from: data)
            
            let db = Firestore.firestore()
            
            for hospital in hospitals {
                db.collection("constituencies")
                    .whereField("Associated Pincodes (Compiled, Non-Official)", arrayContains: hospital.pincode)
                    .getDocuments { (snapshot, error) in
                        
                        if let error = error {
                            print("❌ Error finding constituency for \(hospital.name): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents, !documents.isEmpty else {
                            print("⚠️ No constituency found for pincode \(hospital.pincode) - \(hospital.name)")
                            return
                        }
                        
                        for doc in documents {
                            let constituencyRef = db.collection("constituencies").document(doc.documentID)
                            let hospitalRef = constituencyRef.collection("hospitals").document(hospital.id)
                            
                            do {
                                try hospitalRef.setData(from: hospital) { error in
                                    if let error = error {
                                        print("❌ Error uploading \(hospital.name): \(error.localizedDescription)")
                                    } else {
                                        print("✅ Uploaded \(hospital.name) to constituency \(doc.documentID)")
                                    }
                                }
                            } catch {
                                print("❌ Encoding error for \(hospital.name): \(error)")
                            }
                        }
                    }
            }
            
        } catch {
            print("❌ Decoding error: \(error.localizedDescription)")
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

