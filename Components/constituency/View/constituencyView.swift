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
                    VStack(spacing: 32) {
                        // Profile Header Section
                        VStack(spacing: 24) {
                            // Profile Image with enhanced design
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            }

                            // Name and Basic Info
                            VStack(spacing: 16) {
                                Text(ConstituencyInfo.currentMLAName)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.primary)

                                // Party with enhanced styling
                                Text(getFullPartyName(ConstituencyInfo.politicalParty))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                                
                                // Status Tags
                                HStack(spacing: 16) {
                                    StatusTag(text: ConstituencyInfo.gender, icon: "person.fill", color: .purple)
                                    StatusTag(text: "Elected \(ConstituencyInfo.electionYear)", icon: "calendar", color: .green)
                                }
                            }
                        }
                        .padding(.top, 24)

                        // MLA Personal Information Card
                        MLAPersonalInfoCard()
                        
                        // Office Address Card
                        OfficeAddressCard()

                        // Constituency Information Card
                        VStack(alignment: .leading, spacing: 24) {
                            SectionHeader(title: "Constituency Details", icon: "building.2")

                            // Main Constituency Card
                            VStack(alignment: .leading, spacing: 20) {
                                // Constituency Name and Number
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(ConstituencyInfo.constituencyName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)

                                        Text("Constituency #\(ConstituencyInfo.constituencyNumber)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // Map Icon with enhanced background
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "map.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                // Detailed Information Grid
                                VStack(spacing: 16) {
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
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray6))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Bottom padding to account for floating button
                        Spacer()
                            .frame(height: 100)
                    }
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading constituency details...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(.systemBackground))
            
            // Enhanced Floating MLA History Button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showMLAHistory.toggle()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("History")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 34)
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

// MARK: - New Components for Enhanced UI

struct StatusTag: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(14)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct MLAPersonalInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Personal Information", icon: "person.text.rectangle")
            
            VStack(alignment: .leading, spacing: 18) {
                InfoRow(title: "Age", value: "58 years", icon: "calendar", color: .blue)
                InfoRow(title: "Education", value: "B.A., LL.B from Bangalore University", icon: "graduationcap.fill", color: .purple)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct OfficeAddressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Office Address", icon: "building.2.fill")
            
            VStack(alignment: .leading, spacing: 18) {
                InfoRow(title: "Official Address", value: "Room No. 245, Vidhana Soudha, Bangalore - 560001", icon: "building.2.fill", color: .blue)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ConstituencyDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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

#Preview {
    NavigationView {
        constituencyView(ConstituencyInfo: DummyConstituencyDetials.detials1)
    }
}
