//
//  NewsFeedView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//
import SwiftUI

struct ActivityView: View {
    @StateObject var viewModel = ActivityViewModel()
    @State private var selectedFilter: FilterType = .news
    let pincode: String
    enum FilterType: String, CaseIterable {
        case news = "News"
        case liked = "Liked"
        case disliked = "Disliked"
        case commented = "Commented"
        case saved = "Saved"
        
        var iconName: String {
            switch self {
            case .news: return "newspaper"
            case .liked: return "heart.fill"
            case .disliked: return "heart.slash"
            case .commented: return "message"
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
                List(viewModel.newsItems) { newsItem in
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
        .task(id: selectedFilter){
            switch selectedFilter {
            case .news:
                Task{
                    do{
                        try await viewModel.fetchNews(postalCode: pincode)
                    }catch{
                        // Silent error handling
                    }
                }
            case .liked:
                Task{
                    do{
                        try await viewModel.fetchLikedNews(postalCode: pincode)
                    }catch{
                        // Silent error handling
                    }
                }
                
            case .disliked:
                Task{
                    do{
                        try await viewModel.fetchDisLikedNews(postalCode: pincode)
                    }catch{
                        // Silent error handling
                    }
                }
            case .commented:
                Task{
                    do{
                        try await viewModel.commentedNews(postalCode: pincode)
                    }catch{
                        // Silent error handling
                    }
                }
            case .saved:
                Task{
                    do{
                        try await viewModel.fetchSavedNews(postalCode: pincode)
                    }catch{
                        // Silent error handling
                    }
                }
                // Add more cases as needed
            }
        }
    }
}

// MARK: - SwiftUI Preview
struct NewsFeedView1_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(pincode: "560043")
    }
}
