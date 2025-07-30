//
//  ReplyRowView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI

// 2. View for a Single Reply Row
struct ReplyRowView: View {
    let reply: Reply
    
    // User state management
    @State private var replyUser: CachedUser?
    @State private var isLoadingUser = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Profile Picture
            Group {
                if let user = replyUser {
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
                        .padding(4)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    // Username
                    Group {
                        if let user = replyUser {
                            Text(user.username)
                                .font(.system(size: 13, weight: .semibold))
                        } else if isLoadingUser {
                            Text("Loading...".localized())
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                        } else {
                            Text("Unknown User".localized())
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(reply.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text(reply.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.leading, 40) // Indent replies
        .padding(.vertical, 4)
        .task {
            await loadReplyUser()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadReplyUser() async {
        isLoadingUser = true
        
        // First check cache
        if let cachedUser = await UserCache.shared.getUser(userId: reply.userId) {
            await MainActor.run {
                self.replyUser = cachedUser
                self.isLoadingUser = false
            }
            return
        }
        
        // If not in cache, fetch from Firestore
        do {
            let fetchedUser = try await CommentsViewModel().fetchCurrentUser(reply.userId)
            let cachedUser = CachedUser(username: fetchedUser.username, profilePictureUrl: fetchedUser.profileImageUrl)
            
            await MainActor.run {
                self.replyUser = cachedUser
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
