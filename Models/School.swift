//
//  School.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import Foundation

struct School: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    let diseID: String
    let schoolName: String
    let management: String
    let medium: String
    let category: String
    let sex: String
    let cluster: String
    let block: String
    let district: String
    let schoolType: String
    let assembly: String
    let parliament: String
    let pincode: String
    let address: String
    let landmark: String
    let busNumber: String
    let coordinates: String

    enum CodingKeys: String, CodingKey {
        case diseID = "DISE id"
        case schoolName = "School Name"
        case management = "Management"
        case medium = "Medium of Instruction"
        case category = "Category"
        case sex = "Sex"
        case cluster = "Cluster"
        case block = "Block"
        case district = "District"
        case schoolType = "School Type"
        case assembly = "Assembly"
        case parliament = "Parliament"
        case pincode = "Pincode"
        case address = "Address"
        case landmark = "Landmark"
        case busNumber = "Bus Number"
        case coordinates = "Coordinates"
    }
}
