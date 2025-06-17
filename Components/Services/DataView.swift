//
//  DataView.swift
//  Repin
//
//  Created by Prajwal S S Reddy on 5/15/25.
//

import SwiftUI

struct DataView: View {
    @StateObject private var viewModel : DataViewModel
    
    let tabs = ["Schools", "Hospitals", "Police Stations"]
    let tabImages = ["graduationcap.fill", "cross.case.fill", "shield.fill"]
    
    @State private var selectedTab = 0
    @State private var showingInfoSheet = false
    @State private var selectedInfoItem: InfoItem?
    @Namespace private var animationNamespace
    
    // MARK: - Info Item Model
    struct InfoItem {
        let title: String
        let address: String
        let details: [String: String]
        let coordinates: String?
        let googleMapLink: String?
        let type: InfoType
        
        enum InfoType {
            case school, hospital, policeStation
            
            var icon: String {
                switch self {
                case .school: return "graduationcap.fill"
                case .hospital: return "cross.case.fill"
                case .policeStation: return "shield.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .school: return .blue
                case .hospital: return .red
                case .policeStation: return .green
                }
            }
        }
    }
    
    // MARK: - Constants following Apple Design Guidelines
    private enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 2
        static let minTouchTarget: CGFloat = 44 // Apple's minimum touch target
        static let cardSpacing: CGFloat = 16
    }
    
    init(pincode : String){
        _viewModel = StateObject(wrappedValue: DataViewModel(postalCode: pincode))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Tab Selector
            modernTabSelector
            
            // Current Location Display
            locationDisplayView
            
            // Content Area
            TabView(selection: $selectedTab) {
                // Schools Tab
                contentView(
                    items: viewModel.schools.map { AnyHashable($0) },
                    emptyMessage: "No schools found in your area",
                    emptyIcon: "graduationcap"
                ) { school in
                    if let school = school as? School {
                        ModernDataCard(
                            title: school.schoolName,
                            subtitle: school.address,
                            detail: "Pincode: \(school.pincode)",
                            icon: "graduationcap.fill",
                            iconColor: .blue,
                            onInfoTap: {
                                showSchoolInfo(school)
                            },
                            onNavigateTap: {
                                openGoogleMaps(withAddress: "\(school.schoolName), \(school.address) \(school.pincode)")
                            }
                        )
                    }
                }
                .tag(0)
                
                // Hospitals Tab
                contentView(
                    items: viewModel.hospitals.map { AnyHashable($0) },
                    emptyMessage: "No hospitals found in your area",
                    emptyIcon: "cross.case"
                ) { hospital in
                    if let hospital = hospital as? Hospital {
                        ModernDataCard(
                            title: hospital.name,
                            subtitle: hospital.fullAddress,
                            detail: "Phone: \(hospital.phoneNumber)",
                            icon: "cross.case.fill",
                            iconColor: .red,
                            onInfoTap: {
                                showHospitalInfo(hospital)
                            },
                            onNavigateTap: {
                                openGoogleMaps(withAddress: "\(hospital.name), \(hospital.fullAddress)")
                            }
                        )
                    }
                }
                .tag(1)
                
                // Police Stations Tab
                contentView(
                    items: viewModel.policeStations.map { AnyHashable($0) },
                    emptyMessage: "No police stations found in your area",
                    emptyIcon: "shield"
                ) { station in
                    if let station = station as? PoliceStation {
                        ModernDataCard(
                            title: station.name,
                            subtitle: station.fullAddress,
                            detail: "Contact: \(station.phoneNumber)",
                            icon: "shield.fill",
                            iconColor: .green,
                            onInfoTap: {
                                showPoliceStationInfo(station)
                            },
                            onNavigateTap: {
                                openGoogleMaps(withAddress: "\(station.name), \(station.fullAddress)")
                            }
                        )
                    }
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.fetchData(for: viewModel.postalCode)
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingInfoSheet) {
            if let item = selectedInfoItem {
                InfoDetailView(item: item)
                    .presentationDetents([.fraction(0.7), .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Modern Tab Selector
    private var modernTabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.cardSpacing) {
                ForEach(tabs.indices, id: \.self) { index in
                    TabButtonforDataView(
                        title: tabs[index],
                        icon: tabImages[index],
                        isSelected: selectedTab == index,
                        namespace: animationNamespace
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
        .padding(.vertical, Constants.verticalSpacing)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Location Display
    private var locationDisplayView: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundStyle(.secondary)
            
            Text("Current Area: \(viewModel.postalCode)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalSpacing / 2)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Content View
    private func contentView<T: Hashable>(
        items: [T],
        emptyMessage: String,
        emptyIcon: String,
        @ViewBuilder itemBuilder: @escaping (T) -> some View
    ) -> some View {
        Group {
            if items.isEmpty {
                EmptyStateView(
                    icon: emptyIcon,
                    message: emptyMessage,
                    description: "Try refreshing or check back later"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Constants.cardSpacing) {
                        ForEach(items, id: \.self) { item in
                            itemBuilder(item)
                        }
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                    .padding(.vertical, Constants.verticalSpacing)
                }
            }
        }
    }
    
    // MARK: - Info Display Methods
    private func showSchoolInfo(_ school: School) {
        selectedInfoItem = InfoItem(
            title: school.schoolName,
            address: school.address,
            details: [
                "Management": school.management,
                "Medium": school.medium,
                "Category": school.category,
                "School Type": school.schoolType,
                "Block": school.block,
                "District": school.district,
                "Pincode": school.pincode,
                "Landmark": school.landmark.isEmpty ? "Not available" : school.landmark,
                "Bus Number": school.busNumber.isEmpty ? "Not available" : school.busNumber
            ],
            coordinates: school.coordinates.isEmpty ? nil : school.coordinates,
            googleMapLink: nil,
            type: .school
        )
        showingInfoSheet = true
    }
    
    private func showHospitalInfo(_ hospital: Hospital) {
        selectedInfoItem = InfoItem(
            title: hospital.name,
            address: hospital.fullAddress,
            details: [
                "Constituency": hospital.constituency,
                "Phone": hospital.phoneNumber,
                "Pincode": hospital.pincode
            ],
            coordinates: nil,
            googleMapLink: hospital.googleMapLink.isEmpty ? nil : hospital.googleMapLink,
            type: .hospital
        )
        showingInfoSheet = true
    }
    
    private func showPoliceStationInfo(_ station: PoliceStation) {
        selectedInfoItem = InfoItem(
            title: station.name,
            address: station.fullAddress,
            details: [
                "Constituency": station.constituency,
                "Phone": station.phoneNumber,
                "Division": station.division,
                "Sub-Division": station.subDivision,
                "Pincode": station.pincode
            ],
            coordinates: nil,
            googleMapLink: station.googleMapLink.isEmpty ? nil : station.googleMapLink,
            type: .policeStation
        )
        showingInfoSheet = true
    }
}

// MARK: - Tab Button Component
struct TabButtonforDataView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color("primaryOpposite") : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.primary)
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                } else {
                    Capsule()
                        .fill(Color(.systemGray6))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Data Card Component
struct ModernDataCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let iconColor: Color
    let onInfoTap: () -> Void
    let onNavigateTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 56) // Align with text above
            
            // Action Buttons
            HStack(spacing: 16) {
                Spacer()
                
                Button(action: onInfoTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("Info")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: onNavigateTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                        Text("Navigate")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color("primaryOpposite"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Empty State Component
struct EmptyStateView: View {
    let icon: String
    let message: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Info Detail View
struct InfoDetailView: View {
    let item: DataView.InfoItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon and title
                    headerView
                    
                    // Address section
                    addressSection
                    
                    // Details section
                    detailsSection
                    
                    // Map section
                    if item.googleMapLink != nil || item.coordinates != nil {
                        mapSection
                    }
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding(16)
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: item.type.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(item.type.color)
                .frame(width: 60, height: 60)
                .background(item.type.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Text(item.type == .school ? "Educational Institution" : 
                     item.type == .hospital ? "Healthcare Facility" : "Law Enforcement")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Address", systemImage: "location.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(item.address)
                .font(.body)
                .lineLimit(nil)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Information", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(item.details.keys.sorted()), id: \.self) { key in
                    if let value = item.details[key] {
                        DetailRow(title: key, value: value)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "map.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let googleMapLink = item.googleMapLink, !googleMapLink.isEmpty {
                AsyncImage(url: URL(string: "https://maps.googleapis.com/maps/api/staticmap?center=\(item.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&zoom=15&size=400x200&maptype=roadmap&markers=color:red%7C\(item.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=YOUR_API_KEY")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay {
                            VStack {
                                Image(systemName: "map")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                                Text("Map Preview")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay {
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text("Map not available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                openGoogleMaps(withAddress: "\(item.title), \(item.address)")
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Open in Maps")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let phone = item.details["Phone"], !phone.isEmpty, phone != "Not available" {
                Button {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call \(phone)")
                    }
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.primary, lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        DataView(pincode: "560043")
}
} 
