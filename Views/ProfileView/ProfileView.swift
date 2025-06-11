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
                        ProfilePictureView(currentUser: currentUser, width: 100, height: 100)
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
                            Task {
                                // First clear the local user data while we have access
                                AuthViewModel.clearLocalUser()
                                // Then sign out of Firebase which will trigger the UI update
                                AppState.shared.signOut()
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
    
    /// Refreshes user data from Firestore and updates SwiftData using AuthViewModel's fetchAndStoreUser function
    @MainActor
    private func refreshUserData() async {
        guard let userId = AppState.shared.userSession?.uid else {
            return
        }
        
        isRefreshing = true
        
        // Use the injected AuthViewModel instance to refresh user data
        self.AuthViewModel.fetchAndStoreUser(userId: userId)
        
        // Small delay to allow the UI to update (can be removed if not needed)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        isRefreshing = false
    }
}


// Edit profile view
struct EditProfileView: View {
    @Binding var isPresented: Bool
    var localUser: LocalUser
    var modelContext: ModelContext
    @EnvironmentObject var AuthViewModel : AuthViewModel
    @StateObject private var viewModel = EditProfileViewModel()
    @State private var name: String
    @State private var bio: String
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    init(isPresented: Binding<Bool>, localUser: LocalUser, modelContext: ModelContext) {
        self._isPresented = isPresented
        self.localUser = localUser
        self.modelContext = modelContext
        self._name = State(initialValue: localUser.name)
        self._bio = State(initialValue: localUser.bio)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Profile image
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 3)
                            )
                    }
                    else {
                        ProfilePictureView(currentUser: localUser, width: 100, height: 100)
                    }
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
                }
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                        
                        TextField("Name", text: $name)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                        
                        TextEditor(text: $bio)
                            .frame(height: 100)
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            // Update the LocalUser with new values
                            Task{
                                await  AuthViewModel.updateUserProfile(userID: localUser.id, name: name, bio: bio)
                                if let selectedImage = selectedImage {
                                    try await viewModel.uploadProfileImage(profileImage: selectedImage)
                                }
                            }
                            localUser.name = name
                            localUser.bio = bio
                            
                            // Save the changes to SwiftData
                            do {
                                try modelContext.save()
                            } catch {
                            }
                            
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    ProfileView()
//}
