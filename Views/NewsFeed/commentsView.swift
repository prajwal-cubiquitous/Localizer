import SwiftUI
// Sample data


// 2. View for a Single Reply Row
struct ReplyRowView: View {
    let reply: Reply

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: reply.profileImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.gray)
                .padding(4)
                .background(Color.gray.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(reply.username)
                        .font(.system(size: 13, weight: .semibold))
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
    }
}


// 3. View for a Single Comment Row
struct CommentRowView: View {
    let comment: Comment
    let onToggleLike: () -> Void
    let onStartReply: () -> Void
    let onToggleRepliesVisibility: () -> Void // New closure

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment content
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: comment.profileImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.username)
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
                        Button(action: onToggleLike) {
                            HStack(spacing: 4) {
                                Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                                    .foregroundColor(comment.isLikedByCurrentUser ? .red : .gray)
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
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
            if !comment.replies.isEmpty {
                Button(action: onToggleRepliesVisibility) {
                    HStack {
                        Rectangle() // Little decorative line
                            .frame(width: 20, height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                        Text(comment.areRepliesVisible ? "Hide replies" : "View \(comment.replies.count) \(comment.replies.count == 1 ? "reply" : "replies")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 52) // Align with comment text (avatar width + spacing)
                .padding(.top, 4)

                if comment.areRepliesVisible {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(comment.replies) { reply in
                            ReplyRowView(reply: reply)
                        }
                    }
                    .padding(.top, 6) // Space between toggle button and replies
                }
            }
        }
    }
}

// 4. Main Comments View (Pop-up)
struct CommentsView: View {
    @StateObject var viewModel = CommentsViewModel()
    @State private var comments: [Comment] = getSampleComments()
    @State private var newCommentText: String = ""
    @State private var replyingToComment: Comment? = nil
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(comments) { comment in
                        CommentRowView(
                            comment: comment,
                            onToggleLike: {
                                toggleLike(for: comment.id)
                            },
                            onStartReply: {
                                startReply(to: comment)
                            },
                            onToggleRepliesVisibility: { // Pass the new function
                                toggleRepliesVisibility(for: comment.id)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .padding(.top)

                // Input area
                VStack(spacing: 0) {
                    if let targetComment = replyingToComment {
                        HStack {
                            Text("Replying to")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("@\(targetComment.username)")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            Spacer()
                            Button {
                                replyingToComment = nil
                                newCommentText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray5))
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)

                        TextField(replyingToComment == nil ? "Add a comment..." : "Write a reply to @\(replyingToComment!.username)...", text: $newCommentText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(20)
                            .lineLimit(1...5)

                        Button(action: submitInput) {
                            Text(replyingToComment == nil ? "Post" : "Send")
                                .font(.headline)
                                .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
                        }
                        .disabled(newCommentText.isEmpty)
                    }
                    .padding()
                    .background(.thinMaterial)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onTapGesture {
                 hideKeyboard()
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func toggleLike(for commentId: UUID) {
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].isLikedByCurrentUser.toggle()
            comments[index].likes += comments[index].isLikedByCurrentUser ? 1 : -1
        }
    }
    
    // New function to toggle reply visibility
    private func toggleRepliesVisibility(for commentId: UUID) {
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].areRepliesVisible.toggle()
        }
    }

    private func startReply(to comment: Comment) {
        replyingToComment = comment
        newCommentText = ""
        // Consider focusing TextField if possible
    }

    private func submitInput() {
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        if let targetComment = replyingToComment, let commentIndex = comments.firstIndex(where: { $0.id == targetComment.id }) {
            let newReply = Reply(username: "CurrentUser", text: trimmedText, profileImageName: "person.crop.circle.fill.badge.plus")
            comments[commentIndex].replies.append(newReply)
             // Optionally, make replies visible when a new one is added to this comment
            if !comments[commentIndex].areRepliesVisible {
                comments[commentIndex].areRepliesVisible = true
            }
        } else {
            let newComment = Comment(userId: "sfgisdihfsfbsfsdfsd", username: "CurrentUser", text: trimmedText, profileImageName: "person.crop.circle.fill.badge.plus")
            comments.append(newComment)
        }
        newCommentText = ""
        replyingToComment = nil
        hideKeyboard()
    }
}

// 5. Main Content View
struct ContentView_CommentDemo: View {
    @State private var showingCommentsSheet = false

    var body: some View {
        VStack {
            Image(systemName: "photo.artframe")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding()

            Text("Tap the button below to view comments.")
                .padding()

            Button {
                showingCommentsSheet = true
            } label: {
                Label("View Comments", systemImage: "message.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showingCommentsSheet) {
            CommentsView()
                .presentationDetents([.fraction(0.5),.fraction(0.7), .fraction(0.9)])
        }

    }
}

// Preview Provider
struct CommentUI_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_CommentDemo()
        // CommentsView() // For focused preview
    }
}
