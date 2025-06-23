//
//  constituencyView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/16/25.
//

import SwiftUI

struct constituencyView: View {
    @StateObject var viewModel = constituencyViewModel()
    let ConstituencyInfo : ConstituencyDetails?
    @State private var showMLAHistory = false
    
    var body: some View {
        ScrollView {
                if let ConstituencyInfo = ConstituencyInfo{
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
                            case "JD(S)":
                                Text("Janata Dal (Secular)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            default:
                                Text(ConstituencyInfo.politicalParty)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Gender and Election Year
                            HStack {
                                Text(ConstituencyInfo.gender)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Text("Elected \(ConstituencyInfo.electionYear)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 20)
    
                        // Basic Constituency Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Constituency Details")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
    
                            // Constituency Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ConstituencyInfo.constituencyName)
                                            .font(.title3)
                                            .fontWeight(.medium)
    
                                        Text("Constituency #\(ConstituencyInfo.constituencyNumber)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
    
                                    Spacer()
    
                                    // Map Icon
                                    Image(systemName: "map.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }
                                
                                Divider()
                                
                                // Additional Details
                                VStack(alignment: .leading, spacing: 8) {
                                    ConstituencyDetailRow(title: "District", value: ConstituencyInfo.district)
                                    ConstituencyDetailRow(title: "Lok Sabha Constituency", value: ConstituencyInfo.lokSabhaConstituency)
                                    ConstituencyDetailRow(title: "Assembly Term", value: ConstituencyInfo.assemblyTerm)
                                    ConstituencyDetailRow(title: "Reservation Status", value: ConstituencyInfo.reservationStatus)
                                    ConstituencyDetailRow(title: "Previous MLA", value: ConstituencyInfo.previousMLA)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Pincodes Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Associated Pincodes")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(ConstituencyInfo.associatedPincodes, id: \.self) { pincode in
                                    Text(pincode)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
    
                        // MLA History Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MLA History")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
    
                            // History Card
                            Button(action: {
                                if ConstituencyInfo.mlaHistory != nil && !ConstituencyInfo.mlaHistory!.isEmpty {
                                    showMLAHistory.toggle()
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let mlaHistory = ConstituencyInfo.mlaHistory, !mlaHistory.isEmpty {
                                            Text("View Past Representatives")
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Text("\(mlaHistory.count) historical records available")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("MLA History")
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Text("Still not added")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
    
                                    Spacer()
    
                                    if ConstituencyInfo.mlaHistory != nil && !ConstituencyInfo.mlaHistory!.isEmpty {
                                        Image(systemName: "chevron.right")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Image(systemName: "exclamationmark.circle")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .disabled(ConstituencyInfo.mlaHistory == nil || ConstituencyInfo.mlaHistory!.isEmpty)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
    
                        Spacer()
                    }
                }else {
                ProgressView("Loading constituencies...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showMLAHistory) {
            MLAHistoryView(mlaHistory: ConstituencyInfo?.mlaHistory ?? [], constituencyName: ConstituencyInfo?.constituencyName ?? "")
        }
    }
}

struct ConstituencyDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

struct MLAHistoryView: View {
    let mlaHistory: [MLAHistory]
    let constituencyName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mlaHistory.indices, id: \.self) { index in
                    let history = mlaHistory[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(history.electionYear)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(history.politicalParty)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(partyColor(for: history.politicalParty).opacity(0.2))
                                .foregroundColor(partyColor(for: history.politicalParty))
                                .cornerRadius(8)
                        }
                        
                        Text(history.mlaName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(history.victoryMargin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("MLA History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func partyColor(for party: String) -> Color {
        switch party.uppercased() {
        case "BJP":
            return .orange
        case "INC", "CONGRESS":
            return .blue
        case "JD(S)":
            return .green
        default:
            return .gray
        }
    }
}

//#Preview {
//    NavigationView {
//        constituencyView(, ConstituencyInfo: <#ConstituencyDetails?#>)
//    }
//}
