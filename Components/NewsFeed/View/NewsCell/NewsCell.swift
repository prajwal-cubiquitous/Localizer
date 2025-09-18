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
    let constituencyId : String
    @State private var showingCommentsSheet = false
    @State private var showingFullScreenMedia = false
    @StateObject private var viewModel = NewsCellViewModel()
    let localNews: LocalNews
    let recommendText : String?
    let seledtedTab: NewsTab?
    // User state management for non-current users
    @State private var newsAuthor: CachedUser?
    @State private var isLoadingAuthor = false
    
    // Performance optimization: cache computed values
    @State private var cachedTimeAgo: String = ""
    
    // Read More functionality
    @State private var isExpanded = false
    @State private var needsTruncation = false
    private let maxLines = 3 // Maximum lines before showing "Read More"
    
    init(constituencyId : String,localNews: LocalNews, recommendText: String? = nil, selectedTab: NewsTab? = .latest) {
        self.constituencyId = constituencyId
        self.localNews = localNews
        self.recommendText = recommendText
        self.seledtedTab = selectedTab
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
                            Text("Loading...".localized())
                                .font(.headline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        } else {
                            Text("Unknown User".localized())
                                .font(.headline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    Text(cachedTimeAgo)
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
                        Label(viewModel.savedByCurrentUser ? "Unsave Post".localized() : "Save Post".localized(), systemImage: viewModel.savedByCurrentUser ? "bookmark.slash" :"bookmark")
                    }
                    
                    // Show maximize option only when media is available
                    if hasMedia {
                        Button {
                            showingFullScreenMedia = true
                        } label: {
                            Label("Maximize".localized(), systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                    
                    if recommendText != nil{
                        Button {
                            Task{
                                try await viewModel.removeNOTRecommendNews(postId: localNews.id)
                            }
                        } label: {
                            Label(recommendText!, systemImage: "hand.thumbsup.fill")
                        }
                    }else{
                        Menu {
                            Button("Don't recommend posts from this user".localized()) {
                                Task{
                                    try await viewModel.DontRecommendUsers(newsUserId: localNews.ownerUid)
                                }
                            }
                            Button("Don't recommend this post".localized()) {
                                Task{
                                    try await viewModel.DontRecommendNews(postId: localNews.id)
                                }
                            }
                        } label: {
                            Label("Don't Recommend".localized(), systemImage: "hand.thumbsdown.fill")
                        }

                    }
                    
                    Button(role: .destructive) {
                        // Report post action
                    } label: {
                        Label("Report Post".localized(), systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            
            // Post Content with Read More functionality
            if !localNews.caption.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        // Background text to measure if truncation is needed
                        Text(localNews.caption)
                            .font(.body)
                            .foregroundColor(.clear)
                            .multilineTextAlignment(.leading)
                            .lineLimit(maxLines)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            // Check if text is truncated by comparing heights
                                            let textSize = localNews.caption.boundingRect(
                                                with: CGSize(width: geometry.size.width, height: .greatestFiniteMagnitude),
                                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                                                context: nil
                                            )
                                            
                                            let lineHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight
                                            let maxHeight = lineHeight * CGFloat(maxLines)
                                            
                                            DispatchQueue.main.async {
                                                needsTruncation = textSize.height > maxHeight
                                            }
                                        }
                                }
                            )
                        
                        // Visible text
                        Text(localNews.caption)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : maxLines)
                            .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    }
                    .padding(.horizontal, 4) // Slight indent for content
                    
                    // Read More/Read Less button
                    if needsTruncation {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Read Less".localized() : "Read More".localized())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
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
            if seledtedTab != .City{
                HStack(spacing: 24) {
                    // Reddit-style Voting System
                    HStack(spacing: 12) {
                        // Upvote Button
                        Button {
                            Task{
                                await viewModel.handleUpvote(postId: localNews.id, constituencyId: constituencyId)
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
                                await viewModel.handleDownvote(postId: localNews.id, constituencyId: constituencyId)
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
                            
                            Text("Share".localized())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 4)
            }
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
            // Cache time ago calculation
            cachedTimeAgo = timeAgo
            
            await viewModel.fetchVotesStatus(postId: localNews.id, constituencyId: constituencyId)
            await viewModel.checkIfNewsIsSaved1(postId: localNews.id)
            
            // Load author data if not current user's news
            if localNews.user == nil {
                await loadNewsAuthor()
            }
        }
        .sheet(isPresented: $showingCommentsSheet) {
            CommentsView(constituencyId: constituencyId, localNews: localNews)
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
                // Silently handle video player setup errors
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
        NewsCell(constituencyId: "346C4917-471E-4AB7-AB0A-485C3CB59545", localNews: DummyLocalNews.News3)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
