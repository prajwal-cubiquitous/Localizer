//
//  ColorScheme.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct AppColors {
    static let background = Color("Background")
    static let foreground = Color("Foreground")
    
    // Computed properties for dynamic colors
    static var cardBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var dividerColor: Color {
        Color.gray.opacity(0.3)
    }
}

extension Color {
    static let appBackground = Color(.systemBackground)
    static let appSecondaryBackground = Color(.secondarySystemBackground)
    static let appTertiaryBackground = Color(.tertiarySystemBackground)
}
