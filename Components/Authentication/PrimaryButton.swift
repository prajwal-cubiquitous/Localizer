//
//  PrimaryButton.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: isLoading ? {} : action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 50)
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Sign In") {}
        PrimaryButton(title: "Loading", isLoading: true) {}
    }
    .padding()
}
