
import Foundation
import SQLite3

class DBManager {
    static let shared = DBManager()
    private var db: OpaquePointer?

    private init() {
        self.db = openDatabase()
        
        // Create all tables when the manager is initialized
        HospitalDatabase.createTable(self.db)
        SchoolDatabase.createTable(self.db)
        PoliceStationDatabase.createTable(self.db)
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
        // Using a more generic name for the database file
        let dbPath = documentsDirectory.appendingPathComponent("local_data.sqlite").path

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
    
    // --- Public Hospital Interface ---

    func insert(hospital: Hospital) {
        HospitalDatabase.insert(hospital, into: self.db)
    }

    func fetchHospitals(forPincodes pincodes: [String]) -> [Hospital] {
        return HospitalDatabase.fetch(from: self.db, forPincodes: pincodes)
    }
    
    func clearAllHospitals() {
        HospitalDatabase.deleteAllRows(from: self.db)
    }
    
    // --- Public School Interface ---
    
    func insert(school: School) {
        SchoolDatabase.insert(school, into: self.db)
    }
    
    func fetchSchools(forPincodes pincodes: [String]) -> [School] {
        return SchoolDatabase.fetch(from: self.db, forPincodes: pincodes)
    }
    
    func clearAllSchools() {
        SchoolDatabase.deleteAllRows(from: self.db)
    }
    
    // --- Public Police Station Interface ---
    
    func insert(station: PoliceStation) {
        PoliceStationDatabase.insert(station, into: self.db)
    }
    
    func fetchPoliceStations(forPincodes pincodes: [String]) -> [PoliceStation] {
        return PoliceStationDatabase.fetch(from: self.db, forPincodes: pincodes)
    }
    
    func clearAllPoliceStations() {
        PoliceStationDatabase.deleteAllRows(from: self.db)
    }
}


//// --- HOW TO USE IT ---
//
//// Initialize the manager (this opens the DB and creates all tables)
//let dbManager = DBManager.shared
//
//// Clear previous data (optional, useful for testing)
//dbManager.clearAllHospitals()
//dbManager.clearAllSchools()
//dbManager.clearAllPoliceStations()
//
//// --- Work with Hospitals ---
//print("\n--- Hospital Operations ---")
//let hospital1 = Hospital(constituency: "South", name: "General Hospital", fullAddress: "1 Main St", pincode: "560001", phoneNumber: "555-1111", googleMapLink: "http://maps.google.com/1")
//dbManager.insert(hospital: hospital1)
//let fetchedHospitals = dbManager.fetchHospitals(forPincodes: ["560001", "560004"])
//print("Found \(fetchedHospitals.count) hospital(s).")
//
//
//// --- Work with Schools ---
//print("\n--- School Operations ---")
//let school1 = School(diseID: "D123", schoolName: "Public School One", management: "Govt", medium: "English", category: "Primary", sex: "Co-Ed", cluster: "C1", block: "B1", district: "Metro", schoolType: "Urban", assembly: "A1", parliament: "P1", pincode: "560001", address: "1 School Ln", landmark: "Near Park", busNumber: "101", coordinates: "12.9, 77.5")
//dbManager.insert(school: school1)
//let fetchedSchools = dbManager.fetchSchools(forPincodes: ["560001"])
//print("Found \(fetchedSchools.count) school(s).")
//
//
//// --- Work with Police Stations ---
//print("\n--- Police Station Operations ---")
//let station1 = PoliceStation(constituency: "Central", name: "Central Precinct", fullAddress: "100 Police Plaza", pincode: "560002", phoneNumber: "555-0100", googleMapLink: "http://maps.google.com/ps1", division: "Metro", subDivision: "Downtown")
//dbManager.insert(station: station1)
//let fetchedStations = dbManager.fetchPoliceStations(forPincodes: ["560002"])
//print("Found \(fetchedStations.count) police station(s).")
//if let firstStation = fetchedStations.first {
//    print("Station Name: \(firstStation.name), Division: \(firstStation.division)")
//}
