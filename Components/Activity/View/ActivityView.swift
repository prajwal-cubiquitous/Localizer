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
    
    private var shouldShowEmptyState: Bool {
        if selectedFilter == .NoUser {
            return viewModel.UserItems.isEmpty
        } else {
            return viewModel.newsItems.isEmpty
        }
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
                if shouldShowEmptyState {
                    ActivityEmptyStateView(filter: selectedFilter)
                } else {
                    LocalNewsActivityListView(newsItems: viewModel.newsItems, selectedFilter: selectedFilter, userItems: viewModel.UserItems)
                }
            }
            .navigationTitle("My Activities")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: selectedFilter) {
            await fetchDataForFilter()
        }
    }
    
    private func fetchDataForFilter() async {
        guard !constituencyId.isEmpty else { return }
        
        do {
            switch selectedFilter {
            case .news:
                try await viewModel.fetchNews(constituencyId: constituencyId)
            case .liked:
                try await viewModel.fetchLikedNews(constituencyId: constituencyId)
            case .disliked:
                try await viewModel.fetchDisLikedNews(constituencyId: constituencyId)
            case .commented:
                try await viewModel.commentedNews(constituencyId: constituencyId)
            case .saved:
                try await viewModel.fetchSavedNews(constituencyId: constituencyId)
            case .NoNews:
                try await viewModel.fetchDontRecommendNews(constituencyId: constituencyId)
            case .NoUser:
                try await viewModel.fetchDontRecommendUsers()
            }
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
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
            
            Text("No \(filter.rawValue.lowercased()) yet".localized())
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start engaging with news to see your activity here!".localized())
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LocalNewsActivityListView: View {
    let newsItems: [LocalNews]
    var selectedFilter: ActivityView.FilterType
    let userItems: [User]
    
    // Create unique items to prevent duplicate IDs
    private var uniqueNewsItems: [LocalNews] {
        var seen = Set<String>()
        return newsItems.filter { item in
            if seen.contains(item.id) {
                return false
            } else {
                seen.insert(item.id)
                return true
            }
        }
    }
    
    var body: some View {
        if selectedFilter == .NoUser {
            // Show users in a proper List
            List(userItems, id: \.id) { user in
                Usercell(user: user)
            }
            .listStyle(PlainListStyle())
        } else {
            // Show news in ScrollView
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(uniqueNewsItems.enumerated()), id: \.offset) { index, item in
                        if selectedFilter == .NoNews {
                            NewsCell(localNews: item, recommendText: "Recommend")
                                .padding(.horizontal, 0)
                        } else {
                            NewsCell(localNews: item)
                                .padding(.horizontal, 0)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - SwiftUI Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(ConstituencyInfo: DummyConstituencyDetials.detials1)
    }
}
