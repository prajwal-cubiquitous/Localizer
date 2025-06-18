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
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NewsFeedViewModel()
    @Query private var newsItems: [LocalNews]
    @State private var showCreatePostSheet = false
    @State private var hasAppeared = false

    init(ConstituencyInfo: ConstituencyDetails?) {
        self.ConstituencyInfo = ConstituencyInfo
        // Use constituencyId for filtering local news instead of pincode
        let constituencyId = ConstituencyInfo?.id ?? ""
        _newsItems = Query(filter: #Predicate<LocalNews> { news in
            news.constituencyId == constituencyId
        }, sort: [SortDescriptor(\LocalNews.timestamp, order: .reverse)])
    }
    
    private var constituencyId: String {
        ConstituencyInfo?.id ?? ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Color
                (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                    .ignoresSafeArea(.all)
                
                Group {
                    if viewModel.isLoading && newsItems.isEmpty {
                        // ✅ Skeleton loading state (Instagram-style)
                        VStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonNewsCell()
                                    .padding(.horizontal, 12)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                    } else if newsItems.isEmpty && !viewModel.isLoading {
                        // ✅ Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No news yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Be the first to share news in your area!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button("Create Post") {
                                showCreatePostSheet = true
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    } else {
                        // ✅ News list (Instagram-style performance optimized)
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(newsItems.enumerated()), id: \.element.id) { index, item in
                                    NewsCell(localNews: item)
                                        .padding(.horizontal, 0) // NewsCell handles its own horizontal padding
                                        .padding(.bottom, 8) // Space between news items
                                        .onAppear {
                                            // ✅ Optimized load more trigger - only check near end
                                            if index >= newsItems.count - 3 {
                                                Task {
                                                    await viewModel.loadMoreIfNeeded(
                                                        for: constituencyId,
                                                        context: modelContext,
                                                        currentItem: item,
                                                        allItems: Array(newsItems)
                                                    )
                                                }
                                            }
                                        }
                                        .id(item.id) // Ensure proper identity for LazyVStack
                                }
                                
                                // ✅ Load more indicator (Instagram-style)
                                if viewModel.isLoadingMore {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading more...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)
                                } else if !viewModel.hasMoreContent && newsItems.count > 5 {
                                    Text("You're all caught up!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                        .scrollIndicators(.hidden) // Clean modern look
                        .scrollBounceBehavior(.basedOnSize) // iOS 18 feature for better scroll behavior
                        .refreshable {
                            // ✅ Pull-to-refresh functionality
                            await viewModel.refresh(for: constituencyId, context: modelContext)
                        }
                    }
                }
                .navigationTitle("News Feed")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            // Menu action
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // Search action
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                
                // Floating Action Button (like WhatsApp)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreatePostSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color("primaryOpposite"))
                                .frame(width: 56, height: 56)
                                .background(Color.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            // ✅ Smart loading - only load if not initialized or constituencyId changed
            if !constituencyId.isEmpty {
                Task {
                    await viewModel.initialLoad(for: constituencyId, context: modelContext)
                }
            }
        }
        .onChange(of: constituencyId) { oldValue, newValue in
            // ✅ Load data when constituencyId changes
            if oldValue != newValue && !newValue.isEmpty {
                hasAppeared = false
                Task {
                    await viewModel.initialLoad(for: newValue, context: modelContext)
                }
            }
        }
        .sheet(isPresented: $showCreatePostSheet) {
            if let constituency = ConstituencyInfo, let id = constituency.id {
                PostView(ConstituencyId: id)
            }
        }
    }
}

// MARK: - Skeleton Loading View
struct SkeletonNewsCell: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 12)
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 10)
                        .cornerRadius(5)
                }
                
                Spacer()
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                    .cornerRadius(6)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 12)
                    .cornerRadius(6)
            }
            
            // Image skeleton
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .cornerRadius(12)
            
            // Action buttons skeleton
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 30)
                        .cornerRadius(15)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    NewsFeedView(ConstituencyInfo: DummyConstituencyDetials.detials1)
}
