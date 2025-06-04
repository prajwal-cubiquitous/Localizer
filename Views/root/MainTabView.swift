//
//  MainTabView.swift
//  Localizer
//
//  Created on 5/28/25.
//
import SwiftData
import SwiftUI
import CoreLocation

struct MainTabView: View {
    // MARK: - Properties
    
    // Add a state refresh ID to force view updates
    @State private var refreshID = UUID()
    @State private var selectedTab = 0
    @State private var pincode: String = ""
    @State private var isLocationReady: Bool = false
    @State private var locationError: String? = nil
    @State private var showPostView = false
    @Environment(\.colorScheme) private var colorScheme
    // Use the shared singleton instead of creating a new instance
    @StateObject var AuthviewModel = AuthViewModel.shared
    @StateObject var appState = AppState.shared
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        // Pass the modelContext to the singleton instance
        print("DEBUG: Setting modelContext in MainTabView init")
        AuthViewModel.shared.setModelContext(modelContext)
        
        // Request location permissions when the MainTabView is initialized
        LocationManager.shared.requestLocationPermission()
        
        // For debugging purposes
        print("DEBUG: Current stored pincode in LocationManager: \(LocationManager.shared.pincode)")
        
        // If we already have a pincode from a previous session, use it immediately
        if !LocationManager.shared.pincode.isEmpty {
            print("DEBUG: Using existing pincode from LocationManager: \(LocationManager.shared.pincode)")
            _pincode.wrappedValue = LocationManager.shared.pincode
            _isLocationReady.wrappedValue = true
        } else {
            // Immediately fetch pincode as soon as the app loads
            fetchPincode()
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            // Using a completely different view structure based on state
            // This forces SwiftUI to completely rebuild rather than just update
            if isLocationReady && !pincode.isEmpty {
                // Show main content only when truly ready
                mainContentView
            } else {
                // Show loading view
                loadingContentView
            }
        }
        .onAppear {
            print("DEBUG: MainTabView body appeared, isLocationReady: \(isLocationReady), pincode: \(pincode)")
            
            // Always initiate pincode fetch on appear if needed
            if pincode.isEmpty {
                print("DEBUG: Initiating pincode fetch on appear")
                fetchPincode()
            } else if !isLocationReady {
                // Force state update if we already have a pincode but isLocationReady is false
                print("DEBUG: Fixing inconsistent state - we have pincode but isLocationReady is false")
                DispatchQueue.main.async {
                    self.isLocationReady = true
                }
            }
        }
    }
    
    // MARK: - Views
    
    // Completely separate view for the main content
    private var mainContentView: some View {
        TabView(selection: $selectedTab) {
            // News Feed Tab
            NewsFeedView(pincode: pincode)
                .environmentObject(appState)
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
            ServicesView(pincode: pincode)
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text("Services")
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 1 ? "house.fill" : "house")
                    }
                }
                .tag(1)
            
            // Create Post Tab - Now just triggers sheet
            Color.clear
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
            NotificationsView(pincode: pincode)
                .environmentObject(appState)
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
            ProfileView(pincode: pincode)
                .environment(\.modelContext, modelContext) // Explicitly pass modelContext to ProfileView
                .environmentObject(AuthviewModel)
                .environmentObject(appState)
                .onAppear {
                    print("DEBUG: Profile tab appeared with modelContext: \(modelContext)")
                }
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
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                showPostView = true
                // Switch back to previous tab to avoid staying on empty tab
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $showPostView) {
            PostViewWrapper(pincode: pincode) { shouldNavigateToNewsFeed in
                if shouldNavigateToNewsFeed {
                    selectedTab = 0 // Navigate to NewsFeed tab
                }
            }
        }
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
        
        // Add a listener to the locationManager to detect changes in pincode and authorization
        .onChange(of: LocationManager.shared.pincode) { oldPincode, newPincode in
            if !newPincode.isEmpty && newPincode != pincode {
                pincode = newPincode
                isLocationReady = true
                locationError = nil
            }
        }
        .onChange(of: LocationManager.shared.authorizationStatus) { oldStatus, newStatus in
            if newStatus == .denied || newStatus == .restricted {
                locationError = "Unable to access your location. Please enable location services for this app in Settings."
            } else if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Re-attempt to fetch location when permission is granted
                if pincode.isEmpty {
                    fetchPincode()
                }
            }
        }
    }
    
    // Completely separate view for the loading state
    private var loadingContentView: some View {
        VStack(spacing: 20) {
            if locationError != nil {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding()
                
                Text(locationError ?? "Unknown error")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Retry") {
                    print("DEBUG: Retry button tapped, initiating new pincode fetch")
                    locationError = nil
                    fetchPincode()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Fetching your location...")
                    .font(.headline)
                
                Text("Please wait while we access your current location")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            print("DEBUG: Loading view appeared, isLocationReady: \(isLocationReady), pincode: \(pincode)")
            
            // Ensure pincode fetch is initiated
            if pincode.isEmpty && locationError == nil {
                fetchPincode()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Enhanced pincode fetching with better error handling and state management
    private func fetchPincode() {
        print("DEBUG: Starting pincode fetch process")
        LocationManager.shared.getCurrentPincode { fetchedPincode in
            // No need for weak self or guard since MainTabView is a struct (value type)
            
            DispatchQueue.main.async {
                if let fetchedPincode = fetchedPincode, !fetchedPincode.isEmpty {
                    print("DEBUG: Pincode fetch success: \(fetchedPincode)")
                    self.pincode = fetchedPincode
                    self.locationError = nil
                    
                    // Set location ready and force refresh
                    self.isLocationReady = true
                    self.refreshID = UUID()
                    print("DEBUG: Location state updated - isLocationReady: \(self.isLocationReady), pincode: \(self.pincode)")
                } else {
                    // Check for location authorization status to provide more specific error
                    let authStatus = LocationManager.shared.authorizationStatus
                    
                    switch authStatus {
                    case .denied, .restricted:
                        self.locationError = "Please enable location access in Settings to continue"
                    case .notDetermined:
                        self.locationError = "Location permission is required to use this app"
                    default:
                        if let error = LocationManager.shared.error {
                            self.locationError = "Error fetching location: \(error.localizedDescription)"
                        } else {
                            self.locationError = "Unable to determine your location. Please try again."
                        }
                    }
                    
                    print("DEBUG: Location fetch failed with error: \(self.locationError ?? "unknown")")
                    self.isLocationReady = false
                }
            }
        }
    }
}

// Preview for both light and dark mode
// struct MainTabView_Previews: PreviewProvider {
//     static var previews: some View {
//         Group {
//             MainTabView()
//                 .preferredColorScheme(.light)
//                 .previewDisplayName("Light Mode")
//             
//             MainTabView()
//                 .preferredColorScheme(.dark)
//                 .previewDisplayName("Dark Mode")
//         }
//     }
// }
