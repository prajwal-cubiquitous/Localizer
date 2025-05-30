//
//  ContentView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showMainView = false
    
    var body: some View {
        ZStack {
            if viewModel.userSession != nil {
                MainTabView()
                    .smoothTransition()
            } else {
                AuthContainerView()
                    .fadeInOut()
            }
        }
        .onChange(of: viewModel.userSession) { _, newValue in
            withAnimation(.smoothAppear) {
                showMainView = newValue != nil
            }
        }
    }
}


