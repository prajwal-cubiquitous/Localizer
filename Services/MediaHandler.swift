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
                        // Remove invalid cache entry
                        downloadCache.removeValue(forKey: url.absoluteString)
                    }
                }
                
                // Perform download
                Task {
                    do {
                        let localURL = try await performDownload(from: url, fileName: fileName)
                        
                        // Cache the result
                        cacheQueue.async(flags: .barrier) {
                            downloadCache[url.absoluteString] = localURL
                        }
                        
                        continuation.resume(returning: localURL)
                    } catch {
                        // ✅ Always fall back to original URL on download failure
                        print("⚠️ Download failed for \(url), using original URL: \(error)")
                        continuation.resume(returning: url)
                    }
                }
            }
        }
    }
    
    // ✅ Separate download method for cleaner code
    private static func performDownload(from url: URL, fileName: String) async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let localURL = tempDirectory.appendingPathComponent(fileName)
        
        // ✅ Don't re-download if file already exists
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        // ✅ Use URLSessionConfiguration for better performance and timeout handling
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache.shared
        config.timeoutIntervalForRequest = 30.0 // 30 second timeout
        config.timeoutIntervalForResource = 60.0 // 1 minute resource timeout
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(from: url)
        
        // ✅ Validate response
        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }
        }
        
        try data.write(to: localURL)
        return localURL
    }
    
    // ✅ Enhanced cache clearing that also clears our download cache
    static func clearTemporaryMedia() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in filePaths {
                try FileManager.default.removeItem(at: file)
            }
            
            // Clear our download cache
            cacheQueue.async(flags: .barrier) {
                downloadCache.removeAll()
            }
            
            print("✅ Temporary media and cache cleared.")
        } catch {
            print("❌ Error clearing temp files: \(error)")
        }
    }
    
    // ✅ Enhanced method for bulk downloads with better error handling and fallback
    static func downloadMediaConcurrently(from urls: [URL]) async -> [String] {
        return await withTaskGroup(of: (Int, String).self, returning: [String].self) { group in
            var results: [String] = Array(repeating: "", count: urls.count)
            
            for (index, url) in urls.enumerated() {
                group.addTask {
                    let filename = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
                    do {
                        let localURL = try await downloadMedia(from: url, fileName: filename)
                        print("✅ Successfully downloaded/cached: \(url) -> \(localURL)")
                        return (index, localURL.absoluteString)
                    } catch {
                        print("⚠️ Background media download failed for \(url): \(error)")
                        // ✅ Always return original URL if download fails
                        return (index, url.absoluteString)
                    }
                }
            }
            
            for await (index, urlString) in group {
                results[index] = urlString
            }
            
            print("📱 Processed \(results.count) media URLs (\(results.filter { $0.starts(with: "file://") }.count) local, \(results.filter { $0.starts(with: "https://") }.count) remote)")
            return results
        }
    }
    
    // ✅ New method to directly return original URLs without attempting download
    static func useDirectURLs(from urls: [URL]) -> [String] {
        print("📱 Using direct URLs for \(urls.count) media items")
        return urls.map { $0.absoluteString }
    }
}

