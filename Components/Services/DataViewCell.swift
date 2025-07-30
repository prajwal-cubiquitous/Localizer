//
//  DataViewCell.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import SwiftUI
import UIKit

// MARK: - Identifiable wrapper for sheet presentation
struct InfoSheetItem: Identifiable {
    let id = UUID()
    let type: InfoType
    let data: Any
    
    enum InfoType {
        case policeStation
        case hospital  
        case school
    }
}

struct DataViewCellForPoliceStation: View {
    let screenSize = UIScreen.main.bounds
    let policeStation: PoliceStation
    @State private var infoSheetItem: InfoSheetItem?
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(policeStation.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(policeStation.fullAddress)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Phone Number: ".localized()).bold() + Text(policeStation.phoneNumber)
                    .font(.subheadline)
            }
            .padding()
            
            HStack {
                Button {
                    // Create new InfoSheetItem each time to ensure re-presentation
                    infoSheetItem = InfoSheetItem(type: .policeStation, data: policeStation)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title)
                }
                .padding(.trailing, 20)
                
                Button {
                    openGoogleMaps(withAddress: policeStation.name + "," + policeStation.fullAddress + "," + policeStation.pincode)
                } label: {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .frame(width: screenSize.width - 50)
        .sheet(item: $infoSheetItem) { item in
            if case .policeStation = item.type, let station = item.data as? PoliceStation {
                PopUPView(
                    name: station.name,
                    address: station.fullAddress,
                    constituency: station.constituency,
                    phoneNumber: station.phoneNumber,
                    pincode: station.pincode
                )
                .presentationDetents([.fraction(0.6), .fraction(0.8)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct DataViewCellForHospital: View {
    let screenSize = UIScreen.main.bounds
    let hospital: Hospital
    @State private var infoSheetItem: InfoSheetItem?
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(hospital.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(hospital.fullAddress)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Phone Number: ".localized()).bold() + Text(hospital.phoneNumber)
                    .font(.subheadline)
            }
            
            HStack {
                Button {
                    // Create new InfoSheetItem each time to ensure re-presentation
                    infoSheetItem = InfoSheetItem(type: .hospital, data: hospital)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title)
                }
                .padding(.trailing, 20)
                
                Button {
                    openGoogleMaps(withAddress: hospital.name + "," + hospital.fullAddress + " " + hospital.pincode)
                } label: {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .frame(width: screenSize.width - 50)
        .sheet(item: $infoSheetItem) { item in
            if case .hospital = item.type, let hosp = item.data as? Hospital {
                PopUPView(
                    name: hosp.name,
                    address: hosp.fullAddress,
                    constituency: hosp.constituency,
                    phoneNumber: hosp.phoneNumber,
                    pincode: hosp.pincode
                )
                .presentationDetents([.fraction(0.6), .fraction(0.8)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct DataViewCellForSchool: View {
    let screenSize = UIScreen.main.bounds
    let school: School
    @State private var infoSheetItem: InfoSheetItem?
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(school.schoolName)
                    .font(.headline)
                    .lineLimit(1)
                Text(school.address)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Phone Number: ".localized()).bold() + Text(school.pincode)
                    .font(.subheadline)
            }
            .padding()
            
            HStack {
                Button {
                    // Create new InfoSheetItem each time to ensure re-presentation
                    infoSheetItem = InfoSheetItem(type: .school, data: school)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title)
                }
                .padding(.trailing, 20)
                
                Button {
                    openGoogleMaps(withAddress: school.schoolName + "," + school.address + " " + school.pincode)
                } label: {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .frame(width: screenSize.width - 50)
        .sheet(item: $infoSheetItem) { item in
            if case .school = item.type, let sch = item.data as? School {
                PopUPView(
                    name: sch.schoolName,
                    address: sch.address,
                    constituency: sch.assembly,
                    phoneNumber: sch.busNumber,
                    pincode: sch.pincode
                )
                .presentationDetents([.fraction(0.6), .fraction(0.8)])
                .presentationDragIndicator(.visible)
            }
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
        // Handle error case
    }
}
