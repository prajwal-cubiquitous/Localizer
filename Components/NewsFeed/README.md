# NewsFeedView with Latest & Trending Sections

## Overview

The NewsFeedView has been enhanced to include two distinct sections:

1. **Latest News** - Displays news items sorted by timestamp (newest first)
2. **Trending News** - Displays news items sorted by likes count (most popular first)

## Features

### ✨ Smooth Animations
- **Section Transitions**: Smooth sliding and fading animations when switching between Latest and Trending
- **Content Updates**: Animated content changes with `.easeInOut(duration: 0.3)` timing
- **Interactive Elements**: Responsive button animations and state changes

### 🎯 Dual Section Management
- **Latest Section**: News sorted by `timestamp` in descending order
- **Trending Section**: News sorted by `likesCount` in descending order
- **Smart Switching**: Automatic data reloading when switching sections
- **State Persistence**: Maintains section selection across view updates

### 🎨 Modern UI Components
- **Custom Segmented Control**: Beautiful pill-shaped toggle with icons and colors
- **Responsive Design**: Adapts to different screen sizes and color schemes
- **Clean Layout**: Card-based design with proper spacing and shadows

### 📱 User Experience
- **Pull-to-Refresh**: Swipe down to refresh current section
- **Infinite Scroll**: Automatic loading of more content
- **Loading States**: Visual feedback during data operations
- **Empty States**: Contextual empty state messages for each section

## Architecture

### NewsFeedViewModel
```swift
@MainActor
final class NewsFeedViewModel: ObservableObject {
    @Published var selectedSection: NewsSection = .latest
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMorePages = true
    
    func switchSection(to section: NewsSection, context: ModelContext) async
    func loadInitial(for constituencyId: String, context: ModelContext) async
    func loadMore(context: ModelContext) async
    func refresh(for constituencyId: String, context: ModelContext) async
}
```

### NewsSection Enum
```swift
enum NewsSection: String, CaseIterable {
    case latest = "Latest"      // Clock icon, blue color
    case trending = "Trending"   // Flame icon, orange color
    
    var icon: String { ... }
    var color: String { ... }
}
```

### NewsRowView Component
- **Reusable**: Can be used independently in other views
- **Rich Content**: Displays thumbnail, title, summary, timestamp, and engagement stats
- **Responsive**: Adapts to content length and media availability
- **Accessible**: Proper contrast and touch targets

## Usage

### Basic Implementation
```swift
struct ContentView: View {
    @StateObject private var viewModel = NewsFeedViewModel()
    
    var body: some View {
        NewsFeedView(ConstituencyInfo: constituencyDetails)
            .environmentObject(appState)
    }
}
```

### Custom Section Switching
```swift
// Switch to trending section
await viewModel.switchSection(to: .trending, context: modelContext)

// Switch to latest section
await viewModel.switchSection(to: .latest, context: modelContext)
```

### Custom NewsRowView Usage
```swift
struct CustomView: View {
    let news: LocalNews
    
    var body: some View {
        NewsRowView(news: news)
            .padding(.horizontal, 16)
    }
}
```

## Data Flow

1. **Initial Load**: Fetches news based on selected section and constituency
2. **Section Switch**: Clears current data and fetches new section data
3. **Infinite Scroll**: Loads additional pages when user scrolls to bottom
4. **Pull-to-Refresh**: Reloads current section data
5. **Data Caching**: Stores up to 20 items locally for performance

## Firestore Queries

### Latest News Query
```swift
db.collection("news")
    .whereField("cosntituencyId", isEqualTo: constituencyId)
    .order(by: "timestamp", descending: true)
    .limit(to: pageSize)
```

### Trending News Query
```swift
db.collection("news")
    .whereField("cosntituencyId", isEqualTo: constituencyId)
    .order(by: "likesCount", descending: true)
    .limit(to: pageSize)
```

## Mock Data

The component includes comprehensive mock data for development and testing:

```swift
// Access mock data
DummyLocalNews.latestNews      // Sorted by timestamp
DummyLocalNews.trendingNews    // Sorted by likes
DummyLocalNews.allNews         // All mock news items

// Individual mock items
DummyLocalNews.News1, News2, News3, News4, News5, News6, News7, News8
```

## Customization

### Colors and Styling
```swift
// Custom section colors
enum NewsSection {
    case latest = "Latest"
    case trending = "Trending"
    
    var color: String {
        switch self {
        case .latest: return "blue"
        case .trending: return "orange"
        }
    }
}
```

### Animation Timing
```swift
// Adjust animation duration
withAnimation(.easeInOut(duration: 0.3)) {
    selectedSection = section
}
```

### Page Size
```swift
// Modify items per page
private let pageSize = 10 // Default: 10 items per page
```

## Performance Considerations

- **Lazy Loading**: Uses `LazyVStack` for efficient rendering
- **Pagination**: Loads data in chunks to avoid memory issues
- **Local Caching**: Stores limited items locally for offline access
- **Background Processing**: Handles data operations asynchronously

## Dependencies

- **SwiftUI**: Core UI framework
- **SwiftData**: Local data persistence
- **Firebase Firestore**: Remote data source
- **Kingfisher**: Image loading and caching
- **Firebase Auth**: User authentication

## Best Practices

1. **Always use @MainActor** for UI updates
2. **Handle errors gracefully** with user-friendly messages
3. **Provide loading states** for better UX
4. **Use proper memory management** with pagination
5. **Test with different data scenarios** (empty, loading, error states)

## Troubleshooting

### Common Issues

1. **Section not switching**: Ensure `switchSection` is called on main thread
2. **Data not loading**: Check constituency ID and network connectivity
3. **Animations not working**: Verify animation modifiers are applied correctly
4. **Memory issues**: Reduce `maxLocalItems` or `pageSize` values

### Debug Tips

- Use `print` statements in `switchSection` method
- Check Firestore query results
- Verify SwiftData context is available
- Monitor memory usage during pagination

## Future Enhancements

- [ ] Search functionality within sections
- [ ] Filtering options (date range, category)
- [ ] Bookmark/favorite system
- [ ] Push notifications for trending news
- [ ] Analytics and engagement tracking
- [ ] Offline-first architecture
- [ ] Social sharing features
