//
//  SignupView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject private var viewModel : AuthViewModel
    @State private var offsetY: CGFloat = 30
    @State private var opacity: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Create Account".localized())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign up to get started".localized())
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 16)
                
                // Form
                VStack(spacing: 16) {
                    AuthTextField(
                        title: "Full Name".localized(),
                        placeholder: "Enter your full name".localized(),
                        systemImage: "person",
                        text: $viewModel.fullName
                    )
                    
                    AuthTextField(
                        title: "UserName".localized(),
                        placeholder: "Enter your userName".localized(),
                        systemImage: "person.circle",
                        text: $viewModel.username
                    )
                    
                    AuthTextField(
                        title: "Email".localized(),
                        placeholder: "Enter your email".localized(),
                        systemImage: "envelope",
                        text: $viewModel.email
                    )
                    
                    AuthTextField(
                        title: "Password".localized(),
                        placeholder: "Create a password".localized(),
                        systemImage: "lock",
                        text: $viewModel.password,
                        isSecure: true
                    )
                    
                    AuthTextField(
                        title: "Confirm Password".localized(),
                        placeholder: "Confirm your password".localized(),
                        systemImage: "lock.shield",
                        text: $viewModel.confirmPassword,
                        isSecure: true
                    )
                }
                
                // Password validation message
                if !viewModel.password.isEmpty && viewModel.password.count < 8 {
                    Text("Password must be at least 8 characters".localized())
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -8)
                }
                
                // Error message if any
//                if let errorMessage = viewModel.errorMessage {
//                    Text(errorMessage)
//                        .font(.subheadline)
//                        .foregroundStyle(.red)
//                        .padding(.top, 8)
//                        .transition(.move(edge: .top).combined(with: .opacity))
//                }
                
                // Terms and Conditions
                HStack {
                    Text("By signing up, you agree to our ".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        // Handle terms and conditions
                    }) {
                        Text("Terms & Conditions".localized())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.top, 8)
                
                // Signup Button
                VStack(spacing: 16) {
                    PrimaryButton(
                        title: "Create Account".localized(),
                        isLoading: viewModel.isLoading
                    ) {
                        Task{
                            try await viewModel.signup()
                        }
                    }
                    .disabled(!viewModel.isSignupFormValid)
                    .opacity(viewModel.isSignupFormValid ? 1.0 : 0.7)
                }
                .padding(.top, 16)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(AppColors.dividerColor)
                        .frame(height: 1)
                    
                    Text("OR".localized())
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .fill(AppColors.dividerColor)
                        .frame(height: 1)
                }
                .padding(.vertical, 24)
                
                // Social Login Options
                VStack(spacing: 12) {
                    SocialButton(
                        title: "Continue with Apple",
                        systemImage: "apple.logo"
                    ) {
                        // Handle Apple sign in
                    }
                    
                    SocialButton(
                        title: "Continue with Google",
                        systemImage: "g.circle.fill"
                    ) {
                        // Handle Google sign in
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .scrollDismissesKeyboard(.immediately)
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                offsetY = 0
                opacity = 1
            }
        }
        .alert(item: $viewModel.errorMessage){ error in
            Alert(title: Text("Error".localized()), message: Text(error.localizedDescription), dismissButton: .default(Text("OK".localized())))
        }
    }
}

//#Preview {
//    SignupView()
//        .environmentObject(AuthViewModel())
//}
