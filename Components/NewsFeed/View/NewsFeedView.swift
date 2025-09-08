//
//  NewsFeedView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import SwiftData

struct NewsFeedView: View {
    let ConstituencyInfo: ConstituencyDetails?
    let pincode: String
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NewsFeedViewModel()
    
    @State private var showCreatePostSheet = false
    @State private var hasFetched = false
    @State private var selectedTab: NewsTab = .latest
    
    // SwiftData query for reactive updates
    @Query private var allNews: [LocalNews]
    
    init(ConstituencyInfo: ConstituencyDetails?, pincode: String) {
        self.ConstituencyInfo = ConstituencyInfo
        self.pincode = pincode
    }
    
    private var constituencyId: String {
        ConstituencyInfo?.id ?? ""
    }
    
    // Computed property for filtered and sorted news
    private var filteredNews: [LocalNews] {
        let sortedNews: [LocalNews]
        
        switch selectedTab {
        case .latest:
            sortedNews = allNews.sorted { $0.timestamp > $1.timestamp }
        case .trending:
            sortedNews = allNews.sorted { $0.likesCount > $1.likesCount }
        case .City:
            sortedNews = allNews.sorted { $0.likesCount > $1.likesCount }
        }
        
        return sortedNews
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Segmented Control
                modernSegmentedControl
                
                // Content & Floating Button Overlay
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        if filteredNews.isEmpty && !viewModel.isLoading {
                            emptyStateView
                        } else {
                            newsFeedContent
                        }
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await viewModel.refresh(context: modelContext, category: selectedTab)
                    }
                    
                    if !filteredNews.isEmpty {
                        floatingActionButton
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .background(backgroundColor)
        }
        .task {
            if !hasFetched {
                hasFetched = true
                await viewModel.loadInitial(for: constituencyId, context: modelContext, category: selectedTab)
            }
        }
        .onChange(of: selectedTab) {
            Task {
                await viewModel.loadInitial(for: constituencyId, context: modelContext, category: selectedTab)
            }
        }
        .sheet(isPresented: $showCreatePostSheet) {
            if let constituency = ConstituencyInfo, let id = constituency.id {
                PostView(ConstituencyId: id, pincode: pincode)
            }
        }
    }
    

    
    // MARK: - Modern Segmented Control
    private var modernSegmentedControl: some View {
        ZStack {
            // Background container with subtle shadow
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
                )
            
            // Selection indicator (behind the text)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width / 3)
                    .offset(x: getSelectionOffset(for: selectedTab, in: geometry.size.width))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            }
            .frame(height: 32)
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            
            // Tab buttons (on top of the indicator)
            HStack(spacing: 0) {
                ForEach(NewsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .medium))
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                            
                            Text(tab.localizedTitle)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(height: 36)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // Helper function to calculate selection offset for 3 tabs
    private func getSelectionOffset(for tab: NewsTab, in width: CGFloat) -> CGFloat {
        switch tab {
        case .latest:
            return 0
        case .trending:
            return width / 3
        case .City:
            return (width / 3) * 2
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                
                // Icon and Title
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: selectedTab.icon)
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text(getEmptyStateTitle())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text(getEmptyStateMessage())
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Action Button
                Button {
                    showCreatePostSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Create Post".localized())
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                
                Spacer(minLength: 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 20)
        }
        .refreshable {
            await viewModel.refresh( context: modelContext, category: selectedTab)
        }
    }
    
    // Helper functions for empty state content
    private func getEmptyStateTitle() -> String {
        switch selectedTab {
        case .latest:
            return "No Recent Posts".localized()
        case .trending:
            return "No Trending Posts".localized()
        case .City:
            return "No City Posts".localized()
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch selectedTab {
        case .latest:
            return "Be the first to share what's happening in your constituency!".localized()
        case .trending:
            return "Posts with high engagement will appear here!".localized()
        case .City:
            return "Share news and updates about your city!".localized()
        }
    }
    
    // MARK: - News Feed Content
    private var newsFeedContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredNews) { item in
                NewsCell(constituencyId: constituencyId, localNews: item, selectedTab: selectedTab)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 8)
                    .onAppear {
                        // Load more when reaching the last item
                        if item == filteredNews.last && viewModel.hasMorePages && !viewModel.isLoadingMore {
                            Task {
                                await viewModel.loadMore(context: modelContext, category: selectedTab)
                            }
                        }
                    }
            }
            
            // Loading indicator at the bottom
            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 20)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        Button {
            showCreatePostSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(showCreatePostSheet ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCreatePostSheet)
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
}

#Preview {
    NewsFeedView(ConstituencyInfo: DummyConstituencyDetials.detials1, pincode: "110001")
}
