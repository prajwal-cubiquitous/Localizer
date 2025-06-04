//
//  NewsFeedView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct NewsFeedView: View {
    let pincode: String
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(1...10, id: \.self) { index in
                        NewsCell(localNews: DummyLocalNews.News1)
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
        .onAppear {
            print("DEBUG: NewsFeedView appeared with pincode: \(pincode)")
        }
    }
}

#Preview {
    NewsFeedView(pincode: "560043")
}
