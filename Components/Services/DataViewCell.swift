//
//  DataViewCell.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import SwiftUI
import UIKit
struct DataViewCellForPoliceStation: View {
    let screenSize = UIScreen.main.bounds
    let policeStation: PoliceStation
    @State private var showPopup = false
    var body: some View {
        VStack{
            VStack(alignment: .leading) {
                Text(policeStation.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(policeStation.fullAddress)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Phone Number: ").bold() + Text(policeStation.phoneNumber)
                    .font(.subheadline)
            }
            .padding()
            HStack{
                
                Button{
                    showPopup.toggle()
                }label:{
                    Image(systemName: "info.circle")
                        .font(.title)
                }
                .padding(.trailing, 20)
                Button{
                    openGoogleMaps(withAddress: policeStation.name + "," + policeStation.fullAddress + "," + policeStation.pincode)
                }label: {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .frame(width: screenSize.width - 50)
        .sheet(isPresented: $showPopup) {
            // The PopupView presented as a sheet
            PopUPView(name: policeStation.name, address: policeStation.fullAddress, constituency: policeStation.constituency, phoneNumber: policeStation.phoneNumber, pincode: policeStation.pincode)
                .frame(maxHeight: .infinity) // Makes it extend vertically to fill available space
                .cornerRadius(20)
                .edgesIgnoringSafeArea(.all) // Make sure the background extends to the edges
                .frame(height: UIScreen.main.bounds.height * 0.8) // 80% of screen height
        }
    }
}

struct DataViewCellForHospital: View {
    let screenSize = UIScreen.main.bounds
    let hospital: Hospital
    @State private var showPopup = false
    var body: some View {
        VStack{
            VStack(alignment: .leading) {
                Text(hospital.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(hospital.fullAddress)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Phone Number: ").bold() + Text(hospital.phoneNumber)
                    .font(.subheadline)
            }
            HStack{
                Button{
                    showPopup.toggle()
                }label:{
                    Image(systemName: "info.circle")
                        .font(.title)
                }
                .padding(.trailing, 20)
                Button{
                    openGoogleMaps(withAddress: hospital.name + "," + hospital.fullAddress + " " + hospital.pincode)
                }label: {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .frame(width: screenSize.width - 50)
        .sheet(isPresented: $showPopup) {
            // The PopupView presented as a sheet
            PopUPView(name: hospital.name, address: hospital.fullAddress, constituency: hospital.constituency, phoneNumber: hospital.phoneNumber, pincode: hospital.pincode)
                .frame(maxHeight: .infinity) // Makes it extend vertically to fill available space
                .cornerRadius(20)
                .edgesIgnoringSafeArea(.all) // Make sure the background extends to the edges
                .frame(height: UIScreen.main.bounds.height * 0.8) // 80% of screen height
        }
    }
}

struct DataViewCellForSchool: View {
    let screenSize = UIScreen.main.bounds
    let school: School
    @State private var showPopup = false
    var body: some View {
        VStack{
            VStack(alignment: .leading) {
                Text(school.schoolName)
                    .font(.headline)
                    .lineLimit(1)
                Text(school.address)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Phone Number: ").bold() + Text(school.pincode)
                    .font(.subheadline)
            }
            .padding()
            
            HStack{
                Button{
                    showPopup.toggle()
                }label:{
                    Image(systemName: "info.circle")
                        .font(.title)
                }
                .padding(.trailing, 20)
                Button{
                    openGoogleMaps(withAddress: school.schoolName + "," + school.address + " " + school.pincode)
                }label: {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .frame(width: screenSize.width - 50)
        .sheet(isPresented: $showPopup) {
            // The PopupView presented as a sheet
            PopUPView(name: school.schoolName, address: school.address, constituency: school.assembly, phoneNumber: school.busNumber, pincode: school.pincode)
                .frame(maxHeight: .infinity) // Makes it extend vertically to fill available space
                .cornerRadius(20)
                .edgesIgnoringSafeArea(.all) // Make sure the background extends to the edges
                .frame(height: UIScreen.main.bounds.height * 0.8) // 80% of screen height
        }
    }
}


func openGoogleMaps(withAddress address: String) {
    // Ensure it's just a plain address, not a full Google URL
    let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    
    if let appURL = URL(string: "comgooglemaps://?q=\(encodedAddress)"),
       UIApplication.shared.canOpenURL(appURL) {
        UIApplication.shared.open(appURL)
    } else if let webURL = URL(string: "https://www.google.com/maps/search/\(encodedAddress)") {
        UIApplication.shared.open(webURL)
    } else {
    }
}
