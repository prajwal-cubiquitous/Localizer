//
//  AuthContainerView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import SwiftData

struct AuthContainerView: View {
    @StateObject private var viewModel : AuthViewModel
    @Namespace private var animation
    @Environment(\.modelContext) private var modelContext
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header toggle between Login and Signup
                    HStack(spacing: 0) {
                        // Login tab
                        TabButton(
                            title: "Login",
                            isSelected: viewModel.authState == .login,
                            namespace: animation
                        ) {
                            withAnimation(.spring(duration: 0.5)) {
                                if viewModel.authState == .signup {
                                    viewModel.resetFields()
                                    viewModel.authState = .login
                                }
                            }
                        }
                        
                        // Signup tab
                        TabButton(
                            title: "Sign Up",
                            isSelected: viewModel.authState == .signup,
                            namespace: animation
                        ) {
                            withAnimation(.spring(duration: 0.5)) {
                                if viewModel.authState == .login {
                                    viewModel.resetFields()
                                    viewModel.authState = .signup
                                }
                            }
                        }
                    }
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Content area
                    ZStack {
                        if viewModel.authState == .login {
                            LoginView()
                                .environmentObject(viewModel)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    )
                                )
                        } else {
                            SignupView()
                                .environmentObject(viewModel)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    )
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom toggle
                    HStack {
                        Text(viewModel.authState == .login ? "Don't have an account?" : "Already have an account?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            withAnimation(.spring(duration: 0.5)) {
                                viewModel.resetFields()
                                viewModel.authState = viewModel.authState == .login ? .signup : .login
                            }
                        } label: {
                            Text(viewModel.authState == .login ? "Sign Up" : "Login")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                    .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.light) // Default to light mode, can be changed by system
    }
}

// Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.gray)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 30)
                
                if isSelected {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "TAB_INDICATOR", in: namespace)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

//#Preview {
//    AuthContainerView(appState: AppState())
//}
