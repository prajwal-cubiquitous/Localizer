import SwiftUI
import FirebaseAuth

// 4. Main Comments View (Pop-up)
struct CommentsView: View {
    @StateObject var viewModel = CommentsViewModel()
    @State private var newCommentText: String = ""
    @State private var replyingToComment: Comment? = nil
    @State private var replyingToUser: CachedUser? = nil
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    let localNews: LocalNews
    @State var currentUser: User?
    
    init(localNews: LocalNews) {
        self.localNews = localNews
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.comments, id: \.actualId) { comment in
                        CommentRowView(
                            viewModel: viewModel,
                            newsId: localNews.id,
                            comment: comment,
                            onStartReply: {
                                startReply(to: comment)
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
                            
                            if let user = replyingToUser {
                                Text("@\(user.username)")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                            } else {
                                Text("@Loading...")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            Button {
                                replyingToComment = nil
                                replyingToUser = nil
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
                        ProfilePictureView(userProfileUrl: currentUser?.profileImageUrl, width: 40, height: 40)
                        
                        TextField(
                            replyingToComment == nil ? "Add a comment..." : "Write a reply to @\(replyingToUser?.username ?? "user")...", 
                            text: $newCommentText, 
                            axis: .vertical
                        )
                        .textFieldStyle(.plain)
                        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                        
                        Button {
                            Task {
                                let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedText.isEmpty else { return }
                                
                                if let targetComment = replyingToComment,
                                   let commentId = targetComment.actualId {
                                    do {
                                        try await viewModel.addReply(
                                            toNewsId: localNews.id,
                                            commentId: commentId,
                                            replyText: trimmedText
                                        )
                                        replyingToComment = nil
                                        replyingToUser = nil
                                    } catch {
                                        await MainActor.run {
                                            errorMessage = "Failed to add reply. Please try again."
                                            showingErrorAlert = true
                                        }
                                    }
                                } else {
                                    do {
                                        try await viewModel.addComment(toNewsId: localNews.id, commentText: trimmedText)
                                    } catch {
                                        await MainActor.run {
                                            errorMessage = "Failed to add comment. Please try again."
                                            showingErrorAlert = true
                                        }
                                    }
                                }
                                newCommentText = ""
                            }
                        } label: {
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
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear() {
                Task{
                    do {
                        guard let uid = Auth.auth().currentUser?.uid else { 
                            return 
                        }
                        let fetchedUser = try await viewModel.fetchCurrentUser(uid)
                        try await viewModel.fetchComments(forNewsId: localNews.id)
                        
                        // Ensure assignment happens on main actor
                        await MainActor.run {
                            self.currentUser = fetchedUser
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = "Failed to load comments. Please try again."
                            showingErrorAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func startReply(to comment: Comment) {
        replyingToComment = comment
        newCommentText = ""
        
        // Load user data for the comment we're replying to
        Task {
            if let cachedUser = await UserCache.shared.getUser(userId: comment.userId) {
                await MainActor.run {
                    self.replyingToUser = cachedUser
                }
            }
        }
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
            CommentsView(localNews: DummyLocalNews.News1)
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
