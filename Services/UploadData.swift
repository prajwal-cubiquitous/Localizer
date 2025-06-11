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

}
