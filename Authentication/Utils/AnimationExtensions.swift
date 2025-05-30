//
//  AnimationExtensions.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

extension Animation {
    static let smoothAppear = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let smoothDisappear = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    static func smoothBounce(duration: Double = 0.5) -> Animation {
        Animation.spring(response: duration, dampingFraction: 0.7)
    }
    
    static func easeInOut(duration: Double = 0.3) -> Animation {
        Animation.easeInOut(duration: duration)
    }
}

// View extension for smooth transitions
extension View {
    func smoothTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            )
        )
    }

    func fadeInOut() -> some View {
        transition(.opacity)
    }
}

