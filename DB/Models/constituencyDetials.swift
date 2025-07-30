//
//  constituencyDetials.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/16/25.
//

import Foundation
import FirebaseFirestore

struct MLAHistory: Codable {
    var electionYear: String
    var mlaName: String
    var politicalParty: String
    var victoryMargin: String

    // This initializer is added to fix the compile error.
    init(electionYear: String, mlaName: String, politicalParty: String, victoryMargin: String) {
        self.electionYear = electionYear
        self.mlaName = mlaName
        self.politicalParty = politicalParty
        self.victoryMargin = victoryMargin
    }

    enum CodingKeys: String, CodingKey {
        case electionYear = "Election Year"
        case mlaName = "MLA Name"
        case politicalParty = "Political Party"
        case victoryMargin = "Victory Margin"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let year = try? container.decode(String.self, forKey: .electionYear) {
            electionYear = year
        } else if let container2 = try? decoder.container(keyedBy: AlternativeCodingKeys.self), let year = try? container2.decode(String.self, forKey: .year) {
            electionYear = year
        } else { electionYear = "" }
        if let name = try? container.decode(String.self, forKey: .mlaName) {
            mlaName = name
        } else if let container2 = try? decoder.container(keyedBy: AlternativeCodingKeys.self), let name = try? container2.decode(String.self, forKey: .mla) {
            mlaName = name
        } else { mlaName = "" }
        if let party = try? container.decode(String.self, forKey: .politicalParty) {
            politicalParty = party
        } else if let container2 = try? decoder.container(keyedBy: AlternativeCodingKeys.self), let party = try? container2.decode(String.self, forKey: .party) {
            politicalParty = party
        } else { politicalParty = "" }
        if let margin = try? container.decode(String.self, forKey: .victoryMargin) {
            victoryMargin = margin
        } else if let container2 = try? decoder.container(keyedBy: AlternativeCodingKeys.self), let margin = try? container2.decode(String.self, forKey: .margin) {
            victoryMargin = margin
        } else { victoryMargin = "" }
    }

    enum AlternativeCodingKeys: String, CodingKey {
        case year = "Year", mla = "MLA", party = "Party", margin = "Margin"
    }
}

struct ConstituencyDetails: Codable, Identifiable {
    var id: String?  // Firestore doc ID
    var documentId: String?  // Firestore document ID stored as field
    var constituencyNumber: Int
    var constituencyName: String
    var district: String
    var currentMLAName: String
    var politicalParty: String
    var gender: String
    var electionYear: String
    var assemblyTerm: String
    var associatedPincodes: [String]
    var lokSabhaConstituency: String
    var reservationStatus: String
    var previousMLA: String
    var victoryMargin: String
    var mlaHistory: [MLAHistory]?
    
