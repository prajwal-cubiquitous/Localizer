//
//  ContentView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.userSession != nil {
                MainTabView(modelContext: modelContext)
                    .smoothTransition()
            } else {
                AuthContainerView(modelContext: modelContext)
                    .fadeInOut()
            }
        }
    }
}


