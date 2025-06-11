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

struct NewsCell: View {
    @State private var showingCommentsSheet = false
    @StateObject private var viewModel = NewsCellViewModel()
    let localNews: LocalNews
    
    init(localNews: LocalNews) {
        self.localNews = localNews
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
                // Profile Image
                AsyncImage(url: validProfileImageURL) { image in
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localNews.user?.name ?? "Unknown User")
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

// MARK: - Media Gallery Component
struct MediaGalleryView: View {
    let mediaURLs: [String]
    @State private var currentIndex = 0
    
    // Responsive media height based on screen size
    private var mediaHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 64 // Account for margins and padding
        
        // Maintain 16:9 aspect ratio but with reasonable limits
        let calculatedHeight = availableWidth * 9 / 16
        return min(max(calculatedHeight, 200), 320) // Between 200-320pt
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if mediaURLs.count == 1 {
                // Single media item - ensure consistent height and proper video handling
                let urlString = mediaURLs[0]
                
                if urlString.contains("news_videos") {
                    // Single Video - use proper frame constraints
                    if let videoUrl = URL(string: urlString) {
                        VideoPlayer(player: AVPlayer(url: videoUrl))
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Rectangle()
                            .fill(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Text("Invalid video URL")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            )
                    }
                } else {
                    // Single Image
                    KFImage(URL(string: urlString))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: mediaHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // Multiple media items - use TabView
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, urlString in
                            MediaItemView(urlString: urlString, height: mediaHeight)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: mediaHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Page indicators for multiple items
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            // Custom page indicators
                            HStack(spacing: 6) {
                                ForEach(0..<mediaURLs.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Media counter
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(currentIndex + 1) of \(mediaURLs.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Capsule())
                                .padding(.trailing, 12)
                                .padding(.top, 12)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Individual Media Item Component  
struct MediaItemView: View {
    let urlString: String
    let height: CGFloat
    
    var body: some View {
        if urlString.contains("news_videos") {
            // Video Player for TabView
            if let videoUrl = URL(string: urlString) {
                VideoPlayer(player: AVPlayer(url: videoUrl))
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .background(Color.black)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .overlay(
                        Text("Invalid video URL")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
        } else {
            // Image for TabView
            KFImage(URL(string: urlString))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: height)
                .clipped()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NewsCell(localNews: DummyLocalNews.News1)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
