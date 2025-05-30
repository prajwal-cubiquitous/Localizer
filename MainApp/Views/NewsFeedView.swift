//
//  NewsFeedView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct NewsFeedView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(1...10, id: \.self) { index in
                        newsFeedCard(index: index)
                    }
                }
                .padding()
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
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
    
    private func newsFeedCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with profile pic and name
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("User \(index)")
                        .fontWeight(.semibold)
                    
                    Text("\(index * 5) mins ago")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
            
            // Content
            Text("This is a sample news feed post #\(index). It contains some random text to demonstrate the layout and design of the news feed.")
                .font(.subheadline)
                .lineLimit(3)
            
            // Image placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                )
            
            // Action buttons
            HStack(spacing: 24) {
                Button {
                    // Like action
                } label: {
                    Label {
                        Text("\(index * 5)")
                            .font(.footnote)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    } icon: {
                        Image(systemName: "heart")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                
                Button {
                    // Comment action
                } label: {
                    Label {
                        Text("\(index * 2)")
                            .font(.footnote)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    } icon: {
                        Image(systemName: "bubble.left")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                
                Button {
                    // Share action
                } label: {
                    Label {
                        Text("Share")
                            .font(.footnote)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    } icon: {
                        Image(systemName: "arrowshape.turn.up.right")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NewsFeedView()
}
