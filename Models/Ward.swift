//
//  Ward.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/16/25.
//

import SwiftUI
import FirebaseFirestore

struct Ward: Identifiable, Codable {
    @DocumentID var id: String?
    var number: Int
    var name: String
    var corporator: String
    var reservation: String
    var pinCodes: [String]
}


extension Ward {
    static let dummyWards: [Ward] = [
        Ward(id: "ward8", number: 8, name: "Jakkur", corporator: "ABCD", reservation: "General (W)", pinCodes: ["560064"]),
        Ward(id: "ward10", number: 10, name: "Kodigehalli", corporator: "dummy2", reservation: "OBC (W)", pinCodes: ["560097"])
    ]
}
