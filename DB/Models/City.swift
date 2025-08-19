//
//  City.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 8/14/25.
//
import Foundation

struct City: Codable {
    var id: String
    var name: String
    var constituencyIds: [String]
    var pincodes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case constituencyIds = "constituencyId" // maps Firestore field to struct property
        case pincodes
    }
}

