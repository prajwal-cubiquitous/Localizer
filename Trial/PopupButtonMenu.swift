//
//  PopupButtonMenu.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/20/25.
//


import SwiftUI

struct FancyPopupMenu: View {
    @State private var showPopup = false

    var body: some View {
//        ZStack(alignment: .bottomTrailing) {
//            // Main background
//            Color(.systemBackground).ignoresSafeArea()
//
//            // Dim background when popup is shown
//            if showPopup {
//                Color.black.opacity(0.3)
//                    .ignoresSafeArea()
//                    .transition(.opacity)
//                    .onTapGesture {
//                        withAnimation(.spring()) {
//                            showPopup = false
//                        }
//                    }
//            }
//
//            // Popup buttons stack
//            VStack(spacing: 16) {
//                if showPopup {
//                    PopupButton(label: "Edit", systemImage: "pencil", color: .blue) {
//                        print("Edit tapped")
//                        showPopup = false
//                    }
//
//                    PopupButton(label: "Delete", systemImage: "trash", color: .red) {
//                        print("Delete tapped")
//                        showPopup = false
//                    }
//
//                    PopupButton(label: "Share", systemImage: "square.and.arrow.up", color: .green) {
//                        print("Share tapped")
//                        showPopup = false
//                    }
//                }
//            }
//            .padding(.trailing, 16)
//            .padding(.bottom, 100)
//            .transition(.move(edge: .trailing).combined(with: .opacity))
//            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPopup)
//
//            // Main floating button
//            Button(action: {
//                withAnimation {
//                    showPopup.toggle()
//                }
//            }) {
//                Image(systemName: showPopup ? "xmark" : "plus")
//                    .font(.system(size: 28, weight: .bold))
//                    .frame(width: 64, height: 64)
//                    .background(.ultraThinMaterial)
//                    .foregroundColor(.primary)
//                    .clipShape(Circle())
//                    .shadow(radius: 5)
//                    .overlay(
//                        Circle()
//                            .strokeBorder(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
//                    )
//            }
//            .padding(.trailing, 20)
//            .padding(.bottom, 20)
//        }
        
        VStack{
            Menu {
                Button("Don't recommend posts from this user") {
                    print("Blocked user recommendations")
                }
                Button("Don't recommend this post") {
                    print("Post marked not recommended")
                }
            } label: {
                Label("Don't Recommend", systemImage: "hand.thumbsdown.fill")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
            }

        }
    }
}

struct PopupButton: View {
    var label: String
    var systemImage: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(label)
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .foregroundColor(color)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
    }
}


#Preview{
    FancyPopupMenu()
}
