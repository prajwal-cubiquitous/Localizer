//
//  ResponsiveLayout.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

// Screen sizes utilities
struct ScreenSize {
    static let width = UIScreen.main.bounds.width
    static let height = UIScreen.main.bounds.height
    static let size = UIScreen.main.bounds.size
    
    // Detect device type
    static var isSmallDevice: Bool {
        return height < 700
    }
    
    static var isMediumDevice: Bool {
        return height >= 700 && height < 800
    }
    
    static var isLargeDevice: Bool {
        return height >= 800
    }
    
    // Get relative sizing based on device screen
    static func relativePadding(small: CGFloat = 16, medium: CGFloat = 24, large: CGFloat = 32) -> CGFloat {
        if isSmallDevice {
            return small
        } else if isMediumDevice {
            return medium
        } else {
            return large
        }
    }
    
    static func relativeSpacing(small: CGFloat = 8, medium: CGFloat = 16, large: CGFloat = 24) -> CGFloat {
        if isSmallDevice {
            return small
        } else if isMediumDevice {
            return medium
        } else {
            return large
        }
    }
    
    static func relativeFont(small: CGFloat = 14, medium: CGFloat = 16, large: CGFloat = 18) -> CGFloat {
        if isSmallDevice {
            return small
        } else if isMediumDevice {
            return medium
        } else {
            return large
        }
    }
}

// View modifiers for responsive layout
struct ResponsivePadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, ScreenSize.relativePadding())
            .padding(.vertical, ScreenSize.relativePadding(small: 12, medium: 16, large: 20))
    }
}

struct ResponsiveFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(
                maxWidth: ScreenSize.isSmallDevice ? 320 : (ScreenSize.isMediumDevice ? 380 : 440)
            )
    }
}

// Extension for easier usage
extension View {
    func responsivePadding() -> some View {
        modifier(ResponsivePadding())
    }
    
    func responsiveFrame() -> some View {
        modifier(ResponsiveFrame())
    }
}
