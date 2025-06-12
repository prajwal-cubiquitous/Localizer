//
//  MediaHandler.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//

import Foundation
import SwiftUI

class MediaHandler{
    static func downloadMedia(from url: URL, fileName: String) async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let localURL = tempDirectory.appendingPathComponent(fileName)
        
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: localURL)
        
        return localURL
    }
    
    static func clearTemporaryMedia() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in filePaths {
                try FileManager.default.removeItem(at: file)
            }
            print("Temporary media cleared.")
        } catch {
            print("Error clearing temp files: \(error)")
        }
    }
}

