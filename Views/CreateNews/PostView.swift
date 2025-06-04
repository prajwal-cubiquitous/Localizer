//
//  PostView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import PhotosUI

struct PostView: View {
    let pincode: String
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel = PostViewModel()
    @State private var postContent = ""
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPosting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text("Create Post")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Empty view for alignment
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            
            ScrollView {
                VStack(spacing: 24) {
                    // Content field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's happening?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $postContent)
                                .font(.system(size: 16))
                                .padding(16)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            
                            if postContent.isEmpty {
                                Text("Share your thoughts...")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 24)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Add media section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Media")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        // Media preview
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                                .overlay(alignment: .topTrailing) {
                                    Button(action: {
                                        self.selectedImage = nil
                                        self.selectedItem = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                            .padding(12)
                                    }
                                }
                        } else {
                            // Add image button when no image selected
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Add Photo")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Tap to select from gallery")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                )
                                .cornerRadius(12)
                            }
                        }
                        
                        // Alternative: Add image/video button below preview
                        if selectedImage != nil {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Change Photo")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.blue)
                                }
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .onChange(of: selectedItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // Post button
            VStack {
                Divider()
                
                Button(action: {
                    handlePost()
                }) {
                    HStack {
                        if isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isPosting ? "Posting..." : "Share Post")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(isFormValid ? Color.blue : Color.secondary)
                    )
                    .padding(.horizontal, 20)
                }
                .disabled(!isFormValid || isPosting)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func handlePost() {
        isPosting = true
        
        // Simulate posting delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            postContent = ""
            selectedImage = nil
            selectedItem = nil
            isPosting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var isFormValid: Bool {
        !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    PostView(pincode: "560001")
        .preferredColorScheme(.light)
}

struct PostViewDarkPreview: PreviewProvider {
    static var previews: some View {
        PostView(pincode: "560001")
            .preferredColorScheme(.dark)
    }
}
