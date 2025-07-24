//
//  WardCardView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/16/25.
//

import SwiftUI

struct WardCardView: View {
    let ward: Ward
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Ward Number and Reservation
            HStack(alignment: .top, spacing: 12) {
                // Ward Number Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Text("\(ward.number)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Ward Name
                    Text(ward.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Reservation Status
                    Text(ward.reservation)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(reservationColor(for: ward.reservation).opacity(0.12))
                        .foregroundColor(reservationColor(for: ward.reservation))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            // Details Section
            VStack(spacing: 12) {
                // Corporator
                WardDetailRow(
                    title: "Corporator",
                    value: ward.corporator,
                    icon: "person.fill",
                    color: .green
                )
                
                // Pincodes
                WardDetailRow(
                    title: "Pincodes",
                    value: ward.pinCodes.joined(separator: ", "),
                    icon: "location.fill",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private func reservationColor(for reservation: String) -> Color {
        if reservation.contains("General") {
            return .blue
        } else if reservation.contains("OBC") {
            return .orange
        } else if reservation.contains("SC") {
            return .purple
        } else if reservation.contains("ST") {
            return .green
        } else {
            return .gray
        }
    }
}

struct WardDetailRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Wards List View
struct WardsListView: View {
    let wards: [Ward]
    let constituencyName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Label("Wards in \(constituencyName)", systemImage: "building.2")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(wards.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            // Wards Cards
            ScrollView() {
                ForEach(wards) { ward in
                    WardCardView(ward: ward)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Wards List Preview
            WardsListView(
                wards: Ward.dummyWards,
                constituencyName: "Sample Constituency"
            )
        }
        .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
}
 
