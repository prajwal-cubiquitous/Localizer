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
    let ConstituencyId: String
    let onNavigationRequested: ((Bool) -> Void)?
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel = PostViewModel()
    
    init(ConstituencyId: String, onNavigationRequested: ((Bool) -> Void)? = nil) {
        self.ConstituencyId = ConstituencyId
        self.onNavigationRequested = onNavigationRequested
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        // Caption Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("What's happening?")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Text("\(viewModel.caption.count)/500")
                                    .font(.caption)
                                    .foregroundColor(viewModel.caption.count > 450 ? .red : .secondary)
                            }
                            
                            TextEditor(text: $viewModel.caption)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Media Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add Media")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            PhotosPicker(
                                selection: $viewModel.photosPicked,
                                maxSelectionCount: 10,
                                matching: .any(of: [.images, .videos])
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    
                                    Text("Choose Photos & Videos")
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    if viewModel.isProcessing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(viewModel.isProcessing)
                            
                            // Media Preview
                            if !viewModel.mediaItems.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(Array(viewModel.mediaItems.enumerated()), id: \.offset) { index, item in
                                            MediaPreviewCard(
                                                item: item,
                                                onRemove: { viewModel.removeMediaItem(at: index) },
                                                onRetrim: { url in viewModel.startVideoRetrimming(for: url) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(height: 120)
                            }
                        }
                    }
                    .padding(20)
                    
                    Spacer()
                    
                    // Post Button
                    VStack(spacing: 16) {
                        if viewModel.isSensitiveContent {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Sensitive content detected")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Button {
                            Task {
                                await viewModel.createPost(constituencyId: ConstituencyId)
                            }
                        } label: {
                            HStack {
                                if viewModel.isPosting {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(viewModel.isPosting ? "Posting..." : "Share Post")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                viewModel.isFormValid && !viewModel.isPosting ? 
                                Color.blue : Color.gray
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isPosting)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(viewModel.isPosting)
                }
            }
        }
        .onChange(of: viewModel.photosPicked) { oldItems, newItems in
            if !newItems.isEmpty {
                Task {
                    await viewModel.processPickedPhotos(newItems)
                    await MainActor.run {
                        viewModel.photosPicked.removeAll()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingVideoTrimmer) {
            if let videoURL = viewModel.selectedVideoURL {
                VideoTrimmerView(
                    viewModel: viewModel,
                    videoURL: videoURL,
                    initialStartTime: 0,
                    initialEndTime: 30,
                    onTrimComplete: { trimmedURL in
                        viewModel.addTrimmedVideo(trimmedURL)
                    }
                )
            }
        }
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your post has been shared successfully!")
        }
        .alert("Error", isPresented: $viewModel.showFailureAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct MediaPreviewCard: View {
    let item: MediaItem
    let onRemove: () -> Void
    let onRetrim: (URL) -> Void
    
    var body: some View {
        ZStack {
            // Media Content
            switch item {
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(12)
                
            case .video(let url, let thumbnail):
                ZStack {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .cornerRadius(12)
                    }
                    
                    // Play button and video indicator
                    VStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)).frame(width: 40, height: 40))
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "video.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                    }
                    .frame(width: 100, height: 100)
                }
                .contextMenu {
                    Button("Re-trim Video") {
                        onRetrim(url)
                    }
                }
            }
            
            // Remove button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.red))
                    }
                }
                Spacer()
            }
            .padding(4)
        }
        .frame(width: 100, height: 100)
    }
}

#Preview {
    PostView(ConstituencyId: DummyConstituencyDetials.detials1.id ?? "test")
}
