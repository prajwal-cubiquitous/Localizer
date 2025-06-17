//
//  NewsCell.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//

import SwiftUI
import FirebaseFirestore
import AVKit
import AVFoundation
import Combine
import ObjectiveC
import Network
import Kingfisher
import FirebaseStorage
import SwiftData

struct NewsCell: View {
    let localNews: LocalNews
    @ObservedObject var viewModel: NewsCellViewModel
    @State private var showingCommentsSheet = false
    
    // ✅ State for cached user data
    @State private var cachedUser: CachedUser?
    
    init(localNews: LocalNews) {
        self.localNews = localNews
        self.viewModel = NewsCellViewModel(localNews: localNews)
    }
    
    // MARK: - Computed Properties
    private var validProfileImageURL: URL? {
        guard let profileImageUrl = localNews.user?.profileImageUrl,
              !profileImageUrl.isEmpty,
              !profileImageUrl.hasPrefix("person."),  // Avoid SF Symbol names
              profileImageUrl.hasPrefix("http") else {
            return nil
        }
        return URL(string: profileImageUrl)
    }
    
    // Responsive padding based on device size
    private var horizontalPadding: CGFloat {
        // Use different padding for different screen sizes
        let screenWidth = UIScreen.main.bounds.width
        switch screenWidth {
        case 0..<375: // iPhone SE, Mini
            return 16
        case 375..<428: // iPhone 13, 14, 15 Standard
            return 20
        default: // iPhone Plus, Pro Max
            return 24
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Info Header
            HStack(spacing: 12) {
                // ✅ Profile Image from cached user
                ProfilePictureView(
                    userProfileUrl: cachedUser?.profilePictureUrl,
                    width: 44, 
                    height: 44
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    // ✅ Name from cached user
                    Text(cachedUser?.username ?? "Unknown User")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Three Dots Menu
                Menu {
                    Button {
                        Task{
                            if viewModel.savedByCurrentUser{
                                try await viewModel.removeSavedNews1(postId: localNews.id)
                                viewModel.savedByCurrentUser = false
                            }else{
                                try await viewModel.savePost1(postId: localNews.id)
                                viewModel.savedByCurrentUser = true
                            }
                        }
                    } label: {
                        Label(viewModel.savedByCurrentUser ? "Unsave Post" : "Save Post", systemImage: viewModel.savedByCurrentUser ? "bookmark.slash" :"bookmark")
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
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            
            // Post Content
            if !localNews.caption.isEmpty {
                Text(localNews.caption)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4) // Slight indent for content
            }
            
            // Media Gallery - Display all media items
            if let imageUrls = localNews.newsImageURLs, !imageUrls.isEmpty {
                MediaGalleryView(mediaURLs: imageUrls)
                    .padding(.vertical, 4)
            }
            
            // Interaction Buttons
            HStack(spacing: 24) {
                // Reddit-style Voting System
                HStack(spacing: 12) {
                    // Upvote Button
                    Button {
                        Task{
                            await viewModel.handleUpvote(postId: localNews.id)
                        }
                    } label: {
                        Image(systemName: viewModel.voteState == .upvoted ? "arrowshape.up.fill" : "arrowshape.up")
                            .foregroundColor(viewModel.voteState == .upvoted ? .red : .secondary)
                            .font(.title3)
                            .scaleEffect(viewModel.upvoteScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Vote Count
                    Text("\(viewModel.likesCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .monospacedDigit() // Prevents layout jumping
                    
                    // Downvote Button
                    Button {
                        Task{
                            await viewModel.handleDownvote(postId: localNews.id)
                        }
                    } label: {
                        Image(systemName: viewModel.voteState == .downvoted ? "arrowshape.down.fill" : "arrowshape.down")
                            .foregroundColor(viewModel.voteState == .downvoted ? .purple : .secondary)
                            .font(.title3)
                            .scaleEffect(viewModel.downvoteScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Comment Button
                Button {
                    showingCommentsSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message")
                            .foregroundColor(.secondary)
                            .font(.title3)
                        
                        Text("\(localNews.commentsCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Share Button
                Button {
                    // Share action
                } label: {
                    HStack(spacing: 8) {
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
            .padding(.top, 4)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, 16) // Outer margin from screen edges
        .task {
            // ✅ Fetch user data from cache
            cachedUser = await UserCache.shared.getUser(userId: localNews.ownerUid)
            
            await viewModel.fetchVotesStatus(postId: localNews.id)
            await viewModel.checkIfNewsIsSaved1(postId: localNews.id)
        }
        .sheet(isPresented: $showingCommentsSheet) {
            CommentsView(localNews: localNews)
                .presentationDetents([.fraction(0.5),.fraction(0.7), .fraction(0.9)])
        }
    }
    
    // MARK: - Voting Functions
    
    // Computed property for time ago
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: localNews.timestamp, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 20) {
        NewsCell(localNews: DummyLocalNews.News3)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
