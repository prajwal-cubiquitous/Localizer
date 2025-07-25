//
//  DataUploadUI.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//

import SwiftUI
import FirebaseStorage

// Main view that constructs the UI shown in the image.
struct UploadDataView: View {
    @State private var isLoading = false
    @State private var loadingMessage = ""
    @State private var showConfirmationAlert = false
    @State private var pendingUploadAction: (() -> Void)?
    @State private var confirmationTitle = ""
    @State private var confirmationMessage = ""
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    
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
                        showConfirmationDialog(
                            title: "Upload Hospital Data",
                            message: "This will delete all existing hospital data and upload new data from Hospital.json. This action cannot be undone.",
                            action: {
                                uploadHospitalData()
                            }
                        )
                    }
                    .buttonStyle(CustomButtonStyle())
                    .disabled(isLoading)
                    
                    Button("School Data") {
                        showConfirmationDialog(
                            title: "Upload School Data",
                            message: "This will delete all existing school data and upload new data from school.json. This action cannot be undone.",
                            action: {
                                uploadSchoolData()
                            }
                        )
                    }
                    .buttonStyle(CustomButtonStyle())
                    .disabled(isLoading)
                    
                    Button("Police Data") {
                        showConfirmationDialog(
                            title: "Upload Police Station Data",
                            message: "This will delete all existing police station data and upload new data from PoliceStation.json. This action cannot be undone.",
                            action: {
                                uploadPoliceData()
                            }
                        )
                    }
                    .buttonStyle(CustomButtonStyle())
                    .disabled(isLoading)
                    
                    Button("Constituency Data") {
                        showConfirmationDialog(
                            title: "Upload Constituency Data",
                            message: "This will delete all existing constituency data and upload new data from Karnataka_Complete_Constituency_Details.json. This action cannot be undone.",
                            action: {
                                uploadConstituencyData()
                            }
                        )
                    }
                    .buttonStyle(CustomButtonStyle())
                    .disabled(isLoading)
                    
                    Button("Clean Profile Images") {
                        showConfirmationDialog(
                            title: "Clean Profile Images",
                            message: "This will permanently delete all profile images from Firebase Storage. This action cannot be undone.",
                            action: {
                                cleanProfileImages()
                            }
                        )
                    }
                    .buttonStyle(CustomButtonStyle())
                    .disabled(isLoading)
                }
                .padding(.top, 10)

                // Loading indicator
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text(loadingMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer() // Balances the top spacer.
            }
            .padding(.horizontal, 24) // Adds padding on the sides.
            .background(Color(uiColor: .systemBackground)) // Adapts background for light/dark mode.
            .navigationTitle("Upload Data")
            .navigationBarTitleDisplayMode(.inline)
            // The back button is automatically included by NavigationView.
        }
        .alert(confirmationTitle, isPresented: $showConfirmationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                pendingUploadAction?()
            }
        } message: {
            Text(confirmationMessage)
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Functions
    
    private func showConfirmationDialog(title: String, message: String, action: @escaping () -> Void) {
        confirmationTitle = title
        confirmationMessage = message
        pendingUploadAction = action
        showConfirmationAlert = true
    }
    
    private func uploadHospitalData() {
        isLoading = true
        loadingMessage = "Deleting existing hospital data..."
        
        Task {
            await MainActor.run {
                UploadData.uploadHospitalsAsync { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let count):
                            loadingMessage = "Upload completed successfully!"
                            // Brief delay to show completion message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoading = false
                                alertMessage = "Successfully uploaded \(count) hospitals to Firestore."
                                showSuccessAlert = true
                            }
                        case .failure(let error):
                            isLoading = false
                            alertMessage = "Failed to upload hospital data: \(error.localizedDescription)"
                            showErrorAlert = true
                        }
                    }
                }
                // Update loading message after deletion starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isLoading {
                        loadingMessage = "Uploading hospital data to Firestore..."
                    }
                }
            }
        }
    }
    
    private func uploadSchoolData() {
        isLoading = true
        loadingMessage = "Deleting existing school data..."
        
        Task {
            await MainActor.run {
                UploadData.uploadSchoolsAsync { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let count):
                            loadingMessage = "Upload completed successfully!"
                            // Brief delay to show completion message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoading = false
                                alertMessage = "Successfully uploaded \(count) schools to Firestore."
                                showSuccessAlert = true
                            }
                        case .failure(let error):
                            isLoading = false
                            alertMessage = "Failed to upload school data: \(error.localizedDescription)"
                            showErrorAlert = true
                        }
                    }
                }
                // Update loading message after deletion starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isLoading {
                        loadingMessage = "Uploading school data to Firestore..."
                    }
                }
            }
        }
    }
    
    private func uploadPoliceData() {
        isLoading = true
        loadingMessage = "Deleting existing police station data..."
        
        Task {
            await MainActor.run {
                UploadData.uploadPoliceStationsAsync { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let count):
                            loadingMessage = "Upload completed successfully!"
                            // Brief delay to show completion message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoading = false
                                alertMessage = "Successfully uploaded \(count) police stations to Firestore."
                                showSuccessAlert = true
                            }
                        case .failure(let error):
                            isLoading = false
                            alertMessage = "Failed to upload police station data: \(error.localizedDescription)"
                            showErrorAlert = true
                        }
                    }
                }
                // Update loading message after deletion starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isLoading {
                        loadingMessage = "Uploading police station data to Firestore..."
                    }
                }
            }
        }
    }
    
    private func uploadConstituencyData() {
        isLoading = true
        loadingMessage = "Deleting existing constituency data..."
        
        Task {
            await MainActor.run {
                UploadData.uploadConstituencyJSONAsync { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let count):
                            loadingMessage = "Upload completed successfully!"
                            // Brief delay to show completion message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoading = false
                                alertMessage = "Successfully uploaded \(count) constituencies to Firestore."
                                showSuccessAlert = true
                            }
                        case .failure(let error):
                            isLoading = false
                            alertMessage = "Failed to upload constituency data: \(error.localizedDescription)"
                            showErrorAlert = true
                        }
                    }
                }
                // Update loading message after deletion starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isLoading {
                        loadingMessage = "Uploading constituency data to Firestore..."
                    }
                }
            }
        }
    }
    
    private func cleanProfileImages() {
        isLoading = true
        loadingMessage = "Cleaning profile images from Firebase Storage..."
        
        Task {
            do {
                try await ImageUploaderForProfile.deleteAllProfileImages()
                await MainActor.run {
                    loadingMessage = "Cleanup completed successfully!"
                    // Brief delay to show completion message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isLoading = false
                        alertMessage = "All profile images cleaned up successfully."
                        showSuccessAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to clean profile images: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
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
