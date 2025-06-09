import SwiftUI
// Sample data


// 2. View for a Single Reply Row
struct ReplyRowView: View {
    let reply: Reply
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let user = UserCache.shared.cacheusers[reply.userId]{
                Image(systemName: user.profilePictureUrl)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .padding(4)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }else{
                Image(systemName:"person.crop.circle.badge.questionmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .padding(4)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if let user = UserCache.shared.cacheusers[reply.userId]{
                        Text(user.username)
                            .font(.system(size: 13, weight: .semibold))
                    }else{
                        Text("Unkown User")
                            .font(.system(size: 13, weight: .semibold))
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
    }
}


// 3. View for a Single Comment Row
struct CommentRowView: View {
    @State var islikedBYCurrentUser:Bool = false
    @ObservedObject var viewModel: CommentsViewModel
    let newsId : String
    let comment: Comment
    let onStartReply: () -> Void
    @State var replies: [Reply] = []
    @State var showReplies = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment content
            HStack(alignment: .top, spacing: 12) {
                if let user = UserCache.shared.cacheusers[comment.userId]{
                    Image(systemName: user.profilePictureUrl)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                        .padding(5)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let user = UserCache.shared.cacheusers[comment.userId]{
                            Text(user.username)
                                .font(.system(size: 14, weight: .semibold))
                        }else{
                            Text("Unknown User")
                                .font(.system(size: 14, weight: .semibold))
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
            do{
                replies = try await viewModel.fetchReplies(forNewsId: newsId, commentId: comment.id.uuidString)
                
                for reply in replies {
                    let FetchedUser = try await viewModel.fetchCurrentUser(reply.userId)
                    
                    UserCache.shared.cacheusers[reply.userId] = CachedUser(username: FetchedUser.username, profilePictureUrl: FetchedUser.profileImageUrl)
                }
            }catch{
                print(error.localizedDescription)
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
    let localNews: LocalNews
    
    init(localNews: LocalNews) {
        self.localNews = localNews
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.comments) { comment in
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
                            if let user = UserCache.shared.cacheusers[targetComment.userId]{
                                Text("@\(user.username)")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                            }else{
                                Text("@Unknow")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                            }
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
                        
                        Button{
                            Task{
                                let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmedText.isEmpty else { return }
                                if let targetComment = replyingToComment {
                                    do {
                                        try await viewModel.addReply(
                                            toNewsId: localNews.id,
                                            commentId: targetComment.id.uuidString, // Must be String
                                            replyText: trimmedText
                                        )
                                        replyingToComment = nil
                                        
                                    } catch {
                                        print("Failed to add reply: \(error.localizedDescription)")
                                    }
                                }else{
                                    do {
                                        try await viewModel.addComment(toNewsId: localNews.id, commentText: trimmedText)
                                    } catch {
                                        print("Failed to add comment: \(error.localizedDescription)")
                                    }
                                }
                                newCommentText = ""
                            }
                        }label:{
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
        .task{
            do{
                try await viewModel.fetchComments(forNewsId: localNews.id)
            }catch{
                print("Error fetching comments: \(error)")
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func startReply(to comment: Comment) {
        replyingToComment = comment
        newCommentText = ""
        // Consider focusing TextField if possible
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