    // Standard memberwise initializer
    init(id: String? = nil, documentId: String? = nil, constituencyNumber: Int, constituencyName: String, district: String, currentMLAName: String, politicalParty: String, gender: String, electionYear: String, assemblyTerm: String, associatedPincodes: [String], lokSabhaConstituency: String, reservationStatus: String, previousMLA: String, victoryMargin: String, mlaHistory: [MLAHistory]? = nil) {
        self.id = id
        self.documentId = documentId
        self.constituencyNumber = constituencyNumber
        self.constituencyName = constituencyName
        self.district = district
        self.currentMLAName = currentMLAName
        self.politicalParty = politicalParty
        self.gender = gender
        self.electionYear = electionYear
        self.assemblyTerm = assemblyTerm
        self.associatedPincodes = associatedPincodes
        self.lokSabhaConstituency = lokSabhaConstituency
        self.reservationStatus = reservationStatus
        self.previousMLA = previousMLA
        self.victoryMargin = victoryMargin
        self.mlaHistory = mlaHistory
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case documentId = "documentId"
        case constituencyNumber = "Constituency Number"
        case constituencyName = "Constituency Name"
        case district = "District"
        case currentMLAName = "Current MLA Name"
        case politicalParty = "Political Party"
        case gender = "Gender"
        case electionYear = "Election Year"
        case assemblyTerm = "Assembly Term"
        case associatedPincodes = "Associated Pincodes (Compiled, Non-Official)"
        case lokSabhaConstituency = "Lok Sabha Constituency"
        case reservationStatus = "Reservation Status"
        case previousMLA = "Previous MLA"
        case victoryMargin = "Victory Margin"
        case mlaHistory = "MLA History"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle optional fields that might not exist in JSON
        id = try? container.decode(String.self, forKey: .id)
        documentId = try? container.decode(String.self, forKey: .documentId)
        
        constituencyNumber = try container.decode(Int.self, forKey: .constituencyNumber)
        constituencyName = try container.decode(String.self, forKey: .constituencyName)
        district = try container.decode(String.self, forKey: .district)
        currentMLAName = try container.decode(String.self, forKey: .currentMLAName)
        politicalParty = try container.decode(String.self, forKey: .politicalParty)
        gender = try container.decode(String.self, forKey: .gender)
        electionYear = try container.decode(String.self, forKey: .electionYear)
        assemblyTerm = try container.decode(String.self, forKey: .assemblyTerm)
        lokSabhaConstituency = try container.decode(String.self, forKey: .lokSabhaConstituency)
        reservationStatus = try container.decode(String.self, forKey: .reservationStatus)
        previousMLA = try container.decode(String.self, forKey: .previousMLA)
        victoryMargin = try container.decode(String.self, forKey: .victoryMargin)
        mlaHistory = try? container.decode([MLAHistory].self, forKey: .mlaHistory)
        
        // Handle pincodes - can be string or array
        if let pincodesString = try? container.decode(String.self, forKey: .associatedPincodes) {
            associatedPincodes = pincodesString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        } else if let pincodesArray = try? container.decode([String].self, forKey: .associatedPincodes) {
            associatedPincodes = pincodesArray
        } else {
            associatedPincodes = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields including id and documentId
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(documentId, forKey: .documentId)
        try container.encode(constituencyNumber, forKey: .constituencyNumber)
        try container.encode(constituencyName, forKey: .constituencyName)
        try container.encode(district, forKey: .district)
        try container.encode(currentMLAName, forKey: .currentMLAName)
        try container.encode(politicalParty, forKey: .politicalParty)
        try container.encode(gender, forKey: .gender)
        try container.encode(electionYear, forKey: .electionYear)
        try container.encode(assemblyTerm, forKey: .assemblyTerm)
        try container.encode(associatedPincodes, forKey: .associatedPincodes)
        try container.encode(lokSabhaConstituency, forKey: .lokSabhaConstituency)
        try container.encode(reservationStatus, forKey: .reservationStatus)
        try container.encode(previousMLA, forKey: .previousMLA)
        try container.encode(victoryMargin, forKey: .victoryMargin)
        try container.encodeIfPresent(mlaHistory, forKey: .mlaHistory)
    }
}

struct RawConstituency: Codable {
    enum CodingKeys: String, CodingKey {
        case constituencyName = "Constituency Name"
        case currentMLAName = "Current MLA Name"
        case politicalParty = "Political Party"
        case pincodeString = "Associated Pincodes (Compiled, Non-Official)"
    }

    let constituencyName: String
    let currentMLAName: String
    let politicalParty: String
    let pincodeString: String
}


struct DummyConstituencyDetials{
     static var detials1 = ConstituencyDetails(
        constituencyNumber: 1,
        constituencyName: "Adilabad",
        district: "Adilabad",
        currentMLAName: "Nandini",
        politicalParty: "BJP",
        gender: "Female",
        electionYear: "2023",
        assemblyTerm: "16th Karnataka Assembly",
        associatedPincodes: ["500001", "500002"],
        lokSabhaConstituency: "Adilabad",
        reservationStatus: "General",
        previousMLA: "Previous MLA",
        victoryMargin: "Won"
    )
}
