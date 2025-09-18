//
//  ProfileView.swift
//  Localizer
//
//  Created on 5/28/25.
//

// ProfileView.swift

import SwiftUI
import SwiftData
import PhotosUI
import Kingfisher
import FirebaseAuth

struct ProfileView: View {
    let pincode: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditingProfile = false
    @EnvironmentObject var AuthViewModel : AuthViewModel
    // ADDED: Get the LanguageManager from the environment
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isRefreshing = false
    @State private var hasFetchedUser = false
    @Binding var constituencies : [ConstituencyDetails]?
    @Binding var selectedName: String
    @Query private var localUsers: [LocalUser]
    @State private var showSettings = false
    
    private var currentUser: LocalUser? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        return localUsers.first { $0.id == currentUserId }
    }
    
    @State private var path: [String] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            // MODIFIED: Replaced ScrollView with Form for better settings layout
            Form {
                // Profile Header Section
                Section {
                    if let user = currentUser {
                        VStack {
                            ProfilePictureView(userProfileUrl: user.profileImageUrl, width: 100, height: 100)
                            
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            
                            if !user.bio.isEmpty {
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
                                    // MODIFIED: Localized string
                                    Text("posts".localized())
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack {
                                    Text("\(user.likedCount)")
                                        .font(.headline)
                                    // MODIFIED: Localized string
                                    Text("likes".localized())
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack {
                                    Text("\(user.dislikedCount)")
                                        .font(.headline)
                                    // MODIFIED: Localized string
                                    Text("dislikes".localized())
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack {
                                    Text("\(user.commentCount)")
                                        .font(.headline)
                                    // MODIFIED: Localized string
                                    Text("comments".localized())
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(.top, 16)
                            
                            // Edit profile button
                            Button {
                                isEditingProfile = true
                            } label: {
                                // MODIFIED: Localized string
                                Text("Edit Profile".localized())
                                    .font(.headline)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .frame(maxWidth: .infinity, minHeight: 40) // Make button wider
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
                                    )
                            }
                            .padding(.top, 16)
                        }
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            // MODIFIED: Localized string
                            Text("Loading Profile...".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 200)
                    }
                }
                .listRowBackground(Color.clear) // Make section background transparent
                
                // Constituency Picker Section
                if let list = constituencies {
                    Section {
                        StylishPicker(list: list, selectedName: $selectedName)
                    } header: {
                        // MODIFIED: Localized string
                        Text("Select Constituency".localized())
                    }
                }
                
                // Settings Section
                Section {
                    Picker("Language".localized(), selection: $languageManager.currentLanguage) { // "Language" is a key in your file now
                        ForEach(Language.allCases, id: \.self) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    
                    // MODIFIED: Use the keys exactly as they appear in your strings file
                    settingsRow(icon: "gearshape", title: "Settings".localized()){ // Key is "Settings"
                        // Settings functionality
                        showSettings = true
                    }
                    
                    if currentUser?.id == "jWMfJAquzQfxbYLjuMbCxBUEk2q2" {
                        settingsRow(icon: "square.and.arrow.up.on.square", title: "Upload Data".localized()){ // Key is "Upload Data"
                            path.append("Upload")
                        }
                    }
                    
                    settingsRow(icon: "arrow.left.square", title: "Logout".localized()){ // Key is "Logout"
                        Task { @MainActor in
                            AuthViewModel.clearAllLocalData()
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            AppState.shared.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Profile".localized())
            .task {
                if !hasFetchedUser {
                    hasFetchedUser = true
                    await refreshUserData()
                }
            }
            .refreshable {
                await refreshUserData()
            }
            // MODIFIED: Localized string
            .navigationTitle("profile_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditingProfile) {
                if let currentUser = currentUser {
                    // Remember to localize strings inside EditProfileView as well
                    EditProfileView(isPresented: $isEditingProfile, localUser: currentUser, modelContext: modelContext)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "Upload" {
                    UploadDataView()
                }
            }
            .sheet(isPresented: $showSettings) {
                    SettingsView()
            }
            .presentationDetents([.fraction(0.8)])
        }
    }
    
    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    @MainActor
    private func refreshUserData() async {
        guard let userId = AppState.shared.userSession?.uid else {
            print("❌ No current user session for profile refresh")
            return
        }
        isRefreshing = true
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
                
                // Upload profile image if selected (and delete old one)
                if let selectedImage = selectedImage {
                    let oldImageUrl = localUser.profileImageUrl // Get current image URL
                    try await viewModel.uploadProfileImage(profileImage: selectedImage, oldImageUrl: oldImageUrl)
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
