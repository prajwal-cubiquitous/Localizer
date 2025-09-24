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
    
    // for Constituency Fetching 
    @StateObject var ConstituencyViewModel = constituencyViewModel()
    @State var constituencies : Set<ConstituencyDetails>?  // Changed from Array to Set
    @State private var selectedName: String = ""
    
    // Add state to track constituency loading
    @State private var isConstituencyLoading: Bool = false
    @State private var constituencyError: String? = nil
    
    // Improved selectedConstituency computation with better fallback
    var selectedConstituency: ConstituencyDetails? {
        // First try to find by selectedName
        if let constituency = constituencies?.first(where: { $0.constituencyName == selectedName }) {
            return constituency
        }
        // Fallback to first constituency if selectedName doesn't match
        return constituencies?.first
    }
    
    // Computed property to check if we're ready to show main content
    private var isReadyToShowMainContent: Bool {
        return isLocationReady && 
               !pincode.isEmpty && 
               selectedName != "" && 
               selectedConstituency != nil &&
               !isConstituencyLoading
    }
    
    // Computed property to get all pincodes for the DataView
    private var allPincodes: [String] {
        if let constituency = selectedConstituency {
            // Use all pincodes from the constituency
            return constituency.associatedPincodes.isEmpty ? [pincode] : constituency.associatedPincodes
        }
        // Fallback to current pincode
        return [pincode]
    }
    
    // Convert Set to Binding<Array> for ProfileView compatibility
    private var constituenciesBinding: Binding<[ConstituencyDetails]?> {
        Binding(
            get: {
                guard let constituencies = constituencies else { return nil }
                return Array(constituencies)
            },
            set: { newValue in
                guard let newValue = newValue else { 
                    constituencies = nil
                    return 
                }
                constituencies = Set(newValue)
            }
        )
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        // Pass the modelContext to the singleton instance
        AuthViewModel.shared.setModelContext(modelContext)
        
        // Request location permissions when the MainTabView is initialized
        LocationManager.shared.requestLocationPermission()
        
        // If we already have a pincode from a previous session, use it immediately
        if !LocationManager.shared.pincode.isEmpty {
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
            if isReadyToShowMainContent {
                // Show main content only when truly ready
                mainContentView
            } else {
                // Show loading view
                loadingContentView
            }
        }
        .onAppear {
            // Always initiate pincode fetch on appear if needed
            if pincode.isEmpty {
                fetchPincode()
            } else if !isLocationReady {
                // Force state update if we already have a pincode but isLocationReady is false
                DispatchQueue.main.async {
                    self.isLocationReady = true
                }
            }
        }
        .onAppear {
            // Ensure the current user is loaded
            if let sessionUserId = appState.userSession?.uid {
                // Trigger user loading if not already done
                Task { @MainActor in
                    let users = try? modelContext.fetch(FetchDescriptor<LocalUser>())
                    
                    if users?.isEmpty == true {
                        await AuthviewModel.fetchAndStoreUserAsync(userId: sessionUserId)
                    } else if let users = users, !users.contains(where: { $0.id == sessionUserId }) {
                        await AuthviewModel.fetchAndStoreUserAsync(userId: sessionUserId)
                    }
                }
            }
        }
        .task(id: pincode){
            if !pincode.isEmpty {
                await fetchConstituencyData()
            }
        }
    }
    
    // MARK: - Views
    
    // Completely separate view for the main content
    private var mainContentView: some View {
        TabView(selection: $selectedTab) {
            // News Feed Tab
            NewsFeedView(ConstituencyInfo: selectedConstituency, pincode: pincode)
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text("News Feed".localized())   
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 0 ? "newspaper.fill" : "newspaper")
                    }
                }
                .tag(0)
            
            // Services Tab
            DataView(ConstituencyInfo: selectedConstituency , pincodes: allPincodes/*, ConstituencyName: selectedConstituency?.constituencyName ?? ""*/)
                .id("dataview-\(selectedConstituency?.constituencyName ?? pincode)")
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text("Services".localized())
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 1 ? "house.fill" : "house")
                    }
                }
                .tag(1)
            
            // Constituency Tab
            constituencyView(ConstituencyInfo: selectedConstituency)
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text("Constituency".localized())
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 2 ? "building.2.fill" : "building.2")
                    }
                }
                .tag(2)
            
            // Notifications Tab
            ActivityView(ConstituencyInfo: selectedConstituency)
                .environmentObject(appState)
                .tabItem {
                    Label {
                        Text("My Activities".localized())
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 3 ? "figure.walk.diamond.fill" : "figure.walk.diamond")
                    }
                }
                .tag(3)
            
            // Profile Tab
            ProfileView(pincode: pincode, constituencies: constituenciesBinding, selectedName: $selectedName)
                .environment(\.modelContext, modelContext) // Explicitly pass modelContext to ProfileView
                .environmentObject(AuthviewModel)
                .environmentObject(appState)

                .tabItem {
                    Label {
                        Text("Profile".localized())
                            .font(.caption)
                    } icon: {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    }
                }
                .tag(4)
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
                
                Button("Retry".localized()) {
                    locationError = nil
                    fetchPincode()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else if constituencyError != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding()
                
                Text(constituencyError ?? "Unknown error")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Retry".localized()) {
                    constituencyError = nil
                    if !pincode.isEmpty {
                        Task {
                            await fetchConstituencyData()
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                if isConstituencyLoading {
                    Text("Loading constituency data...".localized())
                        .font(.headline)
                    
                    Text("Please wait while we fetch your constituency information".localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    Text("Fetching your location...".localized())
                        .font(.headline)
                    
                    Text("Please wait while we access your current location".localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            // Ensure pincode fetch is initiated
            if pincode.isEmpty && locationError == nil {
                fetchPincode()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Enhanced pincode fetching with better error handling and state management
    private func fetchPincode() {
        LocationManager.shared.getCurrentPincode { fetchedPincode in
            // No need for weak self or guard since MainTabView is a struct (value type)
            
            DispatchQueue.main.async {
                if let fetchedPincode = fetchedPincode, !fetchedPincode.isEmpty {
                    self.pincode = fetchedPincode
                    self.locationError = nil
                    
                    // Set location ready and force refresh
                    self.isLocationReady = true
                    self.refreshID = UUID()
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
                    
                    self.isLocationReady = false
                }
            }
        }
    }
    
    /// Enhanced constituency data fetching with proper state management
    private func fetchConstituencyData() async {
        guard !pincode.isEmpty else { return }
        
        isConstituencyLoading = true
        constituencyError = nil
        
        do {
            let fetchedConstituencies = await ConstituencyViewModel.fetchConstituency(forPincode: pincode)
            
            await MainActor.run {
                // Convert array to Set to eliminate duplicates
                self.constituencies = Set(fetchedConstituencies)
                
                if let first = fetchedConstituencies.first {
                    self.selectedName = first.constituencyName
                } else {
                    // No constituencies found for this pincode
                    self.constituencyError = "No constituency found for your location. Please try again or contact support."
                }
                
                self.isConstituencyLoading = false
            }
        } catch {
            await MainActor.run {
                self.constituencyError = "Failed to load constituency data: \(error.localizedDescription)"
                self.isConstituencyLoading = false
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
