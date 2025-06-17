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
    
    private var locationManager = LocationManager.shared
    private var db = Firestore.firestore()

    init(postalCode: String) {
        self.postalCode = postalCode
    }
    
    // A cancellables set to hold any Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    func fetchData(for postalCode: String) {
        // Fetch data from Firestore based on the postal code
        
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
