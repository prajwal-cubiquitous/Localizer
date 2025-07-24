//
//  HoapitalDataBase.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/24/25.
//

import Foundation
import SQLite3

// Your existing struct for handling SQL operations
struct HospitalDatabase {
    static func createTable(_ db: OpaquePointer?) {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS Hospitals (
            id TEXT PRIMARY KEY,
            constituency TEXT NOT NULL,
            name TEXT NOT NULL,
            fullAddress TEXT,
            pincode TEXT,
            phoneNumber TEXT,
            googleMapLink TEXT
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Hospitals table checked/created by HospitalDatabase.")
            } else {
                print("❌ Failed to create Hospitals table.")
            }
        } else {
            print("❌ Error preparing CREATE TABLE statement.")
        }
        sqlite3_finalize(statement)
    }

    static func insert(_ hospital: Hospital, into db: OpaquePointer?) {
        let insertSQL = "INSERT INTO Hospitals (id, constituency, name, fullAddress, pincode, phoneNumber, googleMapLink) VALUES (?, ?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (hospital.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (hospital.constituency as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (hospital.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (hospital.fullAddress as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (hospital.pincode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (hospital.phoneNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (hospital.googleMapLink as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Hospital inserted successfully.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to insert hospital: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Error preparing INSERT statement: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }

    // Add this function inside your HospitalDatabase struct
    static func fetch(from db: OpaquePointer?, forPincodes pincodes: [String]) -> [Hospital] {
        // 1. Handle the edge case of an empty pincode list to prevent an SQL error.
        guard !pincodes.isEmpty else {
            return []
        }

        // 2. Create the correct number of '?' placeholders for the IN clause.
        //    Example: ["123", "456"] -> "?,?"
        let placeholders = Array(repeating: "?", count: pincodes.count).joined(separator: ",")
        print("pin codes: \(placeholders)")
        // 3. Construct the final SQL query.
        let selectSQL = "SELECT * FROM Hospitals WHERE pincode IN (\(placeholders)) ORDER BY name ASC;"
        
        var statement: OpaquePointer?
        var hospitals: [Hospital] = []

        // 4. Prepare the statement.
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            
            // 5. Bind each pincode in the array to its corresponding placeholder.
            for (index, pincode) in pincodes.enumerated() {
                // SQLite bind indexes are 1-based.
                sqlite3_bind_text(statement, Int32(index + 1), (pincode as NSString).utf8String, -1, nil)
            }
            
            // 6. Loop through the results.
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let constituency = String(cString: sqlite3_column_text(statement, 1))
                let name = String(cString: sqlite3_column_text(statement, 2))
                let fullAddress = String(cString: sqlite3_column_text(statement, 3))
                let pincodeResult = String(cString: sqlite3_column_text(statement, 4))
                let phoneNumber = String(cString: sqlite3_column_text(statement, 5))
                let googleMapLink = String(cString: sqlite3_column_text(statement, 6))

                let hospital = Hospital(id: id, constituency: constituency, name: name,
                                        fullAddress: fullAddress, pincode: pincodeResult,
                                        phoneNumber: phoneNumber, googleMapLink: googleMapLink)
                hospitals.append(hospital)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare fetch statement for multiple pincodes: \(errorMessage)")
        }

        // 7. Clean up.
        sqlite3_finalize(statement)
        return hospitals
    }
    static func deleteTable(_ db: OpaquePointer?) {
        let deleteTableSQL = "DROP TABLE IF EXISTS Hospitals;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteTableSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Hospitals table deleted successfully.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to delete Hospitals table: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Error preparing DROP TABLE statement: \(errorMessage)")
        }

        sqlite3_finalize(statement)
    }
    
    static func deleteAllRows(from db: OpaquePointer?) {
        let deleteSQL = "DELETE FROM Hospitals;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ All rows deleted from Hospitals table.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to delete rows: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Error preparing DELETE statement: \(errorMessage)")
        }

        sqlite3_finalize(statement)
    }
}
