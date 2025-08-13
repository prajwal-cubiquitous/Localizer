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
    @Query private var newsItems: [LocalNews]
    @State private var showCreatePostSheet = false
    @State private var hasFetched = false
    @State private var selectedTab: NewsTab = .trending
    @State private var sortDescriptors: [SortDescriptor<LocalNews>] = [SortDescriptor(\LocalNews.timestamp, order: .reverse)]
        
    
    
    init(ConstituencyInfo: ConstituencyDetails?, pincode: String) {
        self.ConstituencyInfo = ConstituencyInfo
        self.pincode = pincode
        // Use constituencyId for filtering local news instead of pincode
        let constituencyId = ConstituencyInfo?.id ?? ""
        self._newsItems = Query(sort: sortDescriptors)
    }
    
    private var constituencyId: String {
        ConstituencyInfo?.id ?? ""
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Segmented Control
                customSegmentedControl
                
                // Content & Floating Button Overlay
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        if newsItems.isEmpty {
                            emptyStateView
                        } else {
                            newsFeedContent
                        }
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        if viewModel.count >= viewModel.maxLocalItems/viewModel.pageSize {
                            await viewModel.loadMoreReverse(context: modelContext, category: selectedTab)
                        } else {
                            await viewModel.refresh(for: constituencyId, context: modelContext, category: selectedTab)
                        }
                    }
                    
                    if !newsItems.isEmpty {
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
                await viewModel.fetchAndCacheNews(for: constituencyId, context: modelContext, category: selectedTab)
            }
        }
        .onChange(of: selectedTab) {
            
            if selectedTab == .trending {
                            sortDescriptors = [SortDescriptor(\LocalNews.likesCount, order: .reverse)]
                        } else {
                            sortDescriptors = [SortDescriptor(\LocalNews.timestamp, order: .reverse)]
                        }
            Task{
                await viewModel.fetchAndCacheNews(for: constituencyId, context: modelContext, category: selectedTab)

            }
        }
        .sheet(isPresented: $showCreatePostSheet) {
            if let constituency = ConstituencyInfo, let id = constituency.id {
                PostView(ConstituencyId: id, pincode: pincode)
            }
        }
    }
    
    // MARK: - Custom Segmented Control
    private var customSegmentedControl: some View {
        ZStack {
            // Background container
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            
            // Selection indicator
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width / 2)
                    .offset(x: selectedTab == .latest ? 0 : geometry.size.width / 2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            }
            .frame(height: 28)
            .padding(.horizontal, 1)
            .padding(.vertical, 1)
            
            // Tab buttons
            HStack(spacing: 0) {
                ForEach(NewsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .medium))
                                .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                            
                            Text(tab.localizedTitle)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .padding(.bottom, 1)
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
                        Text(selectedTab == .latest ? "No Recent Posts".localized() : "No Trending Posts".localized())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text(selectedTab == .latest ? "Be the first to share what's happening in your constituency!".localized() : "Posts with high engagement will appear here!".localized())
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
            await viewModel.refresh(for: constituencyId, context: modelContext, category: selectedTab)
        }
    }
    
    // MARK: - News Feed Content
    private var newsFeedContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(newsItems) { item in
                NewsCell(constituencyId: constituencyId, localNews: item)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 8)
                    .onAppear {
                        if item == newsItems.last {
                            Task {
                                await viewModel.loadMore(context: modelContext, category: selectedTab)
                            }
                        }
                    }
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
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
}

#Preview {
    NewsFeedView(ConstituencyInfo: DummyConstituencyDetials.detials1, pincode: "110001")
}
