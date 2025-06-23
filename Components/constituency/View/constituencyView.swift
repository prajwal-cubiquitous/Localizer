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
        ZStack {
            ScrollView {
                if let ConstituencyInfo = ConstituencyInfo {
                    VStack(spacing: 24) {
                        // Profile Header Section
                        VStack(spacing: 16) {
                            // Profile Image
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.blue)
                            }

                            // Name and Basic Info
                            VStack(spacing: 8) {
                                Text(ConstituencyInfo.currentMLAName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)

                                // Party with proper formatting
                                Text(getFullPartyName(ConstituencyInfo.politicalParty))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                // Gender and Election Year Tags
                                HStack(spacing: 12) {
                                    Label(ConstituencyInfo.gender, systemImage: "person.fill")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                    
                                    Label("Elected \(ConstituencyInfo.electionYear)", systemImage: "calendar")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.green)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.top, 24)

                        // Constituency Information Card
                        VStack(alignment: .leading, spacing: 20) {
                            // Section Header
                            HStack {
                                Label("Constituency Details", systemImage: "building.2")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)

                            // Main Constituency Card
                            VStack(alignment: .leading, spacing: 16) {
                                // Constituency Name and Number
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ConstituencyInfo.constituencyName)
                                            .font(.title3)
                                            .fontWeight(.semibold)

                                        Text("Constituency #\(ConstituencyInfo.constituencyNumber)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // Map Icon with background
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "map.fill")
                                            .font(.title3)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                // Detailed Information Grid
                                VStack(spacing: 12) {
                                    ConstituencyDetailRow(
                                        title: "District", 
                                        value: ConstituencyInfo.district,
                                        icon: "location.fill"
                                    )
                                    
                                    ConstituencyDetailRow(
                                        title: "Lok Sabha Constituency", 
                                        value: ConstituencyInfo.lokSabhaConstituency,
                                        icon: "building.columns"
                                    )
                                    
                                    ConstituencyDetailRow(
                                        title: "Assembly Term", 
                                        value: ConstituencyInfo.assemblyTerm,
                                        icon: "calendar.badge.clock"
                                    )
                                    
                                    ConstituencyDetailRow(
                                        title: "Reservation Status", 
                                        value: ConstituencyInfo.reservationStatus,
                                        icon: "shield.fill"
                                    )
                                    
                                    ConstituencyDetailRow(
                                        title: "Previous MLA", 
                                        value: ConstituencyInfo.previousMLA,
                                        icon: "person.2.fill"
                                    )
                                    
                                    ConstituencyDetailRow(
                                        title: "Victory Margin", 
                                        value: ConstituencyInfo.victoryMargin,
                                        icon: "chart.bar.fill"
                                    )
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal, 20)
                        }

                        // Bottom padding to account for floating button
                        Spacer()
                            .frame(height: 100)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Loading constituency details...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(.systemBackground))
            
            // Floating MLA History Button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showMLAHistory.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("History")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.blue)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 34) // Account for safe area
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMLAHistory) {
            MLAHistoryView(
                mlaHistory: ConstituencyInfo?.mlaHistory ?? [], 
                constituencyName: ConstituencyInfo?.constituencyName ?? ""
            )
        }
    }
    
    // Helper function to get full party names
    private func getFullPartyName(_ party: String) -> String {
        switch party {
        case "BJP":
            return "Bharatiya Janata Party"
        case "INC":
            return "Indian National Congress"
        case "JD(S)":
            return "Janata Dal (Secular)"
        default:
            return party
        }
    }
}

struct ConstituencyDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .leading)
            
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Value
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

struct MLAHistoryView: View {
    let mlaHistory: [MLAHistory]
    let constituencyName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if mlaHistory.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("No History Available")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("MLA history for this constituency is still not added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    // History List
                    List {
                        ForEach(mlaHistory.indices, id: \.self) { index in
                            let history = mlaHistory[index]
                            
                            VStack(alignment: .leading, spacing: 12) {
                                // Year and Party
                                HStack {
                                    Text(history.electionYear)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(history.politicalParty)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(partyColor(for: history.politicalParty).opacity(0.15))
                                        .foregroundColor(partyColor(for: history.politicalParty))
                                        .cornerRadius(12)
                                }
                                
                                // MLA Name
                                Text(history.mlaName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                // Victory Margin
                                if !history.victoryMargin.isEmpty {
                                    Text(history.victoryMargin)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color(.systemBackground))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("MLA History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
