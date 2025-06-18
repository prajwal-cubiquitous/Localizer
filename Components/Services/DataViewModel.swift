//
//  DataViewModel.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine


class DataViewModel: ObservableObject {
    @Published var schools: [School] = []
    @Published var hospitals: [Hospital] = []
    @Published var policeStations: [PoliceStation] = []
    
    @Published var postalCode: String = "Fetching..."
    @Published var constituencyInfo: ConstituencyDetails?
    
    private var locationManager = LocationManager.shared
    private var db = Firestore.firestore()

    init(postalCode: String) {
        self.postalCode = postalCode
    }
    
    // A cancellables set to hold any Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    func fetchData(for postalCode: String) {
        // First, find the constituency that contains this pincode
        findConstituencyForPincode(postalCode) { [weak self] constituency in
            guard let self = self, let constituency = constituency else {
                // Fallback to single pincode if constituency not found
                self?.fetchDataForSinglePincode(postalCode)
                return
            }
            
            self.constituencyInfo = constituency
            
            // Fetch data for all pincodes in the constituency
            self.fetchDataForMultiplePincodes(constituency.associatedPincodes)
        }
    }
    
    // Find constituency that contains the given pincode
    private func findConstituencyForPincode(_ pincode: String, completion: @escaping (ConstituencyDetails?) -> Void) {
        db.collection("constituencies")
            .whereField("associatedPincodes", arrayContains: pincode)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("❌ Error finding constituency: \(error)")
                    completion(nil)
                    return
                }
                
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    print("⚠️ No constituency found for pincode: \(pincode)")
                    completion(nil)
                    return
                }
                
                // Get the first matching constituency
                if let constituency = try? documents.first?.data(as: ConstituencyDetails.self) {
                    print("✅ Found constituency: \(constituency.constituencyName) with \(constituency.associatedPincodes.count) pincodes")
                    completion(constituency)
                } else {
                    completion(nil)
                }
            }
    }
    
    // Fetch data for multiple pincodes (constituency-wide)
    private func fetchDataForMultiplePincodes(_ pincodes: [String]) {
        guard !pincodes.isEmpty else { return }
        
        // Clear existing data
        DispatchQueue.main.async {
            self.schools = []
            self.hospitals = []
            self.policeStations = []
        }
        
        // Fetch schools for all pincodes in the constituency
        fetchSchoolsForPincodes(pincodes)
        
        // Fetch hospitals for all pincodes in the constituency
        fetchHospitalsForPincodes(pincodes)
        
        // Fetch police stations for all pincodes in the constituency
        fetchPoliceStationsForPincodes(pincodes)
    }
    
    // Fetch schools for multiple pincodes
    private func fetchSchoolsForPincodes(_ pincodes: [String]) {
        db.collection("schools")
            .whereField("Pincode", in: pincodes)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("❌ Error fetching schools: \(error)")
                    return
                }
                
                let schools = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: School.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.schools = schools
                    print("✅ Fetched \(schools.count) schools for constituency")
                }
            }
    }
    
    // Fetch hospitals for multiple pincodes
    private func fetchHospitalsForPincodes(_ pincodes: [String]) {
        db.collection("hospitals")
            .whereField("Pincode", in: pincodes)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("❌ Error fetching hospitals: \(error)")
                    return
                }
                
                let hospitals = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Hospital.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.hospitals = hospitals
                    print("✅ Fetched \(hospitals.count) hospitals for constituency")
                }
            }
    }
    
    // Fetch police stations for multiple pincodes
    private func fetchPoliceStationsForPincodes(_ pincodes: [String]) {
        db.collection("policeStations")
            .whereField("Pincode", in: pincodes)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("❌ Error fetching police stations: \(error)")
                    return
                }
                
                let policeStations = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: PoliceStation.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.policeStations = policeStations
                    print("✅ Fetched \(policeStations.count) police stations for constituency")
                }
            }
    }
    
    // Fallback method for single pincode (if constituency not found)
    private func fetchDataForSinglePincode(_ postalCode: String) {
        print("🔄 Falling back to single pincode fetch for: \(postalCode)")
        
        // Fetch schools matching the postal code
        db.collection("schools")
            .whereField("Pincode", isEqualTo: postalCode)
            .getDocuments { [weak self] (querySnapshot, error) in
                if error != nil {
                    return
                }
                
                self?.schools = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: School.self)
                } ?? []
            }
        
        // Fetch hospitals matching the postal code
        db.collection("hospitals")
            .whereField("Pincode", isEqualTo: postalCode)
            .getDocuments { [weak self] (querySnapshot, error) in
                if error != nil {
                    return
                }
                
                self?.hospitals = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Hospital.self)
                } ?? []
            }
        
        // Fetch police stations matching the postal code
        db.collection("policeStations")
            .whereField("Pincode", isEqualTo: postalCode)
            .getDocuments { [weak self] (querySnapshot, error) in
                if error != nil {
                    return
                }
                
                self?.policeStations = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: PoliceStation.self)
                } ?? []
            }
    }
}
