//
//  ActivityView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/9/25.
//
import SwiftUI

struct ActivityView: View {
    @StateObject var viewModel = ActivityViewModel()
    @State private var selectedFilter: FilterType = .news
    let ConstituencyInfo: ConstituencyDetails?
    
    enum FilterType: String, CaseIterable {
        case news = "News"
        case liked = "Liked"
        case disliked = "Disliked"
        case commented = "Commented"
        case saved = "Saved"
        case NoNews = "No News"
        case NoUser = "No User"
        
        var iconName: String {
            switch self {
            case .news: return "newspaper"
            case .liked: return "heart.fill"
            case .disliked: return "heart.slash"
            case .commented: return "message"
            case .saved: return "bookmark.fill"
            case .NoNews: return "nosign"
            case .NoUser: return "nosign"
            }
        }
    }
    
    private var constituencyId: String {
        ConstituencyInfo?.id ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            FilterTab(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
                
                // Content
                if viewModel.newsItems.isEmpty {
                    ActivityEmptyStateView(filter: selectedFilter)
                } else {
                    NewsListView(newsItems: viewModel.newsItems)
                }
            }
            .navigationTitle("My Activities")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: selectedFilter) {
            // ✅ Don't clear cache when switching tabs - preserve vote states
            guard !constituencyId.isEmpty else { return }
            
            switch selectedFilter {
            case .news:
                Task {
                    do {
                        try await viewModel.fetchNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }
            case .liked:
                Task {
                    do {
                        try await viewModel.fetchLikedNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }
                
            case .disliked:
                Task {
                    do {
                        try await viewModel.fetchDisLikedNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }
            case .commented:
                Task {
                    do {
                        try await viewModel.commentedNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }
            case .saved:
                Task {
                    do {
                        try await viewModel.fetchSavedNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }
            case .NoNews:
                Task {
                    do {
                        try await viewModel.fetchSavedNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }

            case .NoUser:
                Task {
                    do {
                        try await viewModel.fetchSavedNews(constituencyId: constituencyId)
                    } catch {
                        // Silent error handling
                    }
                }

            }
        }
    }
}

// MARK: - Supporting Views
struct FilterTab: View {
    let filter: ActivityView.FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    .opacity(isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityEmptyStateView: View {
    let filter: ActivityView.FilterType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: filter.iconName)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No \(filter.rawValue.lowercased()) yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start engaging with news to see your activity here!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NewsListView: View {
    let newsItems: [LocalNews]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(newsItems, id: \.id) { item in
                    NewsCell(localNews: item)
                        .padding(.horizontal, 0)
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - SwiftUI Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(ConstituencyInfo: DummyConstituencyDetials.detials1)
    }
}
