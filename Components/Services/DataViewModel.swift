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
    @Published var ConstituencyId: String = ""
    
    private var locationManager = LocationManager.shared
    private var db = Firestore.firestore()

    init(postalCodes: [String], ConstituencyId: String) {
        self.postalCodes = postalCodes
        self.ConstituencyId = ConstituencyId
        fetchFromFirebaseandStoreinSQLite()
    }
    
    let DBsqlite = DBManager.shared
    
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
        DispatchQueue.main.async {
            self.schools = self.DBsqlite.fetchSchools(forPincodes: pincodes)
        }
    }
    
    // Fetch hospitals for multiple pincodes
    private func fetchHospitalsForPincodes(_ pincodes: [String]) {
        DispatchQueue.main.async {
            self.hospitals = self.DBsqlite.fetchHospitals(forPincodes: pincodes)
        }
    }
    
    // Fetch police stations for multiple pincodes
    private func fetchPoliceStationsForPincodes(_ pincodes: [String]) {
        DispatchQueue.main.async {
            self.policeStations = self.DBsqlite.fetchPoliceStations(forPincodes: pincodes)
        }
    }
    
    private func fetchFromFirebaseandStoreinSQLite(){
        UploadData.uploadSchoolsAsync(ConstituencyId: ConstituencyId)
        UploadData.uploadHospitalsAsync(ConstituencyId: ConstituencyId)
        UploadData.uploadPoliceStationsAsync(ConstituencyId: ConstituencyId)
    }
}
