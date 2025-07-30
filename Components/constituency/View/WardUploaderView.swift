//
//  WardUploaderView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/16/25.
//


import SwiftUI
import FirebaseFirestore

struct WardUploaderView: View {
    let constituencyId : String = "B8B05F79-8F68-4492-8C9A-300EAB6861FE"

    var body: some View {
        VStack {
            Button("Upload Ward Data".localized()) {
                uploadWards(for: constituencyId)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    func uploadWards(for constituencyId: String) {
        let db = Firestore.firestore()

        let wards: [Ward] = [
            Ward(id: nil, number: 8, name: "Jakkur",
                 corporator: "Mamatha Vasudeva (BJP)",
                 reservation: "General (W)", pinCodes: ["560064"]),

            Ward(id: nil, number: 9, name: "Sampigehalli",
                 corporator: "Muneer (JDS)",
                 reservation: "General", pinCodes: ["560043", "560064"]),

            Ward(id: nil, number: 10, name: "Kodigehalli",
                 corporator: "R. Sathyabhama (BJP)",
                 reservation: "OBC (W)", pinCodes: ["560097"]),

            Ward(id: nil, number: 11, name: "Vidyaranyapura",
                 corporator: "Manjula Narayanaswamy (BJP)",
                 reservation: "SC (W)", pinCodes: ["560097"]),

            Ward(id: nil, number: 12, name: "Doddabommasandra",
                 corporator: "B. N. Lakshmidevamma (BJP)",
                 reservation: "ST (W)", pinCodes: ["560097", "560090"]),

            Ward(id: nil, number: 13, name: "Thindlu",
                 corporator: "U. R. Sabhapathi (INC)",
                 reservation: "General", pinCodes: ["560097"]),

            Ward(id: nil, number: 14, name: "Kuvempu Nagar",
                 corporator: "Padmavathi (BJP)",
                 reservation: "General (W)", pinCodes: ["560094"]),
        ]

        for ward in wards {
            do {
                _ = try db.collection("constituencies")
                          .document(constituencyId)
                          .collection("wards")
                          .addDocument(from: ward)
            } catch {
                print("Failed to upload ward \(ward.number): \(error)")
            }
        }

        print("Uploaded \(wards.count) wards.")
    }
}
