//
//  AuthTextField.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct AuthTextField: View {
    let title: String
    let placeholder: String
    let systemImage: String
    let isSecure: Bool
    
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String,
        systemImage: String,
        text: Binding<String>,
        isSecure: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self.systemImage = systemImage
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary.opacity(0.8))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
                    )
                    .shadow(color: isFocused ? Color.accentColor.opacity(0.3) : Color.clear, radius: 5)
                
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundStyle(isFocused ? Color.accentColor : Color.gray)
                    
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .focused($isFocused)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        TextField(placeholder, text: $text)
                            .focused($isFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(title.lowercased().contains("email") ? .never : .words)
                            .textContentType(textContentType)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .animation(.spring(duration: 0.2), value: isFocused)
        }
    }
    
    private var textContentType: UITextContentType? {
        if title.lowercased().contains("email") {
            return .emailAddress
        } else if title.lowercased().contains("name") {
            return .name
        } else if title.lowercased().contains("password") {
            return isSecure ? .newPassword : .password
        }
        return nil
    }
}

#Preview {
    VStack {
        AuthTextField(
            title: "Email",
            placeholder: "Enter your email",
            systemImage: "envelope",
            text: .constant("user@example.com")
        )
        
        AuthTextField(
            title: "Password",
            placeholder: "Enter your password",
            systemImage: "lock",
            text: .constant("password"),
            isSecure: true
        )
    }
    .padding()
}
