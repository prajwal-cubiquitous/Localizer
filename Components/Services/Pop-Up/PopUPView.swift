//
//  PopUPView.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import SwiftUI

struct PopUPView: View {
    var name: String
    var address: String
    var constituency: String
    var phoneNumber: String
    var pincode : String
    @State private var selectedTab = 0
    @Environment(\.dismiss) var dismiss
    let screenSize = UIScreen.main.bounds
    var body: some View {
        ScrollView{
            VStack{
                Image("tiger-image")
                    .resizable()
                    .frame(width: screenSize.width, height: 300)
                    .padding(.vertical)
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Phone number
                    Link(destination: URL(string: phoneNumber)!) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            Text(phoneNumber)
                        }
                        .font(.body)
                    }
                    
                    // Area / Locality
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                        Text(constituency)
                            .font(.body)
                    }
                    
                    // Address
                    HStack(alignment: .top) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.orange)
                        Text(address)
                        .font(.subheadline)
                    }
                    
                    // Pincode
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.gray)
                        Text(pincode)
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color("AdaptiveTextColor"))
                .cornerRadius(16)
                .shadow(radius: 5)
                .padding()
            }
        }
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
                Button{
                    
                }label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color("AdaptiveBackgroundColor"))
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button{
                    dismiss()
                }label: {
                    Text("Cancel".localized())
                        .foregroundColor(Color("AdaptiveBackgroundColor"))
                }
            }
        }
    }
}

#Preview {
    NavigationStack{
        PopUPView(name: "anything", address: "XYZ", constituency: "ABC", phoneNumber: "98643496779", pincode: "456565")
    }
}
