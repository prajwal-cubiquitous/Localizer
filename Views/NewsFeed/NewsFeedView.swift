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
    @State private var hasFetched = false
    
    init(pincode: String) {
        self.pincode = pincode
        _newsItems = Query(filter: #Predicate<LocalNews> { news in
            news.postalCode == pincode
        }, sort: [SortDescriptor(\LocalNews.timestamp, order: .reverse)])
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if newsItems.isEmpty {
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
                        
                        Button {
                            showCreatePostSheet = true
                        } label: {
                            Text("Create Post")
                                .font(.headline)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                } else {
                    // News Feed Content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(newsItems) { item in
                                NewsCell(localNews: item)
                                    .padding(.horizontal, 0) // NewsCell handles its own horizontal padding
                                    .padding(.bottom, 8) // Space between news items
                            }
                        }
                        .padding(.top, 8) // Top spacing from navigation
                        .padding(.bottom, 20) // Bottom spacing for safe area
                    }
                    .scrollIndicators(.hidden) // Clean modern look
                    .refreshable {
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
        }
        .task {
            if !hasFetched {
                hasFetched = true
                await viewModel.fetchAndCacheNews(for: pincode, context: modelContext)
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
