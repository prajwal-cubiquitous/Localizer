//
//  LoginView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var offsetY: CGFloat = 30
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Welcome Back".localized())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue".localized())
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            // Form
            VStack(spacing: 16) {
                AuthTextField(
                    title: "Email".localized(),
                    placeholder: "Enter your email".localized(),
                    systemImage: "envelope",
                    text: $viewModel.email
                )
                
                AuthTextField(
                    title: "Password".localized(),
                    placeholder: "Enter your password".localized(),
                    systemImage: "lock",
                    text: $viewModel.password,
                    isSecure: true
                )
                
                // Forgot Password
                HStack {
                    Spacer()
                    
                    Button {
                        // Handle forgot password
                        Task{
                            try await viewModel.resetPassword()
                        }
                    } label: {
                        Text("Forgot Password?".localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Error message if any
//            if let errorMessage = viewModel.errorMessage {
//                Text(errorMessage)
//                    .font(.subheadline)
//                    .foregroundStyle(.red)
//                    .padding(.top, 8)
//                    .transition(.move(edge: .top).combined(with: .opacity))
//            }
            
            // Login Button
            VStack(spacing: 16) {
                PrimaryButton(
                    title: "Sign In".localized(),
                    isLoading: viewModel.isLoading
                ) {
                    Task{
                        try await viewModel.login()
                    }
                }
                .disabled(!viewModel.isLoginFormValid)
                .opacity(viewModel.isLoginFormValid ? 1.0 : 0.7)
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
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.appBackground)
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
//
//#Preview {
//    LoginView()
//        .environmentObject(AuthViewModel(appState: AppState()))
//        .preferredColorScheme(.light)
//}
