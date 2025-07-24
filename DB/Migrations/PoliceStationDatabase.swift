//
//  PoliceStationDatabase.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/24/25.
//
import Foundation
import SQLite3

struct PoliceStationDatabase {
    static func createTable(_ db: OpaquePointer?) {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS PoliceStations (
            id TEXT PRIMARY KEY, constituency TEXT, name TEXT, fullAddress TEXT,
            pincode TEXT, phoneNumber TEXT, googleMapLink TEXT, division TEXT, subDivision TEXT
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ PoliceStations table checked/created.")
            } else { print("❌ Failed to create PoliceStations table.") }
        } else { print("❌ Error preparing CREATE TABLE statement for PoliceStations.") }
        sqlite3_finalize(statement)
    }

    static func insert(_ station: PoliceStation, into db: OpaquePointer?) {
        let insertSQL = """
        INSERT INTO PoliceStations (id, constituency, name, fullAddress, pincode, phoneNumber,
        googleMapLink, division, subDivision) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (station.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (station.constituency as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (station.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (station.fullAddress as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (station.pincode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (station.phoneNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (station.googleMapLink as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (station.division as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (station.subDivision as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("❌ Failed to insert police station: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else { print("❌ Error preparing INSERT statement for PoliceStation.") }
        sqlite3_finalize(statement)
    }

    static func fetch(from db: OpaquePointer?, forPincodes pincodes: [String]) -> [PoliceStation] {
        guard !pincodes.isEmpty else { return [] }
        let placeholders = Array(repeating: "?", count: pincodes.count).joined(separator: ",")
        let selectSQL = "SELECT * FROM PoliceStations WHERE pincode IN (\(placeholders)) ORDER BY name ASC;"
        var statement: OpaquePointer?
        var stations: [PoliceStation] = []
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            for (index, pincode) in pincodes.enumerated() {
                sqlite3_bind_text(statement, Int32(index + 1), (pincode as NSString).utf8String, -1, nil)
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                let station = PoliceStation(
                    id: String(cString: sqlite3_column_text(statement, 0)),
                    constituency: String(cString: sqlite3_column_text(statement, 1)),
                    name: String(cString: sqlite3_column_text(statement, 2)),
                    fullAddress: String(cString: sqlite3_column_text(statement, 3)),
                    pincode: String(cString: sqlite3_column_text(statement, 4)),
                    phoneNumber: String(cString: sqlite3_column_text(statement, 5)),
                    googleMapLink: String(cString: sqlite3_column_text(statement, 6)),
                    division: String(cString: sqlite3_column_text(statement, 7)),
                    subDivision: String(cString: sqlite3_column_text(statement, 8))
                )
                stations.append(station)
            }
        } else { print("❌ Failed to prepare fetch statement for PoliceStations.") }
        sqlite3_finalize(statement)
        return stations
    }
    
    static func deleteAllRows(from db: OpaquePointer?) {
        let deleteSQL = "DELETE FROM PoliceStations;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("❌ Failed to delete rows from PoliceStations: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
}
