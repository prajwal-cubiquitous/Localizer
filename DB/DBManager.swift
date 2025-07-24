//
//  DBManager.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/24/25.
//


import Foundation
import SQLite3

class DBManager {
    static let shared = DBManager()
    private var db: OpaquePointer?

    private init() {
        self.db = openDatabase()
        HospitalDatabase.createTable(self.db)
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
            print("✅ Database connection closed.")
        }
    }

    private func openDatabase() -> OpaquePointer? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not determine documents directory.")
            return nil
        }
        let dbPath = documentsDirectory.appendingPathComponent("hospital_database.sqlite").path

        var db: OpaquePointer?
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("✅ Successfully opened connection to database at \(dbPath)")
            return db
        } else {
            print("❌ Unable to open database.")
            if let errorPointer = sqlite3_errmsg(db) {
                print("Error details: \(String(cString: errorPointer))")
            }
            return nil
        }
    }
    
    // --- Public Interface for Database Operations ---

    /// Inserts a hospital into the database.
    func insert(hospital: Hospital) {
        HospitalDatabase.insert(hospital, into: self.db)
    }

    /// Fetches hospitals for a given pincode.
    func fetchHospitals(pincode: String) -> [Hospital] {
        return HospitalDatabase.fetch(from: self.db, pincode: pincode)
    }
}








// --- HOW TO USE IT ---
//
//// Initialize the manager (this opens the DB and creates the table)
//let dbManager = DBManager.shared
//
//// Now use the simplified interface:
//let newHospital = Hospital(constituency: "Central", name: "City General", fullAddress: "123 Main St", pincode: "12345", phoneNumber: "555-1234", googleMapLink: "http://maps.google.com")
//dbManager.insert(hospital: newHospital)
//
//let fetchedHospitals = dbManager.fetchHospitals(pincode: "12345")
//print("Found \(fetchedHospitals.count) hospitals.")
