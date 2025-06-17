//
//  NewsFeedView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import SwiftData

struct NewsFeedView: View {
    let pincode: String
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NewsFeedViewModel()
    @Query private var newsItems: [LocalNews]
    @State private var showCreatePostSheet = false
    @State private var hasAppeared = false

    init(pincode: String) {
        self.pincode = pincode
        _newsItems = Query(filter: #Predicate<LocalNews> { news in
            news.postalCode == pincode
        }, sort: [SortDescriptor(\LocalNews.timestamp, order: .reverse)])
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if newsItems.isEmpty && !viewModel.isLoading {
                        // Empty State
                        VStack(spacing: 24) {
                            Image(systemName: "square.and.pencil")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.secondary)
                            
                            Text("Be the first to post!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("Tap the + button to share your thoughts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    } else {
                        // ✅ Instagram-style News Feed with Pagination
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // ✅ Initial loading indicator
                                if viewModel.isLoading && newsItems.isEmpty {
                                    VStack(spacing: 16) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("Loading news...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 200)
                                    .padding()
                                }
                                
                                // ✅ News items with optimized pagination detection
                                ForEach(Array(newsItems.enumerated()), id: \.element.id) { index, item in
                                    NewsCell(localNews: item)
                                        .padding(.horizontal, 0) // NewsCell handles its own horizontal padding
                                        .padding(.bottom, 8) // Space between news items
                                        .onAppear {
                                            // ✅ Optimized load more trigger - only check near end
                                            if index >= newsItems.count - 3 {
                                                Task {
                                                    await viewModel.loadMoreIfNeeded(
                                                        for: pincode,
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
                                    HStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading more...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .padding()
                                    .transition(.opacity.combined(with: .scale))
                                }
                                
                                // ✅ End of content indicator
                                if !viewModel.hasMoreContent && !newsItems.isEmpty && !viewModel.isLoading {
                                    VStack(spacing: 8) {
                                        Divider()
                                            .padding(.horizontal, 40)
                                        Text("You're all caught up!")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .padding()
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding(.top, 8) // Top spacing from navigation
                            .padding(.bottom, 80) // Bottom spacing for floating button
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingMore)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.hasMoreContent)
                        }
                        .scrollIndicators(.hidden) // Clean modern look
                        .scrollBounceBehavior(.basedOnSize) // iOS 18 feature for better scroll behavior
                        .refreshable {
                            // ✅ Pull-to-refresh functionality
                            await viewModel.refresh(for: pincode, context: modelContext)
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
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
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
            // ✅ Smart loading - only load if not initialized or pincode changed
            Task {
                await viewModel.initialLoad(for: pincode, context: modelContext)
            }
        }
        .onChange(of: pincode) { oldValue, newValue in
            // ✅ Load data when pincode changes
            if oldValue != newValue {
                hasAppeared = false
                Task {
                    await viewModel.initialLoad(for: newValue, context: modelContext)
                }
            }
        }
        .sheet(isPresented: $showCreatePostSheet) {
            PostView(pincode: pincode)
        }
    }
}

#Preview {
    NewsFeedView(pincode: "560043")
}
