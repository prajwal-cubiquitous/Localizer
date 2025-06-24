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
    
    @Published var postalCodes: [String] = []
    
    private var locationManager = LocationManager.shared
    private var db = Firestore.firestore()

    init(postalCodes: [String]) {
        self.postalCodes = postalCodes
    }
    
    // A cancellables set to hold any Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    func fetchData(for postalCodes: [String]) {
        guard !postalCodes.isEmpty else { return }
        
        // Clear existing data
        DispatchQueue.main.async {
            self.schools = []
            self.hospitals = []
            self.policeStations = []
        }
        
        // Fetch data for all provided pincodes
        fetchSchoolsForPincodes(postalCodes)
        fetchHospitalsForPincodes(postalCodes)
        fetchPoliceStationsForPincodes(postalCodes)
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
                    print("✅ Fetched \(schools.count) schools for \(pincodes.count) areas")
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
                    print("✅ Fetched \(hospitals.count) hospitals for \(pincodes.count) areas")
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
                    print("✅ Fetched \(policeStations.count) police stations for \(pincodes.count) areas")
                }
            }
    }
}
