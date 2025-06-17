//
//  CommentRowView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI

// 3. View for a Single Comment Row
struct CommentRowView: View {
    @State var islikedBYCurrentUser:Bool = false
    @ObservedObject var viewModel: CommentsViewModel
    let newsId : String
    let comment: Comment
    let onStartReply: () -> Void
    @State var replies: [Reply] = []
    @State var showReplies = false
    
    // ✅ Add state for cached user data
    @State private var cachedUser: CachedUser?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment content
            HStack(alignment: .top, spacing: 12) {
                // ✅ Use cached user data
                if let cachedUser = cachedUser {
                    ProfilePictureView(userProfileUrl: cachedUser.profilePictureUrl, width: 30, height: 30)
                } else {
                    // Placeholder while loading
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // ✅ Use cached user data
                        Text(cachedUser?.username ?? "Loading...")
                            .font(.system(size: 14, weight: .semibold))
                        
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
                            Task{
                                islikedBYCurrentUser.toggle()
                                await viewModel.toggleLike(for: comment, inNews: newsId)
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
                        .task{
                            islikedBYCurrentUser = await viewModel.checkIfLiked(comment: comment, newsId: newsId)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onStartReply) {
                            Text("Reply")
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
                Button{
                    showReplies.toggle()
                }label:{
                    HStack {
                        Rectangle() // Little decorative line
                            .frame(width: 20, height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                        Text(showReplies ? "Hide replies" : "View \(replies.count) \(replies.count == 1 ? "reply" : "replies")")
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
            // ✅ Load user data on appear
            cachedUser = await UserCache.shared.getUser(userId: comment.userId)
            
            do{
                replies = try await viewModel.fetchReplies(forNewsId: newsId, commentId: comment.id.uuidString)
                
                // ✅ Use the new cacheUser method for replies
                for reply in replies {
                    let FetchedUser = try await viewModel.fetchCurrentUser(reply.userId)
                    UserCache.shared.cacheUser(
                        userId: reply.userId, 
                        cachedUser: CachedUser(username: FetchedUser.username, profilePictureUrl: FetchedUser.profileImageUrl)
                    )
                }
            }catch{
                // Silent error handling
            }
        }
    }
}
