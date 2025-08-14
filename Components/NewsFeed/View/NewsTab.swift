//
//  NewsTab.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 8/12/25.
//
import Foundation
import SwiftUI

enum NewsTab: String, Identifiable, CaseIterable {
    case latest = "Latest"
    case trending = "Trending"
    case City = "City"
    
    var id: String { rawValue }  // ✅ Required for Identifiable
    
    var localizedTitle: String {
        self.rawValue.localized()
    }
    
    var icon: String {
        switch self {
        case .latest:
            return "clock"
        case .trending:
            return "flame"
        case .City:
            return "map"
        }
    }
}

