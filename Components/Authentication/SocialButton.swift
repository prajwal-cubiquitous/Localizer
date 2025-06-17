//
//  SocialButton.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct SocialButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .imageScale(.medium)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color(.systemBackground)),
            )
            .foregroundStyle(Color.primary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        SocialButton(title: "Continue with Apple", systemImage: "apple.logo") {}
        SocialButton(title: "Continue with Google", systemImage: "g.circle.fill") {}
    }
    .padding()
}
