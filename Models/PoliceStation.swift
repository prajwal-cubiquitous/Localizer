//
//  PoliceStation.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import Foundation

struct PoliceStation: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    let constituency: String
    let name: String
    let fullAddress: String
    let pincode: String
    let phoneNumber: String
    let googleMapLink: String
    let division: String
    let subDivision: String

    enum CodingKeys: String, CodingKey {
        case constituency = "Constituency"
        case name = "Name"
        case fullAddress = "Full address "
        case pincode = "Pincode"
        case phoneNumber = "Phone Number"
        case googleMapLink = "Google Map Link"
        case division = "Division"
        case subDivision = "Sub-Division"
    }
}
