//
//  ConstituencyDB.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/24/25.
//
import Foundation
import SQLite3

struct ConstituencyDatabase {
    
    /// Creates all necessary tables for constituency data.
    static func createTables(_ db: OpaquePointer?) {
        execute("""
        CREATE TABLE IF NOT EXISTS Constituencies (
            constituencyNumber INTEGER PRIMARY KEY, constituencyName TEXT NOT NULL, district TEXT,
            assemblyTerm TEXT, lokSabhaConstituency TEXT, reservationStatus TEXT, previousMLA TEXT,
            victoryMargin TEXT, associatedPincodes TEXT
        );
        """, on: db, successMessage: "✅ Constituencies table checked/created.")
        
        execute("""
        CREATE TABLE IF NOT EXISTS MLAs (
            id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE
        );
        """, on: db, successMessage: "✅ MLAs table checked/created.")
        
        execute("""
        CREATE TABLE IF NOT EXISTS TermHistory (
            id TEXT PRIMARY KEY, constituencyNumber INTEGER, mlaId TEXT, politicalParty TEXT,
            electionYear TEXT, victoryMargin TEXT, isCurrent INTEGER,
            FOREIGN KEY (constituencyNumber) REFERENCES Constituencies(constituencyNumber) ON DELETE CASCADE,
            FOREIGN KEY (mlaId) REFERENCES MLAs(id) ON DELETE CASCADE
        );
        """, on: db, successMessage: "✅ TermHistory table checked/created.")
    }

    /// Inserts a complete ConstituencyDetails object into the normalized database tables.
    static func insert(details: ConstituencyDetails, into db: OpaquePointer?) {
        // 1. Insert the main Constituency record
        let constituencySQL = "INSERT OR REPLACE INTO Constituencies (constituencyNumber, constituencyName, district, assemblyTerm, lokSabhaConstituency, reservationStatus, previousMLA, victoryMargin, associatedPincodes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, constituencySQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(details.constituencyNumber)); sqlite3_bind_text(stmt, 2, (details.constituencyName as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 3, (details.district as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 4, (details.assemblyTerm as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 5, (details.lokSabhaConstituency as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 6, (details.reservationStatus as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 7, (details.previousMLA as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 8, (details.victoryMargin as NSString).utf8String, -1, nil); sqlite3_bind_text(stmt, 9, (details.associatedPincodes.joined(separator: ",") as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) != SQLITE_DONE { print("❌ Failed to insert constituency: \(details.constituencyName)") }
        }
        sqlite3_finalize(stmt)
        
        // 2. Insert the Current MLA and their Term
        if let currentMlaId = insertOrGetMla(name: details.currentMLAName, gender: details.gender, into: db) {
            
            insertTerm(constituencyNumber: details.constituencyNumber, mlaId: currentMlaId, party: details.politicalParty, year: details.electionYear, margin: details.victoryMargin, isCurrent: true, into: db)
        }

