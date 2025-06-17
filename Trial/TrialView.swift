//
//  TrialView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//

import SwiftUI

struct TrialView: View {
    // Sample data
    let items = ["Home", "Profile", "Settings"]

    // State to track the current selection
    @State private var selectedItem = "Home"

    var body: some View {
        VStack(spacing: 20) {
            // Dropdown menu (Picker)
            Picker("Select Option", selection: $selectedItem) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
            }
            .pickerStyle(.menu) // Use .segmented or .wheel for other styles

            Divider()

            // Switch view based on selection
            switch selectedItem {
            case "Home":
                Text("🏠 Welcome to the Home Screen")
                    .font(.title)
            case "Profile":
                Text("👤 User Profile")
                    .font(.title)
            case "Settings":
                Text("⚙️ Settings Panel")
                    .font(.title)
            default:
                Text("Unknown Selection")
            }
        }
        .padding()
    }
}


#Preview {
    TrialView()
}
