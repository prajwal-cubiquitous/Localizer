//
//  LocalizerApp.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/28/25.
//
import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct LocalizerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    
    let container: ModelContainer

    init() {
        // 🔥 RESET EVERYTHING ON EVERY APP LAUNCH - Enhanced reset
        Self.resetSwiftDataStore()
        
        // Create fresh container with new configuration
        do {
            // Force a completely new configuration to avoid schema conflicts
            let config = ModelConfiguration(
                "Localizer_v2", // Changed name to force fresh schema
                isStoredInMemoryOnly: false, allowsSave: true,
//                allowsCloudEncryption: false
            )
            
            print("🔧 Attempting to create SwiftData container with models:")
            print("   - LocalUser")
            print("   - LocalNews (with JSON-based newsImageURLs)")
            print("   - LocalVote")
            
            container = try ModelContainer(
                for: LocalUser.self, LocalNews.self, LocalVote.self,
                configurations: config
            )
            print("✅ Fresh SwiftData container created with new schema")
            print("📁 Container URL: \(config.url)")
        } catch {
            // Fallback: Try in-memory database if persistent fails
            print("⚠️ Failed to create persistent container, falling back to in-memory: \(error)")
            do {
                let memoryConfig = ModelConfiguration(
                    "Localizer_Memory",
                    isStoredInMemoryOnly: true, allowsSave: false
                )
                container = try ModelContainer(
                    for: LocalUser.self, LocalNews.self, LocalVote.self,
                    configurations: memoryConfig
                )
                print("✅ In-memory SwiftData container created")
            } catch {
                fatalError("❌ Failed to initialize any SwiftData container: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(selectedColorScheme)
                .tint(.accentColor)
                .dynamicTypeSize(.medium)
                .modelContainer(container)
        }
    }

    private var selectedColorScheme: ColorScheme? {
        switch colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // Enhanced reset function
    static func resetSwiftDataStore() {
        let fileManager = FileManager.default
        let storeNames = ["Localizer", "Localizer_v2", "Localizer_Memory"] // All possible store names
        
        // Get all possible SwiftData storage locations
        let searchPaths: [FileManager.SearchPathDirectory] = [
            .applicationSupportDirectory,
            .documentDirectory,
            .libraryDirectory,
            .cachesDirectory // Added cache directory
        ]
        
        for searchPath in searchPaths {
            guard let baseURL = fileManager.urls(for: searchPath, in: .userDomainMask).first else { continue }
            
            // Check multiple possible subdirectories
            let urlsToCheck = [
                baseURL,
                baseURL.appendingPathComponent("Application Support"),
                baseURL.appendingPathComponent("default.store"), // SwiftData default location
                baseURL.appendingPathComponent("CoreData")
            ]
            
            for url in urlsToCheck {
                for storeName in storeNames {
                    deleteSwiftDataFiles(at: url, storeName: storeName)
                }
                // Also clean any default SwiftData files
                deleteSwiftDataFiles(at: url, storeName: "default")
                deleteSwiftDataFiles(at: url, storeName: "DataModel")
            }
        }
        
        print("🔥 SwiftData store completely reset")
    }
    
    private static func deleteSwiftDataFiles(at baseURL: URL, storeName: String) {
        let fileManager = FileManager.default
        
        // All possible file variations including new SwiftData formats
        let fileVariations = [
            "\(storeName).sqlite",
            "\(storeName).sqlite-shm",
            "\(storeName).sqlite-wal",
            "\(storeName).db",
            "\(storeName).db-shm", 
            "\(storeName).db-wal",
            "\(storeName).store",
            "\(storeName).store-shm",
            "\(storeName).store-wal",
            storeName, // File without extension
            "\(storeName).swiftdata",
            "\(storeName)-shm",
            "\(storeName)-wal"
        ]
        
        for fileName in fileVariations {
            let fileURL = baseURL.appendingPathComponent(fileName)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("🗑️ Deleted: \(fileURL.path)")
                } catch {
                    print("❌ Failed to delete \(fileName): \(error)")
                }
            }
        }
        
        // Also try to delete the entire directory if it's a SwiftData store directory
        let storeDirectory = baseURL.appendingPathComponent("\(storeName).store")
        if fileManager.fileExists(atPath: storeDirectory.path) {
            do {
                try fileManager.removeItem(at: storeDirectory)
                print("🗑️ Deleted directory: \(storeDirectory.path)")
            } catch {
                print("❌ Failed to delete directory \(storeDirectory.path): \(error)")
            }
        }
    }
}