        // 3. Insert Historical MLAs and their Terms
        if let historyList = details.mlaHistory {
            for history in historyList {
                if let historicalMlaId = insertOrGetMla(name: history.mlaName, gender: "Unknown", into: db) {
                     insertTerm(constituencyNumber: details.constituencyNumber, mlaId: historicalMlaId, party: history.politicalParty, year: history.electionYear, margin: history.victoryMargin, isCurrent: false, into: db)
                }
            }
        }
    }
    
    /// Fetches and reconstructs ConstituencyDetails objects based on a list of pincodes.
    static func fetch(forPincodes pincodes: [String], from db: OpaquePointer?) -> [ConstituencyDetails] {
        guard !pincodes.isEmpty else { return [] }

        var results: [Int: ConstituencyDetails] = [:]
        
        for pincode in pincodes {
            let sql = """
            SELECT C.*, M.name, M.gender, T.politicalParty, T.electionYear, T.victoryMargin, T.isCurrent
            FROM Constituencies C
            JOIN TermHistory T ON C.constituencyNumber = T.constituencyNumber
            JOIN MLAs M ON T.mlaId = M.id
            WHERE C.associatedPincodes LIKE ?;
            """
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, "%\(pincode)%", -1, nil)
                
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let constNumber = Int(sqlite3_column_int(stmt, 0))
                    
                    if results[constNumber] == nil {
                        results[constNumber] = ConstituencyDetails(
                            id: "\(constNumber)",
                            constituencyNumber: constNumber,
                            constituencyName: String(cString: sqlite3_column_text(stmt, 1)),
                            district: String(cString: sqlite3_column_text(stmt, 2)),
                            currentMLAName: "", // Will be set below
                            politicalParty: "", // Will be set below
                            gender: "", // Will be set below
                            electionYear: "", // Will be set below
                            assemblyTerm: String(cString: sqlite3_column_text(stmt, 3)),
                            associatedPincodes: String(cString: sqlite3_column_text(stmt, 8)).components(separatedBy: ","),
                            lokSabhaConstituency: String(cString: sqlite3_column_text(stmt, 4)),
                            reservationStatus: String(cString: sqlite3_column_text(stmt, 5)),
                            previousMLA: String(cString: sqlite3_column_text(stmt, 6)),
                            victoryMargin: String(cString: sqlite3_column_text(stmt, 7)),
                            mlaHistory: []
                        )
                    }
                    
                    let isCurrent = sqlite3_column_int(stmt, 15) == 1
                    let mlaName = String(cString: sqlite3_column_text(stmt, 9))
                    let mlaGender = String(cString: sqlite3_column_text(stmt, 10))
                    let termParty = String(cString: sqlite3_column_text(stmt, 11))
                    let termYear = String(cString: sqlite3_column_text(stmt, 12))
                    let termMargin = String(cString: sqlite3_column_text(stmt, 13))

                    if isCurrent {
                        results[constNumber]?.currentMLAName = mlaName
                        results[constNumber]?.gender = mlaGender
                        results[constNumber]?.politicalParty = termParty
                        results[constNumber]?.electionYear = termYear
                    } else {
                        let history = MLAHistory(electionYear: termYear, mlaName: mlaName, politicalParty: termParty, victoryMargin: termMargin)
                        results[constNumber]?.mlaHistory?.append(history)
                    }
                }
            }
            sqlite3_finalize(stmt)
        }
        
        return Array(results.values).sorted { $0.constituencyNumber < $1.constituencyNumber }
    }
    
    /// Clears all data from the related tables.
    static func deleteAllData(from db: OpaquePointer?) {
        execute("DELETE FROM TermHistory;", on: db, successMessage: "✅ Cleared TermHistory")
        execute("DELETE FROM MLAs;", on: db, successMessage: "✅ Cleared MLAs")
        execute("DELETE FROM Constituencies;", on: db, successMessage: "✅ Cleared Constituencies")
    }
    
    // MARK: - Private Helper Methods
    
    private static func insertOrGetMla(name: String, gender: String, into db: OpaquePointer?) -> String? {
        let selectSql = "SELECT id FROM MLAs WHERE name = ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(stmt, 0))
                sqlite3_finalize(stmt)
                return id
            }
        }
        sqlite3_finalize(stmt)

        let newId = UUID().uuidString
        let insertSql = "INSERT INTO MLAs (id, name, gender) VALUES (?, ?, ?);"
        if sqlite3_prepare_v2(db, insertSql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (newId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (gender as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
                return newId
            }
        }
        sqlite3_finalize(stmt)
        return nil
    }
    
    private static func insertTerm(constituencyNumber: Int, mlaId: String, party: String, year: String, margin: String, isCurrent: Bool, into db: OpaquePointer?) {
        let sql = "INSERT OR IGNORE INTO TermHistory (id, constituencyNumber, mlaId, politicalParty, electionYear, victoryMargin, isCurrent) VALUES (?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (UUID().uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(constituencyNumber))
            sqlite3_bind_text(stmt, 3, (mlaId as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (party as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (year as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (margin as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 7, isCurrent ? 1 : 0)
            if sqlite3_step(stmt) != SQLITE_DONE { print("❌ Failed to insert term history") }
        }
        sqlite3_finalize(stmt)
    }

    private static func execute(_ sql: String, on db: OpaquePointer?, successMessage: String) {
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_DONE { print(successMessage) }
            else { print("❌ Failed to execute statement: \(sql)") }
        } else { print("❌ Error preparing statement: \(sql)") }
        sqlite3_finalize(stmt)
    }
}
