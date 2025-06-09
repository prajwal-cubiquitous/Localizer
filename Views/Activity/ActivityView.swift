//
//  NewsFeedView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//
import SwiftUI

struct ActivityView: View {
    @StateObject var viewModel = ActivityViewModel()
    @State private var selectedFilter: FilterType = .saved
    let pincode: String
    // Mock data for demonstration.
    let newsItems: [LocalNews] = [DummyLocalNews.News1, DummyLocalNews.News1, DummyLocalNews.News1, DummyLocalNews.News1]
    // Enum for the filter categories.
    enum FilterType: String, CaseIterable {
        case news = "My News"
        case liked = "Liked"
        case commented = "Commented"
        case saved = "Saved"
        
        var iconName: String {
            switch self {
            case .news: return "newspaper"
            case .liked: return "heart"
            case .commented: return "text.bubble"
            case .saved: return "bookmark.fill"
            }
        }
    }

    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                // MARK: - Filter Buttons
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        Button(action: {
                            self.selectedFilter = filter
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: filter.iconName)
                                    .font(.system(size: 22))
                                Text(filter.rawValue)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(width: 75, height: 75)
                            .background(selectedFilter == filter ? Color.primary : Color.primary.opacity(0.1))
                            .foregroundColor(selectedFilter == filter ? Color("primaryOpposite") : .primary)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding()

                // MARK: - News List
                List(newsItems) { newsItem in
                    NewsCell(localNews: newsItem)
                        .listRowInsets(EdgeInsets()) // Remove default padding
                        .listRowSeparator(.hidden) // Hide the default separator
                        .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .background(Color(UIColor.systemGray6))
            }
            .navigationTitle("My Activity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// A view for a single cell in the list.
struct NewsItemCell1: View {
    let newsItem: LocalNews
    
    @State private var voteCount: Int
    @State private var isUpvoted: Bool = false
    @State private var isDownvoted: Bool = false

    init(newsItem: LocalNews) {
        self.newsItem = newsItem
        _voteCount = State(initialValue: newsItem.likesCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(newsItem.caption)
                        .font(.headline)
                    // Using SwiftUI's built-in relative date style.
                    Text(newsItem.timestamp, style: .relative)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        + Text(" ago") // Append "ago" for clarity
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Caption
            Text(newsItem.caption)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Footer
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Button(action: { /* upvote logic */ }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isUpvoted ? .red : .gray)
                    }
                    Text("\(voteCount)")
                        .font(.subheadline).fontWeight(.bold)
                    Button(action: { /* downvote logic */ }) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isDownvoted ? .blue : .gray)
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                        Text("\(newsItem.commentsCount)")
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
    }
}


// MARK: - SwiftUI Preview
struct NewsFeedView1_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(pincode: "560043")
    }
}
