//
//  TrialView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//

//
//  TrialView.swift
//  (Your App Name)
//
//  Created by (Your Name) on (Date).
//

//  In your main App file...
//  In your main App file...
//
//  TrialView.swift
//  (Your App Name)
//
//  Created by (Your Name) on (Date).
//

import SwiftUI

// MARK: - DATA MODEL 1

struct Post1: Identifiable {
    let id = UUID()
    let username: String
    let profileImageName: String
    let postImageName: String
    let caption: String
    var likes: Int
    var isLiked: Bool = false
    var isBookmarked: Bool = false
    
    // Sample Data for the Feed
    static func mockPosts() -> [Post1] {
        return [
            Post1(username: "travel_adventures", profileImageName: "person.crop.circle.fill", postImageName: "photo.artframe", caption: "Exploring the hidden gems of the city. What an amazing view!", likes: 1245),
            Post1(username: "foodie_delight", profileImageName: "person.crop.square.filled.and.at.rectangle", postImageName: "cup.and.saucer.fill", caption: "This is the best cup of coffee I've ever had! ☕️ #coffee #morning", likes: 832, isLiked: true),
            Post1(username: "code_creator", profileImageName: "desktopcomputer", postImageName: "swift", caption: "Loving the new animations in SwiftUI. Making beautiful UI has never been easier.", likes: 2301, isBookmarked: true),
            Post1(username: "nature_lover", profileImageName: "leaf.fill", postImageName: "tree.fill", caption: "Finding peace in the heart of the forest. 🌲💚", likes: 1788),
            Post1(username: "urban_explorer", profileImageName: "building.2.crop.circle", postImageName: "tram.fill", caption: "City nights and bright lights.", likes: 950, isLiked: true, isBookmarked: true)
        ]
    }
}


// MARK: - MAIN FEED VIEW 1

struct TrialView1: View {
    // Note the change to Post1
    @State private var posts: [Post1] = Post1.mockPosts()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Using $posts to create bindings for each post
                    ForEach($posts) { $post in
                        // Note the change to PostView1
                        PostView1(post: $post)
                            .padding(.bottom, 10)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("News Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "camera")
                        .font(.title2)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "paperplane")
                        .font(.title2)
                }
            }
        }
    }
}

// MARK: - POST VIEW 1 (The main card for each post)

struct PostView1: View {
    @Binding var post: Post1 // Note the change to Post1
    @State private var hasAppeared: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PostHeaderView1(username: post.username, profileImageName: post.profileImageName)
            
            PostContentView1(post: $post)
            
            PostActionsView1(isLiked: $post.isLiked, isBookmarked: $post.isBookmarked, likes: $post.likes)
            
            PostDescriptionView1(likes: post.likes, username: post.username, caption: post.caption)
        }
        // Entry Animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}


// MARK: - UI COMPONENTS 1

struct PostHeaderView1: View {
    let username: String
    let profileImageName: String
    
    var body: some View {
        HStack {
            Image(systemName: profileImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .foregroundColor(.secondary)
            
            Text(username)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .font(.headline)
        }
        .padding(.horizontal)
    }
}

struct PostContentView1: View {
    @Binding var post: Post1 // Note the change to Post1
    @State private var showLikeAnimation: Bool = false

    var body: some View {
        ZStack {
            // Main Post Image
            Image(systemName: post.postImageName)
                .resizable()
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray5))
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 200)) // Use for SF Symbols
                .foregroundStyle(.white, .pink, .yellow) // Style SF Symbol colors

            // Animated Heart Overlay
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white.opacity(0.85))
                .shadow(radius: 5)
                .scaleEffect(showLikeAnimation ? 1.0 : 0)
                .opacity(showLikeAnimation ? 1 : 0)
                .animation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10).speed(1.5), value: showLikeAnimation)
        }
        .onTapGesture(count: 2) {
            triggerLikeAnimation()
        }
    }
    
    private func triggerLikeAnimation() {
        if !post.isLiked {
            post.isLiked = true
            post.likes += 1
        }
        
        showLikeAnimation = true
        // Hide the animated heart after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showLikeAnimation = false
        }
    }
}

struct PostActionsView1: View {
    @Binding var isLiked: Bool
    @Binding var isBookmarked: Bool
    @Binding var likes: Int

    var body: some View {
        HStack(spacing: 20) {
            // Like Button
            Button(action: {
                if isLiked {
                    likes -= 1
                } else {
                    likes += 1
                }
                isLiked.toggle()
            }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isLiked ? .red : .primary)
                    .scaleEffect(isLiked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isLiked)
            }
            
            Image(systemName: "message")
            Image(systemName: "paperplane")
            
            Spacer()
            
            // Bookmark Button
            Button(action: {
                isBookmarked.toggle()
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.primary)
                    .scaleEffect(isBookmarked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isBookmarked)
            }
        }
        .font(.title2)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}


struct PostDescriptionView1: View {
    let likes: Int
    let username: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(likes) likes")
                .font(.subheadline)
                .fontWeight(.bold)
            
            // Rich text for username and caption
            (
                Text(username)
                    .fontWeight(.bold)
                +
                Text(" ")
                +
                Text(caption)
            )
            .font(.subheadline)
            
            Text("View all 42 comments")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            
            Text("2 hours ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - PREVIEW 1

struct TrialView1_Previews: PreviewProvider {
    static var previews: some View {
        // Note the change to TrialView1
        TrialView1()
            .preferredColorScheme(.dark) // Preview in Dark Mode
        TrialView1()
            .preferredColorScheme(.light) // Preview in Light Mode
    }
}
