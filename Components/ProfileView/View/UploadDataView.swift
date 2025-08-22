//
//  DataUploadUI.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//

import SwiftUI
import FirebaseStorage
import Firebase

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
    @State var showUploadward: Bool = false
    
    var body: some View {
        // Use a NavigationView to get the top navigation bar.
        NavigationView {
            VStack(spacing: 24) {
                Spacer() // Pushes the content to the vertical center.

                // The main title text on the screen.
                // .primary color makes it black in light mode and white in dark mode.
                Text("Select Data Type".localized())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Buttons for data selection.
                // Using a custom style for a consistent look.
                VStack(spacing: 16) {
                    Button("Hospital Data".localized()) {
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
                    
                    Button("School Data".localized()) {
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
                    
                    Button("Police Data".localized()) {
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
                    
                    Button("Constituency Data".localized()) {
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
                    
                    Button("Clean Profile Images".localized()) {
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
                    
                    Button("Upload ward detials for one ward 560043".localized()) {
                        showUploadward.toggle()
                    }
                    .buttonStyle(CustomButtonStyle())
                    .disabled(isLoading)
                    
                    Button("upload temp data 1000") {
                        showConfirmationDialog(
                            title: "Upload 1000 temp data to firebase",
                            message: "just uplaod the data to firebase for testing",
                            action: {
                                uploadDummyNews()
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
            Button("Cancel".localized(), role: .cancel) { }
            Button("Confirm".localized(), role: .destructive) {
                pendingUploadAction?()
            }
        } message: {
            Text(confirmationMessage)
        }
        .alert("Success".localized(), isPresented: $showSuccessAlert) {
            Button("OK".localized()) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error".localized(), isPresented: $showErrorAlert) {
            Button("OK".localized()) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showUploadward) {
            NavigationView {
                WardUploaderView()
            }
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
                UploadData.uploadHospitalsToFirestore()
                isLoading = false
            }
        }
    }
    
    private func uploadSchoolData() {
        isLoading = true
//        loadingMessage = "Deleting existing hospital data..."
        
        Task {
            await MainActor.run {
                UploadData.uploadSchoolsToFirestore()
                isLoading = false
            }
        }
    }
    
    private func uploadPoliceData() {
        isLoading = true
        loadingMessage = "Deleting existing hospital data..."
        
        Task {
            await MainActor.run {
                UploadData.uploadPoliceStationsToFirestore()
                isLoading = false
            }
        }    }
    
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
    
    private func uploadDummyNews() {
            let db = Firestore.firestore()
            let ownerUid = "BvXKrYAFj9dA8XVnF9wpOY157552"
            let constituencyId = "346C4917-471E-4AB7-AB0A-485C3CB59545"
            let pincode = "560001"

            print("Starting upload of 1000 documents...")

            for i in 1...100 {
                let postData: [String: Any] = [
                    "caption": "Dummy Post \(i)",
                    "commentsCount": 0,
                    "likesCount": 0,
                    "ownerUid": ownerUid,
                    "cosntituencyId": pincode, // Note: "constituencyId" is misspelled as in your example
                    "timestamp": Timestamp(date: Date()) // Uses the current time for each post
                ]

                // addDocument creates a new document with a random, unique ID
                db.collection("constituencies").document(constituencyId).collection("news").addDocument(data: postData) { error in
                    if let error = error {
                        print("Error adding document \(i): \(error.localizedDescription)")
                    } else {
                        // To avoid flooding the console, we only print every 100th success message
                        if i % 100 == 0 {
                            print("Successfully uploaded document \(i) of 1000.")
                        }
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
