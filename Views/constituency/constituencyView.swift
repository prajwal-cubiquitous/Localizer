//
//  constituencyView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/16/25.
//

import SwiftUI

struct constituencyView: View {
    @StateObject var viewModel = constituencyViewModel()
    let pincode: String
    @State var constituencies : [ConstituencyDetails]?
    @State private var selectedName: String = ""
    var selectedConstituency: ConstituencyDetails? {
        constituencies?.first { $0.constituencyName == selectedName }
    }
    var body: some View {
        ScrollView {
            if let list = constituencies {
//                Picker("Select Constituency", selection: $selectedName) {
//                    ForEach(list, id: \.constituencyName) { item in
//                        Text(item.constituencyName).tag(item.constituencyName)
//                    }
//                }
//                .pickerStyle(.menu)
                StylishPicker(list: list, selectedName: $selectedName)
                
                if let ConstituencyInfo = selectedConstituency {
                    VStack(spacing: 20) {
                        // Profile Header Section
                        VStack(spacing: 12) {
                            // Profile Image
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .background(
                                    Circle()
                                        .fill(Color.orange.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                )
    
                            // Name
                            Text(ConstituencyInfo.currentMLAName)
                                .font(.title2)
                                .fontWeight(.semibold)
    
                            // Party
                            switch ConstituencyInfo.politicalParty {
                            case "BJP":
                                Text("Bharatiya Janata Party")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            case "INC":
                                Text("Indian National Congress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            default:
                                Text("Indipendent")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
    
                        // Basic Constituency Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Constituency Info")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
    
                            // Constituency Card
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ConstituencyInfo.constituencyName)
                                        .font(.title3)
                                        .fontWeight(.medium)
    
                                    Text(ConstituencyInfo.constituencyName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
    
                                Spacer()
    
                                // Map Icon
                                Image(systemName: "map.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
    
                        // MLA History Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MLA History")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
    
                            // History Card
                            HStack {
                                Text("View Past Representatives")
                                    .font(.body)
                                    .foregroundColor(.primary)
    
                                Spacer()
    
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
    
                        Spacer()
                    }
                }
            } else {
                ProgressView("Loading constituencies...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .task(id: pincode){
            constituencies = await viewModel.fetchConstituency(forPincode: pincode)
            if let first = constituencies?.first {
                selectedName = first.constituencyName
            }
        }
    }
}

#Preview {
    NavigationView {
        constituencyView(pincode: "590001")
    }
}
