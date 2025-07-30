//
//  StylishPicker.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/17/25.
//


import SwiftUI

struct StylishPicker: View {
    let list: [ConstituencyDetails]
    @Binding var selectedName: String
    @State private var showMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Constituency".localized())
                .font(.headline)
                .foregroundColor(.gray)

            Button {
                withAnimation(.spring()) {
                    showMenu.toggle()
                }
            } label: {
                HStack {
                    Text(selectedName.isEmpty ? "Choose..." : selectedName)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: showMenu ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
            }

            if showMenu {
                VStack(spacing: 0) {
                    ForEach(list, id: \.constituencyName) { item in
                        Button {
                            selectedName = item.constituencyName
                            withAnimation(.easeOut) {
                                showMenu = false
                            }
                        } label: {
                            HStack {
                                Text(item.constituencyName)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 10)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.white.opacity(0.001)) // fix for tap issue
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 5)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
    }
}

