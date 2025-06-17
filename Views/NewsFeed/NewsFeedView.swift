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
                            
                            Text("Tap the + button to share your thoughts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
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
                            .padding(.bottom, 80) // Bottom spacing for floating button
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
        .task {
                await viewModel.fetchAndCacheNews(for: pincode, context: modelContext)
        }
        .sheet(isPresented: $showCreatePostSheet) {
            PostView(pincode: pincode)
        }
    }
}

#Preview {
    NewsFeedView(pincode: "560043")
}
