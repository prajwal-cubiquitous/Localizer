//
//  CommentRowView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI

// 3. View for a Single Comment Row
struct CommentRowView: View {
    let constituencyId: String
    @State var islikedBYCurrentUser: Bool = false
    @ObservedObject var viewModel: CommentsViewModel
    let newsId: String
    let comment: Comment
    let onStartReply: () -> Void
    @State var replies: [Reply] = []
    @State var showReplies = false
    
    // User state management
    @State private var commentUser: CachedUser?
    @State private var isLoadingUser = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment content
            HStack(alignment: .top, spacing: 12) {
                // Profile Picture
                Group {
                    if let user = commentUser {
                        ProfilePictureView(userProfileUrl: user.profilePictureUrl, width: 30, height: 30)
                    } else if isLoadingUser {
                        ProgressView()
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Username
                        Group {
                            if let user = commentUser {
                                Text(user.username)
                                    .font(.system(size: 14, weight: .semibold))
                            } else if isLoadingUser {
                                Text("Loading...".localized())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            } else {
                                Text("Unknown User".localized())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(comment.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(comment.text)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Action Buttons: Like, Reply
                    HStack(spacing: 20) {
                        Button {
                            Task {
                                islikedBYCurrentUser.toggle()
                                await viewModel.toggleLike(for: comment, inNews: newsId, constituencyId: constituencyId)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: islikedBYCurrentUser ? "heart.fill" : "heart")
                                    .foregroundColor(islikedBYCurrentUser ? .red : .gray)
                                
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .task {
                            islikedBYCurrentUser = await viewModel.checkIfLiked(comment: comment, newsId: newsId, constituencyId: constituencyId)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onStartReply) {
                            Text("Reply".localized())
                                .font(.caption.weight(.medium))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            
            // Toggle Replies Button and Replies List
            if !replies.isEmpty {
                Button {
                    showReplies.toggle()
                } label: {
                    HStack {
                        Rectangle() // Little decorative line
                            .frame(width: 20, height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                        Text(showReplies ? "Hide replies".localized() : "View \(replies.count) \(replies.count == 1 ? "reply" : "replies")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .contentShape(Rectangle()) // Make the whole HStack tappable
                    .background(Color.clear)   // Prevent any background from blocking taps
                }
                .buttonStyle(.plain)
                .padding(.leading, 52) // Align with comment text (avatar width + spacing)
                .padding(.top, 4)
                
                if showReplies {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(replies) { reply in
                            ReplyRowView(reply: reply)
                        }
                    }
                    .padding(.top, 6) // Space between toggle button and replies
                }
            }
        }
        .task {
            // Load comment user data
            await loadCommentUser()
            
            // Load replies
            if let commentId = comment.actualId {
                do {
                    replies = try await viewModel.fetchReplies(forNewsId: newsId, commentId: commentId, constituencyId: constituencyId)
                } catch {
                    // Silently handle error - replies will remain empty
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCommentUser() async {
        isLoadingUser = true
        
        // First check cache
        if let cachedUser = await UserCache.shared.getUser(userId: comment.userId) {
            await MainActor.run {
                self.commentUser = cachedUser
                self.isLoadingUser = false
            }
            return
        }
        
        // If not in cache, fetch from Firestore
        do {
            let fetchedUser = try await viewModel.fetchCurrentUser(comment.userId)
            let cachedUser = CachedUser(username: fetchedUser.username, profilePictureUrl: fetchedUser.profileImageUrl)
            
            await MainActor.run {
                self.commentUser = cachedUser
                self.isLoadingUser = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingUser = false
            }
            // Silently handle error - will show "Unknown User"
        }
    }
}
