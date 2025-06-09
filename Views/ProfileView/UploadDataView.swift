//
//  DataUploadUI.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//

import SwiftUI

// Main view that constructs the UI shown in the image.
struct UploadDataView: View {
    var body: some View {
        // Use a NavigationView to get the top navigation bar.
        NavigationView {
            VStack(spacing: 24) {
                Spacer() // Pushes the content to the vertical center.

                // The main title text on the screen.
                // .primary color makes it black in light mode and white in dark mode.
                Text("Select Data Type")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Buttons for data selection.
                // Using a custom style for a consistent look.
                VStack(spacing: 16) {
                    Button("Hospital Data") {
                        UploadData.uploadHospitals()
                    }
                    .buttonStyle(CustomButtonStyle())
                    
                    Button("School Data") {
                        UploadData.uploadSchools()
                    }
                    .buttonStyle(CustomButtonStyle())
                    
                    Button("Police Data") {
                        UploadData.uploadPoliceStations()
                    }
                    .buttonStyle(CustomButtonStyle())
                }
                .padding(.top, 10)

                Spacer() // Balances the top spacer.
            }
            .padding(.horizontal, 24) // Adds padding on the sides.
            .background(Color(uiColor: .systemBackground)) // Adapts background for light/dark mode.
            .navigationTitle("Upload Data")
            .navigationBarTitleDisplayMode(.inline)
            // The back button is automatically included by NavigationView.
        }
    }
}

// A reusable custom style for the buttons to match the image.
// This makes the code cleaner and easier to maintain.
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            // Using systemGray6 provides a background that adapts nicely.
            // In light mode it's a very light gray, and in dark mode a darker gray.
            .background(Color(uiColor: .systemGray6))
            .foregroundColor(.accentColor) // Using the app's tint color for the text.
            .cornerRadius(14)
            // Gently scale the button when it's pressed.
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}


// --- Previews ---
// You can see how your view looks in different states here.

// Preview for Light Mode
#Preview("Light Mode") {
    UploadDataView()
}

// Preview for Dark Mode
#Preview("Dark Mode") {
    UploadDataView()
        .preferredColorScheme(.dark)
}
