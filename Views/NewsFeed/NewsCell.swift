//
//  NewsCell.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//

import SwiftUI
import FirebaseFirestore

struct NewsCell: View {
    let localNews: LocalNews
    @State private var voteState: VoteState = .none
    @State private var likesCount: Int = 0
    @State private var showingMenu: Bool = false
    
    // Animation states for button scaling
    @State private var upvoteScale: CGFloat = 1.0
    @State private var downvoteScale: CGFloat = 1.0
    
    enum VoteState {
        case upvoted, downvoted, none
    }
    
    init(localNews: LocalNews) {
        self.localNews = localNews
        self._likesCount = State(initialValue: localNews.likesCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info Header
            HStack {
                // Profile Image
                AsyncImage(url: URL(string: localNews.user?.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.secondary.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                                .font(.title2)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localNews.user?.username ?? "Unknown User")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Three Dots Menu
                Menu {
                    Button {
                        // Save post action
                    } label: {
                        Label("Save Post", systemImage: "bookmark")
                    }
                    
                    Button {
                        // Don't recommend action
                    } label: {
                        Label("Don't Recommend", systemImage: "hand.thumbsdown")
                    }
                    
                    Button {
                        // Maximize action
                    } label: {
                        Label("Maximize", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    
                    Button(role: .destructive) {
                        // Report post action
                    } label: {
                        Label("Report Post", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            
            // Post Content
            Text(localNews.caption)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Image Placeholder or Actual Image
            if let imageUrls = localNews.newsImageURLs, 
               let firstImageUrl = imageUrls.first, 
               !firstImageUrl.isEmpty {
                AsyncImage(url: URL(string: firstImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    imagePlaceholder
                }
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Interaction Buttons
            HStack(spacing: 24) {
                // Reddit-style Voting System
                HStack(spacing: 10) {
                    // Upvote Button
                    Button {
                        handleUpvote()
                    } label: {
                        Image(systemName: voteState == .upvoted ? "arrowshape.up.fill" : "arrowshape.up")
                            .foregroundColor(voteState == .upvoted ? .red : .secondary)
                            .font(.title3)
                            .scaleEffect(upvoteScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Vote Count
                    Text("\(likesCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // Downvote Button
                    Button {
                        handleDownvote()
                    } label: {
                        Image(systemName: voteState == .downvoted ? "arrowshape.down.fill" : "arrowshape.down")
                            .foregroundColor(voteState == .downvoted ? .purple : .secondary)
                            .font(.title3)
                            .scaleEffect(downvoteScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Comment Button
                Button {
                    // Comment action
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .foregroundColor(.secondary)
                            .font(.title3)
                        
                        Text("\(localNews.commentsCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Share Button
                Button {
                    // Share action
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .foregroundColor(.secondary)
                            .font(.title3)
                        
                        Text("Share")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
    
    // MARK: - Voting Functions
    
    private func handleUpvote() {
        // Scale animation
        withAnimation(.easeInOut(duration: 0.1)) {
            upvoteScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                upvoteScale = 1.0
            }
        }
        
        // Vote logic
        switch voteState {
        case .none:
            voteState = .upvoted
            likesCount += 1
        case .upvoted:
            voteState = .none
            likesCount -= 1
        case .downvoted:
            voteState = .upvoted
            likesCount += 2 // Remove downvote (-1) and add upvote (+1) = +2
        }
    }
    
    private func handleDownvote() {
        // Scale animation
        withAnimation(.easeInOut(duration: 0.1)) {
            downvoteScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                downvoteScale = 1.0
            }
        }
        
        // Vote logic
        switch voteState {
        case .none:
            voteState = .downvoted
            likesCount -= 1
        case .downvoted:
            voteState = .none
            likesCount += 1
        case .upvoted:
            voteState = .downvoted
            likesCount -= 2 // Remove upvote (+1) and add downvote (-1) = -2
        }
    }
    
    // Computed property for time ago
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: localNews.timestamp, relativeTo: Date())
    }
    
    // Image Placeholder View
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 200)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.6))
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        NewsCell(localNews: DummyLocalNews.News1)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
