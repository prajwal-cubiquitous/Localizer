//
//  PostView.swift
//  Localizer
//
//  Created on 5/28/25.
//

import SwiftUI
import PhotosUI
import AVKit

//struct PostViewWrapper: View {
//    let pincode: String
//    let onNavigationRequested: (Bool) -> Void
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        PostView(pincode: pincode,  onNavigationRequested: onNavigationRequested)
//    }
//}

struct PostView: View {
    let pincode: String
    let ConstituencyId: String
    let onNavigationRequested: ((Bool) -> Void)?
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel = PostViewModel()
    
    init(pincode: String, ConstituencyId: String, onNavigationRequested: ((Bool) -> Void)? = nil) {
        self.pincode = pincode
        self.ConstituencyId = ConstituencyId
        self.onNavigationRequested = onNavigationRequested
    }
    
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
                            TextEditor(text: $viewModel.caption)
                                .font(.system(size: 16))
                                .padding(16)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            
                            if viewModel.caption.isEmpty {
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
                    
                    // Media Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Media")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if viewModel.isProcessing {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Media Grid
                        if !viewModel.mediaItems.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(Array(viewModel.mediaItems.enumerated()), id: \.offset) { index, item in
                                    MediaPreviewCard(
                                        item: item,
                                        onRemove: {
                                            viewModel.removeMediaItem(at: index)
                                        },
                                        onVideoTap: {
                                            if let videoURL = item.videoURL {
                                                viewModel.startVideoRetrimming(for: videoURL)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Add Media Button
                        PhotosPicker(
                            selection: $viewModel.photosPicked,
                            maxSelectionCount: 10,
                            matching: .any(of: [.images, .videos])
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add Photos & Videos")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Tap to select from gallery")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        .onChange(of: viewModel.photosPicked) { _, newValue in
                            Task {
                                await viewModel.processPickedPhotos(newValue)
                                viewModel.photosPicked.removeAll()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // Post button
            VStack {
                Divider()
                
                Button(action: {
                    Task {
                        await viewModel.createPost(constituencyId: ConstituencyId)
                    }
                }) {
                    HStack {
                        if viewModel.isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(viewModel.isPosting ? "Posting..." : "Share Post")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(viewModel.isFormValid ? Color.blue : Color.secondary)
                    )
                    .padding(.horizontal, 20)
                }
                .disabled(!viewModel.isFormValid || viewModel.isPosting)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $viewModel.isShowingVideoTrimmer) {
            if let videoURL = viewModel.selectedVideoURL {
                VideoTrimmerView(
                    viewModel: viewModel,
                    videoURL: videoURL,
                    initialStartTime: 0,
                    initialEndTime: 30, // Default 30 seconds, will be adjusted based on actual video duration
                    onTrimComplete: { trimmedURL in
                        viewModel.addTrimmedVideo(trimmedURL)
                    }
                )
            }
        }
        .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
                onNavigationRequested?(true)
            }
        } message: {
            Text("Your post has been shared successfully!")
        }
        .alert("Error", isPresented: $viewModel.showFailureAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct MediaPreviewCard: View {
    let item: MediaItem
    let onRemove: () -> Void
    let onVideoTap: (() -> Void)?
    
    init(item: MediaItem, onRemove: @escaping () -> Void, onVideoTap: (() -> Void)? = nil) {
        self.item = item
        self.onRemove = onRemove
        self.onVideoTap = onVideoTap
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch item {
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
                
            case .video(_, let thumbnail):
                Button(action: {
                    onVideoTap?()
                }) {
                    ZStack {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 120)
                                .cornerRadius(12)
                        }
                        
                        // Video overlay with better visibility
                        ZStack {
                            // Background blur for better contrast
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 60, height: 40)
                            
                            VStack(spacing: 2) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                
                                Text("Tap to edit")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
    }
}

#Preview {
    PostView(pincode: "560001", ConstituencyId: "DummyConstituencyDetials.detials1")
        .preferredColorScheme(.light)
}
