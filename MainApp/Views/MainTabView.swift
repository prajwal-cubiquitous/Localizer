//
//  MainTabView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // News Feed Tab
            NewsFeedView()
                .tabItem {
                    Label {
                        Text("News Feed")
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 0 ? "newspaper.fill" : "newspaper")
                    }
                }
                .tag(0)
            
            // Services Tab
            ServicesView()
                .tabItem {
                    Label {
                        Text("Services")
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 1 ? "house.fill" : "house")
                    }
                }
                .tag(1)
            
            // Post Tab
            PostView()
                .tabItem {
                    Label {
                        Text("Post")
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 2 ? "plus.square.fill" : "plus.square")
                    }
                }
                .tag(2)
            
            // Notifications Tab
            NotificationsView()
                .tabItem {
                    Label {
                        Text("Notifications")
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 3 ? "bell.fill" : "bell")
                    }
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label {
                        Text("Profile")
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    }
                }
                .tag(4)
        }
        .tint(colorScheme == .dark ? .white : .blue)
        .onAppear {
            // Customize tab bar appearance for both light and dark mode
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            
            // Customize tab bar colors based on color scheme
            if colorScheme == .dark {
                // Customize for dark mode
                tabBarAppearance.backgroundColor = UIColor.black
                
                // Customize unselected tab appearance
                let unselectedAppearance = UITabBarItemAppearance(style: .stacked)
                unselectedAppearance.normal.iconColor = UIColor.lightGray
                unselectedAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
                
                // Apply appearances
                tabBarAppearance.stackedLayoutAppearance = unselectedAppearance
                tabBarAppearance.inlineLayoutAppearance = unselectedAppearance
                tabBarAppearance.compactInlineLayoutAppearance = unselectedAppearance
            }
            
            // For iOS 15 and newer
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UITabBar.appearance().standardAppearance = tabBarAppearance
        }
        .preferredColorScheme(colorScheme) // Ensure color scheme propagates to child views
    }
}

// Preview for both light and dark mode
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainTabView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            MainTabView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
