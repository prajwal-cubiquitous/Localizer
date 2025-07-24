//
//  SchoolDatabase.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/24/25.
//
import Foundation
import SQLite3

struct SchoolDatabase {
    static func createTable(_ db: OpaquePointer?) {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS Schools (
            id TEXT PRIMARY KEY, diseID TEXT, schoolName TEXT, management TEXT, medium TEXT,
            category TEXT, sex TEXT, cluster TEXT, block TEXT, district TEXT, schoolType TEXT,
            assembly TEXT, parliament TEXT, pincode TEXT, address TEXT, landmark TEXT,
            busNumber TEXT, coordinates TEXT
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Schools table checked/created.")
            } else { print("❌ Failed to create Schools table.") }
        } else { print("❌ Error preparing CREATE TABLE statement for Schools.") }
        sqlite3_finalize(statement)
    }

    static func insert(_ school: School, into db: OpaquePointer?) {
        let insertSQL = """
        INSERT INTO Schools (id, diseID, schoolName, management, medium, category, sex, cluster,
        block, district, schoolType, assembly, parliament, pincode, address, landmark, busNumber, coordinates)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (school.id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (school.diseID as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (school.schoolName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (school.management as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (school.medium as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (school.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 7, (school.sex as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 8, (school.cluster as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 9, (school.block as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 10, (school.district as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 11, (school.schoolType as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 12, (school.assembly as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 13, (school.parliament as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 14, (school.pincode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 15, (school.address as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 16, (school.landmark as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 17, (school.busNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 18, (school.coordinates as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("❌ Failed to insert school: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else { print("❌ Error preparing INSERT statement for School.") }
        sqlite3_finalize(statement)
    }

    static func fetch(from db: OpaquePointer?, forPincodes pincodes: [String]) -> [School] {
        guard !pincodes.isEmpty else { return [] }
        let placeholders = Array(repeating: "?", count: pincodes.count).joined(separator: ",")
        let selectSQL = "SELECT * FROM Schools WHERE pincode IN (\(placeholders)) ORDER BY schoolName ASC;"
        var statement: OpaquePointer?
        var schools: [School] = []
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            for (index, pincode) in pincodes.enumerated() {
                sqlite3_bind_text(statement, Int32(index + 1), (pincode as NSString).utf8String, -1, nil)
            }
            while sqlite3_step(statement) == SQLITE_ROW {
                let school = School(
                    id: String(cString: sqlite3_column_text(statement, 0)),
                    diseID: String(cString: sqlite3_column_text(statement, 1)),
                    schoolName: String(cString: sqlite3_column_text(statement, 2)),
                    management: String(cString: sqlite3_column_text(statement, 3)),
                    medium: String(cString: sqlite3_column_text(statement, 4)),
                    category: String(cString: sqlite3_column_text(statement, 5)),
                    sex: String(cString: sqlite3_column_text(statement, 6)),
                    cluster: String(cString: sqlite3_column_text(statement, 7)),
                    block: String(cString: sqlite3_column_text(statement, 8)),
                    district: String(cString: sqlite3_column_text(statement, 9)),
                    schoolType: String(cString: sqlite3_column_text(statement, 10)),
                    assembly: String(cString: sqlite3_column_text(statement, 11)),
                    parliament: String(cString: sqlite3_column_text(statement, 12)),
                    pincode: String(cString: sqlite3_column_text(statement, 13)),
                    address: String(cString: sqlite3_column_text(statement, 14)),
                    landmark: String(cString: sqlite3_column_text(statement, 15)),
                    busNumber: String(cString: sqlite3_column_text(statement, 16)),
                    coordinates: String(cString: sqlite3_column_text(statement, 17))
                )
                schools.append(school)
            }
        } else { print("❌ Failed to prepare fetch statement for Schools.") }
        sqlite3_finalize(statement)
        return schools
    }
    
    static func deleteAllRows(from db: OpaquePointer?) {
        let deleteSQL = "DELETE FROM Schools;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("❌ Failed to delete rows from Schools: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
}
