//
//  ServicesView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct ServicesView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let services = [
        "Home Repair", "Cleaning", "Moving", "Delivery", 
        "Food", "Healthcare", "Tutoring", "Legal"
    ]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Featured services
                    Text("Featured Services")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<5) { index in
                                featuredServiceCard(index: index)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Service categories
                    Text("Service Categories")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(services.indices, id: \.self) { index in
                            serviceCard(name: services[index], iconName: getIconName(for: index))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.inline)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .preferredColorScheme(colorScheme)
    }
    
    private func featuredServiceCard(index: Int) -> some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                .frame(width: 240, height: 160)
                .cornerRadius(12)
                .overlay(
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(colorScheme == .dark ? .white : .blue)
                )
            
            Text("Featured Service \(index + 1)")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                .lineLimit(1)
            
            Text("This is a description of the featured service.")
                .font(.subheadline)
                .foregroundStyle(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                .lineLimit(2)
            
            HStack {
                Text("$\(25 + (index * 10))/hr")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .green.opacity(0.9) : .blue)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { starIndex in
                        Image(systemName: starIndex < 4 ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .frame(width: 240)
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func serviceCard(name: String, iconName: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundStyle(colorScheme == .dark ? .white : .blue)
                .frame(width: 60, height: 60)
                .background(colorScheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                .cornerRadius(30)
            
            Text(name)
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func getIconName(for index: Int) -> String {
        let icons = ["house", "spray.sparkle", "box.truck", "bicycle", 
                     "fork.knife", "heart.text.square", "book", "scroll"]
        return icons[index % icons.count]
    }
}

#Preview {
    ServicesView()
}
