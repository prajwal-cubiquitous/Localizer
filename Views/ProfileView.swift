//
//  ProfileView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    let pincode: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditingProfile = false
    @EnvironmentObject var AuthViewModel : AuthViewModel
    @State private var isRefreshing = false
    
    // Use a properly configured query to fetch the current user without any filters
    // This will show ALL users in the database, which should include our current user
    @Query private var localUsers: [LocalUser]
    
    // Add an onAppear action to debug what's happening
    @State private var debugMessage = ""
    
    // Computed property to safely get current user
    private var currentUser: LocalUser? {
        // Only return the user that matches the current session
        guard let sessionUserId = AppState.shared.userSession?.uid else {
            print("DEBUG: No session user ID available")
            return nil
        }
        
        let matchingUser = localUsers.first { $0.id == sessionUserId }
        
        if matchingUser == nil && !localUsers.isEmpty {
            print("DEBUG: No matching user found for session ID: \(sessionUserId)")
            print("DEBUG: Available user IDs: \(localUsers.map { $0.id })")
        }
        
        return matchingUser
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {                
                VStack(spacing: 20) {
                    // Header with profile image
                    VStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                            )
                            .padding(.bottom, 8)
                        
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
                    
                    // Posts section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Posts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                            ForEach(1...9, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.title)
                                            .foregroundStyle(.gray)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings and more section
                    VStack(spacing: 0) {
                        settingsRow(icon: "bookmark", title: "Saved Posts"){
                            
                        }
                        settingsRow(icon: "person.2", title: "Close Friends"){
                            
                        }
                        settingsRow(icon: "star", title: "Favorites"){
                            
                        }
                        settingsRow(icon: "gearshape", title: "Settings"){
                            
                        }
                        
                        // Development reset button (only in debug mode)
                        #if DEBUG
                        settingsRow(icon: "trash", title: "🔧 Clear All Local Data (Dev)"){
                            Task {
                                print("DEBUG: Manual clear all local data triggered")
                                AuthViewModel.clearLocalUser()
                                
                                // Verify the clear worked
                                let users = try? modelContext.fetch(FetchDescriptor<LocalUser>())
                                let news = try? modelContext.fetch(FetchDescriptor<LocalNews>())
                                let votes = try? modelContext.fetch(FetchDescriptor<LocalVote>())
                                
                                print("DEBUG: After manual clear - Users: \(users?.count ?? 0), News: \(news?.count ?? 0), Votes: \(votes?.count ?? 0)")
                            }
                        }
                        
                        // Development session info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🔧 Development Info")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("Session User: \(AppState.shared.userSession?.uid ?? "None")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("Local Users: \(localUsers.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            ForEach(localUsers.prefix(3), id: \.id) { user in
                                Text("• \(user.name) (\(String(user.id.prefix(8)))...)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        #endif
                        
                        settingsRow(icon: "arrow.left.square", title: "Logout"){
                            Task {
                                do {
                                    // First clear the local user data while we have access
                                    print("DEBUG: Starting logout process")
                                    AuthViewModel.clearLocalUser()
                                    
                                    // Add a small delay to ensure clearing completes
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                    
                                    // Then sign out of Firebase which will trigger the UI update
                                    print("DEBUG: Signing out of Firebase")
                                    AppState.shared.signOut()
                                    
                                } catch {
                                    print("ERROR: Logout process failed: \(error)")
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical)
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
            .onAppear {
                print("DEBUG: Profile tab appeared with modelContext: \(modelContext)")
                print("DEBUG: Found \(localUsers.count) local users")
                
                // Log details about each user for debugging
                for (index, user) in localUsers.enumerated() {
                    print("DEBUG: User \(index + 1): \(user.name) (ID: \(user.id))")
                }
                
                // Ensure AuthViewModel has the model context
                AuthViewModel.setModelContext(modelContext)
                
                // Check session consistency
                if let sessionUserId = AppState.shared.userSession?.uid {
                    print("DEBUG: Current session user ID: \(sessionUserId)")
                    
                    let hasMatchingUser = localUsers.contains { $0.id == sessionUserId }
                    
                    if localUsers.isEmpty {
                        print("DEBUG: No local users found - fetching current user")
                        AuthViewModel.fetchAndStoreUser(userId: sessionUserId)
                    } else if !hasMatchingUser {
                        print("DEBUG: Session user not in local storage - clearing and fetching")
                        Task {
                            await refreshUserData()
                        }
                    } else if localUsers.count > 1 {
                        print("WARNING: Multiple users found (\(localUsers.count)) - clearing extras")
                        Task {
                            await refreshUserData()
                        }
                    }
                } else {
                    print("DEBUG: No session user - user should be logged out")
                    if !localUsers.isEmpty {
                        print("DEBUG: Clearing stale user data")
                        AuthViewModel.clearLocalUser()
                    }
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
            print("DEBUG: No user session found during refresh")
            return
        }
        
        isRefreshing = true
        print("DEBUG: Refreshing user data for ID: \(userId)")
        
        // Check if the current user in the database matches the session user
        let currentUsers = try? modelContext.fetch(FetchDescriptor<LocalUser>())
        let currentUserIds = currentUsers?.map { $0.id } ?? []
        
        print("DEBUG: Current stored user IDs: \(currentUserIds)")
        print("DEBUG: Session user ID: \(userId)")
        
        // If the session user is different from stored users, clear all and fetch fresh
        if !currentUserIds.contains(userId) {
            print("DEBUG: Session user different from stored users, clearing all data")
            AuthViewModel.clearLocalUser()
        }
        
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
    @State private var name: String
    @State private var bio: String
    
    init(isPresented: Binding<Bool>, localUser: LocalUser, modelContext: ModelContext) {
        self._isPresented = isPresented
        self.localUser = localUser
        self.modelContext = modelContext
        self._name = State(initialValue: localUser.name)
        self._bio = State(initialValue: localUser.bio ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Profile image
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .padding(-4)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 5, y: 5)
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
                            }
                            localUser.name = name
                            localUser.bio = bio
                            
                            // Save the changes to SwiftData
                            do {
                                try modelContext.save()
                            } catch {
                                print("Error saving user profile: \(error.localizedDescription)")
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
