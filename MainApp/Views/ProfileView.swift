//
//  ProfileView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditingProfile = false
    
    // Sample user data
    let user = User(
        name: "John Doe",
        username: "@johndoe",
        bio: "iOS Developer | Swift Enthusiast | Coffee Lover",
        postsCount: 48,
        followersCount: 1258,
        followingCount: 357
    )
    
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
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.username)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        
                        Text(user.bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(user.postsCount)")
                                    .font(.headline)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            
                            VStack {
                                Text("\(user.followersCount)")
                                    .font(.headline)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            
                            VStack {
                                Text("\(user.followingCount)")
                                    .font(.headline)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.top, 16)
                        
                        // Edit profile button
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
                        settingsRow(icon: "arrow.left.square", title: "Logout"){
                            print("logging out ")
                            AppState.shared.signOut()
                            print("logged out")
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(isPresented: $isEditingProfile, user: user)
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

}

// User model
struct User {
    let name: String
    let username: String
    let bio: String
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
}

// Edit profile view
struct EditProfileView: View {
    @Binding var isPresented: Bool
    let user: User
    
    @State private var name: String
    @State private var bio: String
    
    init(isPresented: Binding<Bool>, user: User) {
        self._isPresented = isPresented
        self.user = user
        self._name = State(initialValue: user.name)
        self._bio = State(initialValue: user.bio)
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
                        // Save profile changes
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
