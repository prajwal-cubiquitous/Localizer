//
//  ProfileView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import Kingfisher

struct ProfileView: View {
    let pincode: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditingProfile = false
    @EnvironmentObject var AuthViewModel : AuthViewModel
    @State private var isRefreshing = false
    @State private var hasFetchedUser = false
    
    // Use a properly configured query to fetch the current user without any filters
    // This will show ALL users in the database, which should include our current user
    @Query private var localUsers: [LocalUser]
    
    // Add an onAppear action to debug what's happening
    @State private var debugMessage = ""
    
    // Computed property to safely get current user
    private var currentUser: LocalUser? {
        return localUsers.first
    }
    @State private var path: [String] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with profile image
                    VStack {
                        ProfilePictureView(userProfileUrl: currentUser?.profileImageUrl, width: 100, height: 100)
                        if let user = currentUser {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            
                            if user.bio != ""{
                                Text(user.bio)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                            
                            // Stats
                            HStack(spacing: 40) {
                                VStack {
                                    Text("\(user.postCount)")
                                        .font(.headline)
                                    Text("Posts")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack {
                                    Text("\(user.likedCount)")
                                        .font(.headline)
                                    Text("Likes")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack {
                                    Text("\(user.dislikedCount)")
                                        .font(.headline)
                                    Text("Dislikes")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack {
                                    Text("\(user.commentCount)")
                                        .font(.headline)
                                    Text("Comments")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(.top, 16)
                        }
                        // Edit profile button
                        if currentUser != nil {
                            Button {
                                isEditingProfile = true
                            } label: {
                                Text("Edit Profile")
                                    .font(.headline)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .frame(width: 150, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
                                    )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    
                    // Settings and more section
                    VStack(spacing: 0) {
                        
                        settingsRow(icon: "gearshape", title: "Settings"){
                            
                        }
                        if currentUser?.id == "jWMfJAquzQfxbYLjuMbCxBUEk2q2" {
                            settingsRow(icon: "square.and.arrow.up.on.square", title: "UploadData"){
                                path.append("Upload")
                            }
                        }
                        settingsRow(icon: "arrow.left.square", title: "Logout"){
                            Task { @MainActor in
                                // ✅ Improved logout process with proper sequencing
                                // First clear the local user data
                                AuthViewModel.clearLocalUser()
                                
                                // Small delay to ensure data is cleared
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                                
                                // Then sign out of Firebase
                                AppState.shared.signOut()
                                
                                // Logout completed successfully
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .task {
                if !hasFetchedUser {
                    hasFetchedUser = true
                    await refreshUserData()
                }
            }
            .refreshable {
                await refreshUserData()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .sheet(isPresented: $isEditingProfile) {
                if let currentUser = currentUser {
                    EditProfileView(isPresented: $isEditingProfile, localUser: currentUser, modelContext: modelContext)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "Upload" {
                    UploadDataView()
                }
            }
        }
    }
    
    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Refreshes user data from Firestore and updates SwiftData using AuthViewModel's fetchAndStoreUserAsync function
    @MainActor
    private func refreshUserData() async {
        guard let userId = AppState.shared.userSession?.uid else {
            return
        }
        
        isRefreshing = true
        
        // Use the injected AuthViewModel instance to refresh user data with async method
        await self.AuthViewModel.fetchAndStoreUserAsync(userId: userId)
        
        isRefreshing = false
    }
}


// MARK: - Edit Profile View
struct EditProfileView: View {
    @Binding var isPresented: Bool
    var localUser: LocalUser
    var modelContext: ModelContext
    @EnvironmentObject var AuthViewModel: AuthViewModel
    @StateObject private var viewModel = EditProfileViewModel()
    
    // Form state
    @State private var name: String
    @State private var bio: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasChanges = false
    
    // Focus management
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, bio
    }
    
    init(isPresented: Binding<Bool>, localUser: LocalUser, modelContext: ModelContext) {
        self._isPresented = isPresented
        self.localUser = localUser
        self.modelContext = modelContext
        self._name = State(initialValue: localUser.name)
        self._bio = State(initialValue: localUser.bio)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Photo Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ZStack {
                                    if let selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 3)
                                            }
                                            .overlay(alignment: .bottomTrailing) {
                                                editBadge
                                            }
                                    } else {
                                        ProfilePictureView(userProfileUrl: localUser.profileImageUrl, width: 120, height: 120)
                                            .overlay(alignment: .bottomTrailing) {
                                                editBadge
                                            }
                                    }
                                }
                                .scaleEffect(isLoading ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isLoading)
                            }
                            .disabled(isLoading)
                            
                            Text("Tap to change photo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Profile Photo")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                // MARK: - Personal Information Section
                Section {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Name", systemImage: "person.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if name.count > 50 {
                                Text("\(name.count)/50")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        TextField("Enter your name", text: $name)
                            .focused($focusedField, equals: .name)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .bio
                            }
                            .onChange(of: name) { oldValue, newValue in
                                checkForChanges()
                                if newValue.count > 50 {
                                    name = String(newValue.prefix(50))
                                }
                            }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Bio Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Bio", systemImage: "text.alignleft")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(bio.count)/150")
                                .font(.caption2)
                                .foregroundStyle(bio.count > 150 ? .red : .secondary)
                        }
                        
                        TextField("Tell us about yourself", text: $bio, axis: .vertical)
                            .focused($focusedField, equals: .bio)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .lineLimit(4...8)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                            }
                            .onChange(of: bio) { oldValue, newValue in
                                checkForChanges()
                                if newValue.count > 150 {
                                    bio = String(newValue.prefix(150))
                                }
                            }
                    }
                    .padding(.vertical, 8)
                    
                } header: {
                    Text("Personal Information")
                        .font(.headline)
                        .foregroundStyle(.primary)
                } footer: {
                    Text("Your name and bio will be visible to other users.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Account Information Section (Read-only)
                Section {
                    HStack {
                        Label("Email", systemImage: "envelope.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(localUser.email)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                } header: {
                    Text("Account Information")
                        .font(.headline)
                        .foregroundStyle(.primary)
                } footer: {
                    Text("Your email address cannot be changed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismissView()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!hasChanges || isLoading || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .fontWeight(.medium)
                    }
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    loadingOverlay
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                loadSelectedImage()
            }
            .onAppear {
                checkForChanges()
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }
    
    // MARK: - UI Components
    private var editBadge: some View {
        Circle()
            .fill(.blue)
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Saving Profile...")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func checkForChanges() {
        let nameChanged = name.trimmingCharacters(in: .whitespacesAndNewlines) != localUser.name
        let bioChanged = bio.trimmingCharacters(in: .whitespacesAndNewlines) != localUser.bio
        let imageChanged = selectedImage != nil
        
        hasChanges = nameChanged || bioChanged || imageChanged
    }
    
    private func loadSelectedImage() {
        Task {
            if let data = try? await selectedItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = uiImage
                    checkForChanges()
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name cannot be empty"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Update profile data
                await AuthViewModel.updateUserProfile(
                    userID: localUser.id,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                // Upload profile image if selected
                if let selectedImage = selectedImage {
                    try await viewModel.uploadProfileImage(profileImage: selectedImage)
                }
                
                // Update local user
                await MainActor.run {
                    localUser.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    localUser.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Save to SwiftData
                    do {
                        try modelContext.save()
                    } catch {
                        errorMessage = "Failed to save locally: \(error.localizedDescription)"
                        showError = true
                    }
                    
                    isLoading = false
                    isPresented = false
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func dismissView() {
        if hasChanges {
            // Could add confirmation dialog here if needed
        }
        isPresented = false
    }
}

//#Preview {
//    ProfileView()
//}
