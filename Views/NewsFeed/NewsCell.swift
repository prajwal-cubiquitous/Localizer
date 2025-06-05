//
//  NewsCell.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/4/25.
//

import SwiftUI
import FirebaseFirestore

struct NewsCell: View {
    @State private var showingCommentsSheet = false
    @StateObject private var viewModel = NewsCellViewModel()
    let localNews: LocalNews
    
    
    init(localNews: LocalNews) {
        self.localNews = localNews
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
                    Text(localNews.user?.name ?? "Unknown User")
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
        .task {
            await viewModel.fetchVotesStatus(postId: localNews.id)
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
