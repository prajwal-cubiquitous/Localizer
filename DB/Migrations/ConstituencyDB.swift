//
//  ConstituencyDB.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/24/25.
//
//import Foundation
//import SQLite3
//
//struct ConstituencyDB {
//    static func createTable(_ db: OpaquePointer?) {
//        let sql = """
//        CREATE TABLE IF NOT EXISTS Constituencies (
//            constituencyNumber INTEGER PRIMARY KEY,
//            constituencyName TEXT NOT NULL,
//            district TEXT,
//            assemblyTerm TEXT,
//            lokSabhaConstituency TEXT,
//            reservationStatus TEXT,
//            previousMLA TEXT,
//            victoryMargin TEXT,
//            associatedPincodes TEXT
//        );
//        """
//        execute(sql, on: db, successMessage: "✅ Constituencies table checked/created.")
//    }
//
//    static func insert(from details: ConstituencyDetails, into db: OpaquePointer?) {
//        let sql = "INSERT OR REPLACE INTO Constituencies (constituencyNumber, constituencyName, district, assemblyTerm, lokSabhaConstituency, reservationStatus, previousMLA, victoryMargin, associatedPincodes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
//        var statement: OpaquePointer?
//        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
//            sqlite3_bind_int(statement, 1, Int32(details.constituencyNumber))
//            sqlite3_bind_text(statement, 2, (details.constituencyName as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 3, (details.district as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 4, (details.assemblyTerm as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 5, (details.lokSabhaConstituency as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 6, (details.reservationStatus as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 7, (details.previousMLA as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 8, (details.victoryMargin as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 9, (details.associatedPincodes.joined(separator: ",") as NSString).utf8String, -1, nil)
//            
//            if sqlite3_step(statement) != SQLITE_DONE {
//                 print("❌ Failed to insert constituency: \(details.constituencyName)")
//            }
//        }
//        sqlite3_finalize(statement)
//    }
//}
//
//struct MlaDB {
//    static func createTable(_ db: OpaquePointer?) {
//        let sql = """
//        CREATE TABLE IF NOT EXISTS MLAs (
//            id TEXT PRIMARY KEY,
//            name TEXT NOT NULL UNIQUE,
//            gender TEXT
//        );
//        """
//        execute(sql, on: db, successMessage: "✅ MLAs table checked/created.")
//    }
//
//    static func insertOrGet(name: String, gender: String, into db: OpaquePointer?) -> String? {
//        let selectSql = "SELECT id FROM MLAs WHERE name = ?;"
//        var statement: OpaquePointer?
//        var mlaId: String?
//
//        if sqlite3_prepare_v2(db, selectSql, -1, &statement, nil) == SQLITE_OK {
//            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
//            if sqlite3_step(statement) == SQLITE_ROW {
//                mlaId = String(cString: sqlite3_column_text(statement, 0))
//            }
//        }
//        sqlite3_finalize(statement)
//
//        if let mlaId = mlaId { return mlaId }
//
//        let newId = UUID().uuidString
//        let insertSql = "INSERT INTO MLAs (id, name, gender) VALUES (?, ?, ?);"
//        if sqlite3_prepare_v2(db, insertSql, -1, &statement, nil) == SQLITE_OK {
//            sqlite3_bind_text(statement, 1, (newId as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 2, (name as NSString).utf8String, -1, nil)
//            sqlite3_bind_text(statement, 3, (gender as NSString).utf8String, -1, nil)
//            if sqlite3_step(statement) == SQLITE_DONE {
//                sqlite3_finalize(statement)
//                return newId
//            }
//        }
//        sqlite3_finalize(statement)
//        return nil
//    }
//}
