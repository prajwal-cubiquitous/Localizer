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
                            switch filter {
                            case .news:
                                Task{
                                    do{
                                        try await viewModel.fetchNews(postalCode: pincode)
                                    }catch{
                                        print(error.localizedDescription)
                                    }
                                }
                            case .liked:
                                Task{
                                    do{
                                        try await viewModel.fetchLikedNews()
                                    }catch{
                                        print(error.localizedDescription)
                                    }
                                }
                            case .commented:
                                Task{
                                    do{
                                        try await viewModel.commentedNews()
                                    }catch{
                                        print(error.localizedDescription)
                                    }
                                }
                            case .saved:
                                Task{
                                    do{
                                        try await viewModel.fetchSavedNews()
                                    }catch{
                                        print(error.localizedDescription)
                                    }
                                }
                                // Add more cases as needed
                            }
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
    }
}

// MARK: - SwiftUI Preview
struct NewsFeedView1_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(pincode: "560043")
    }
}
