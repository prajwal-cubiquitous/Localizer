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
    @State private var showingFullScreenMedia = false
    @StateObject private var viewModel = NewsCellViewModel()
    let localNews: LocalNews
    
    // User state management for non-current users
    @State private var newsAuthor: CachedUser?
    @State private var isLoadingAuthor = false
    
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
    
    private var hasMedia: Bool {
        guard let imageUrls = localNews.newsImageURLs else { return false }
        return !imageUrls.isEmpty
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
                Group {
                    if let user = localNews.user {
                        // Current user's news - use LocalUser data
                        ProfilePictureView(userProfileUrl: user.profileImageUrl, width: 44, height: 44)
                    } else if let author = newsAuthor {
                        // Other user's news - use cached data
                        ProfilePictureView(userProfileUrl: author.profilePictureUrl, width: 44, height: 44)
                    } else if isLoadingAuthor {
                        ProgressView()
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Username
                    Group {
                        if let user = localNews.user {
                            // Current user's news - use LocalUser data
                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        } else if let author = newsAuthor {
                            // Other user's news - use cached data
                            Text(author.username)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        } else if isLoadingAuthor {
                            Text("Loading...")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        } else {
                            Text("Unknown User")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
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
                    
                    // Show maximize option only when media is available
                    if hasMedia {
                        Button {
                            showingFullScreenMedia = true
                        } label: {
                            Label("Maximize", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                    
                    Menu {
                        Button("Don't recommend posts from this user") {
                            Task{
                                try await viewModel.DontRecommendUsers(newsUserId: localNews.ownerUid)
                            }
                        }
                        Button("Don't recommend this post") {
                            Task{
                                try await viewModel.DontRecommendNews(postId: localNews.id)
                            }
                        }
                    } label: {
                        Label("Don't Recommend", systemImage: "hand.thumbsdown.fill")
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
                    .onTapGesture {
                        showingFullScreenMedia = true
                    }
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
            
            // Load author data if not current user's news
            if localNews.user == nil {
                await loadNewsAuthor()
            }
        }
        .sheet(isPresented: $showingCommentsSheet) {
            CommentsView(localNews: localNews)
                .presentationDetents([.fraction(0.5),.fraction(0.7), .fraction(0.9)])
        }
        .fullScreenCover(isPresented: $showingFullScreenMedia) {
            if let imageUrls = localNews.newsImageURLs, !imageUrls.isEmpty {
                FullScreenMediaViewer(mediaURLs: imageUrls)
            }
        }
    }
    
    // MARK: - Voting Functions
    
    // Computed property for time ago
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: localNews.timestamp, relativeTo: Date())
    }
    
    // MARK: - Helper Methods
    
    /// Load news author data for non-current user's news
    private func loadNewsAuthor() async {
        isLoadingAuthor = true
        
        // First check cache
        if let cachedUser = await UserCache.shared.getUser(userId: localNews.ownerUid) {
            await MainActor.run {
                self.newsAuthor = cachedUser
                self.isLoadingAuthor = false
            }
            return
        }
        
        // If not in cache, the user should already be cached by the ViewModel
        // Just wait a moment and check again
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        if let cachedUser = await UserCache.shared.getUser(userId: localNews.ownerUid) {
            await MainActor.run {
                self.newsAuthor = cachedUser
                self.isLoadingAuthor = false
            }
        } else {
            await MainActor.run {
                self.isLoadingAuthor = false
            }
        }
    }
}

// MARK: - Full Screen Media Viewer
struct FullScreenMediaViewer: View {
    let mediaURLs: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    private var isVideo: Bool {
        guard currentIndex < mediaURLs.count else { return false }
        let urlString = mediaURLs[currentIndex].lowercased()
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]
        return videoExtensions.contains { ext in
            urlString.contains(".\(ext)") || urlString.range(of: "\\.\\(ext)[?&#]", options: .regularExpression) != nil
        } || urlString.contains("news_videos")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header with close button and counter
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if mediaURLs.count > 1 {
                        Text("\(currentIndex + 1) of \(mediaURLs.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Media Content
                TabView(selection: $currentIndex) {
                    ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, urlString in
                        FullScreenMediaItem(urlString: urlString)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if abs(value.translation.height) > abs(value.translation.width) {
                                dragOffset = value.translation
                                isDragging = true
                            }
                        }
                        .onEnded { value in
                            if abs(value.translation.height) > 100 {
                                dismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                    isDragging = false
                                }
                            }
                        }
                )
                .offset(y: dragOffset.height)
                .scaleEffect(isDragging ? 0.9 : 1.0)
                .animation(.spring(), value: isDragging)
                
                Spacer()
                
                // Page indicators for multiple media
                if mediaURLs.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<mediaURLs.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Full Screen Media Item
struct FullScreenMediaItem: View {
    let urlString: String
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    
    private var isVideo: Bool {
        let lowercaseURL = urlString.lowercased()
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]
        return videoExtensions.contains { ext in
            lowercaseURL.contains(".\(ext)") || lowercaseURL.range(of: "\\.\\(ext)[?&#]", options: .regularExpression) != nil
        } || lowercaseURL.contains("news_videos")
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isVideo {
                ZStack {
                    if let player = player, isVideoReady {
                        VideoPlayer(player: player)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        // Loading state for video
                        Rectangle()
                            .fill(Color.clear)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            )
                    }
                }
                .onAppear {
                    setupVideoPlayer()
                }
                .onDisappear {
                    player?.pause()
                }
            } else {
                // Image
                AsyncImage(url: URL(string: urlString)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    private func setupVideoPlayer() {
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                // Download video if needed
                let fileExtension = extractFileExtension(from: urlString)
                let fileName = "\(UUID().uuidString).\(fileExtension)"
                let localURL = try await MediaHandler.downloadMedia(from: url, fileName: fileName)
                
                await MainActor.run {
                    let asset = AVURLAsset(url: localURL)
                    let playerItem = AVPlayerItem(asset: asset)
                    player = AVPlayer(playerItem: playerItem)
                    player?.isMuted = false // Allow sound in full screen
                    isVideoReady = true
                }
            } catch {
                print("❌ Failed to setup video player: \(error)")
            }
        }
    }
    
    private func extractFileExtension(from urlString: String) -> String {
        if let url = URL(string: urlString) {
            let pathExtension = url.pathExtension
            if !pathExtension.isEmpty {
                return pathExtension
            }
        }
        
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]
        for ext in videoExtensions {
            if urlString.lowercased().contains(".\(ext)") {
                return ext
            }
        }
        
        return "mov"
    }
}

#Preview {
    VStack(spacing: 20) {
        NewsCell(localNews: DummyLocalNews.News3)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
