//
//  constituencyDetials.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/16/25.
//

import Foundation
import FirebaseFirestore

struct ConstituencyDetails: Codable, Identifiable {
    @DocumentID var id: String?  // Firestore doc ID

    var constituencyName: String
    var currentMLAName: String
    var politicalParty: String
    var associatedPincodes: [String]
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
     static var detials1 = ConstituencyDetails(constituencyName: "Adilabad", currentMLAName: "Nandini", politicalParty: "BJP", associatedPincodes: ["500001", "500002"])
    
}
