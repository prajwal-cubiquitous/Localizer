//
//  NotificationsView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // Sample notification data
    private let notifications = [
        Notification(type: .like, username: "John Doe", content: "liked your post", timeAgo: "2m ago"),
        Notification(type: .comment, username: "Sarah Johnson", content: "commented on your post", timeAgo: "15m ago"),
        Notification(type: .follow, username: "Mike Chen", content: "started following you", timeAgo: "1h ago"),
        Notification(type: .mention, username: "Emma Williams", content: "mentioned you in a comment", timeAgo: "3h ago"),
        Notification(type: .like, username: "David Brown", content: "liked your comment", timeAgo: "5h ago"),
        Notification(type: .follow, username: "Alex Rodriguez", content: "started following you", timeAgo: "1d ago"),
        Notification(type: .comment, username: "Taylor Swift", content: "replied to your comment", timeAgo: "2d ago"),
        Notification(type: .mention, username: "Chris Evans", content: "mentioned you in a post", timeAgo: "3d ago")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Today section
                Section(header: Text("Today").foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .gray)) {
                    ForEach(notifications.prefix(5)) { notification in
                        notificationRow(notification: notification)
                            .listRowBackground(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
                    }
                }
                
                // Earlier section
                Section(header: Text("Earlier").foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .gray)) {
                    ForEach(notifications.suffix(3)) { notification in
                        notificationRow(notification: notification)
                            .listRowBackground(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color.white)
                    }
                }
            }
            .scrollContentBackground(colorScheme == .dark ? .hidden : .visible)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Mark all as read
                    } label: {
                        Text("Mark All")
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? .white : .blue)
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
    
    private func notificationRow(notification: Notification) -> some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(iconBackgroundColor(for: notification.type, darkMode: colorScheme == .dark))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName(for: notification.type))
                        .foregroundStyle(.white)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.username)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    + Text(" \(notification.content)")
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : .primary)
                    
                    Spacer()
                    
                    Text(notification.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                }
                
                // Additional content preview for comments and mentions
                if notification.type == .comment || notification.type == .mention {
                    Text("This is a preview of the comment or mention content...")
                        .font(.caption)
                        .foregroundStyle(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconName(for type: NotificationType) -> String {
        switch type {
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.left.fill"
        case .follow:
            return "person.fill.badge.plus"
        case .mention:
            return "at"
        }
    }
    
    private func iconBackgroundColor(for type: NotificationType, darkMode: Bool) -> Color {
        switch type {
        case .like:
            return darkMode ? .red.opacity(0.8) : .red
        case .comment:
            return darkMode ? .blue.opacity(0.8) : .blue
        case .follow:
            return darkMode ? .green.opacity(0.8) : .green
        case .mention:
            return darkMode ? .purple.opacity(0.8) : .purple
        }
    }
}

// Notification model
struct Notification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let username: String
    let content: String
    let timeAgo: String
    var isRead: Bool = false
}

enum NotificationType {
    case like, comment, follow, mention
}

#Preview {
    NotificationsView()
}
