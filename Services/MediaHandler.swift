//
//  MediaHandler.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//

import Foundation
import SwiftUI

class MediaHandler{
    // ✅ Cache to avoid re-downloading same files
    private static var downloadCache: [String: URL] = [:]
    private static let cacheQueue = DispatchQueue(label: "media.cache.queue", attributes: .concurrent)
    
    static func downloadMedia(from url: URL, fileName: String) async throws -> URL {
        // ✅ Check cache first
        return try await withCheckedThrowingContinuation { continuation in
            cacheQueue.async {
                if let cachedURL = downloadCache[url.absoluteString] {
                    // Check if cached file still exists
                    if FileManager.default.fileExists(atPath: cachedURL.path) {
                        continuation.resume(returning: cachedURL)
                        return
                    } else {
                        // Remove stale cache entry
                        downloadCache.removeValue(forKey: url.absoluteString)
                    }
                }
                
                // Download the file
                Task {
                    do {
                        let localURL = try await performDownload(from: url, fileName: fileName)
                        
                        // Cache the result
                        cacheQueue.async(flags: .barrier) {
                            downloadCache[url.absoluteString] = localURL
                        }
                        
                        continuation.resume(returning: localURL)
                    } catch {
                        // ✅ Always return original URL when download fails
                        continuation.resume(returning: url)
                    }
                }
            }
        }
    }
    
    private static func performDownload(from url: URL, fileName: String) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Create temporary directory if it doesn't exist
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("LocalizerMedia")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create local file URL
        let localURL = tempDir.appendingPathComponent(fileName)
        
        // Write data to local file
        try data.write(to: localURL)
        
        return localURL
    }
    
    // ✅ Enhanced method to download multiple media items concurrently
    static func downloadMediaConcurrently(urls: [String]) async -> [String] {
        guard !urls.isEmpty else { return [] }
        
        // ✅ Use TaskGroup for concurrent downloads
        return await withTaskGroup(of: (Int, String).self, returning: [String].self) { group in
            // Add download tasks for each URL
            for (index, urlString) in urls.enumerated() {
                group.addTask {
                    guard let url = URL(string: urlString) else {
                        return (index, urlString) // Return original if invalid
                    }
                    
                    do {
                        let filename = url.lastPathComponent
                        let localURL = try await downloadMedia(from: url, fileName: filename)
                        return (index, localURL.absoluteString)
                    } catch {
                        return (index, urlString) // Return original URL on failure
                    }
                }
            }
            
            // Collect results maintaining original order
            var results: [(Int, String)] = []
            for await result in group {
                results.append(result)
            }
            
            // Sort by index and return URLs
            let sortedResults = results.sorted { $0.0 < $1.0 }.map { $0.1 }
            return sortedResults
        }
    }
    
    // ✅ Clear temporary media files and cache
    static func clearTemporaryMedia() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("LocalizerMedia")
        
        do {
            if FileManager.default.fileExists(atPath: tempDir.path) {
                try FileManager.default.removeItem(at: tempDir)
            }
            
            // Clear cache
            cacheQueue.async(flags: .barrier) {
                downloadCache.removeAll()
            }
        } catch {
            // Silent error handling
        }
    }
    
    // ✅ Convenience method for single URL processing
    static func processMediaURLs(_ urls: [String]) async -> [String] {
        guard !urls.isEmpty else { return [] }
        
        // For small arrays, use concurrent download
        if urls.count <= 10 {
            let results = await downloadMediaConcurrently(urls: urls)
            return results
        } else {
            // For larger arrays, return original URLs to avoid overwhelming the system
            return urls
        }
    }
}

