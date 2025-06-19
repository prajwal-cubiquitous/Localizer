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
    @State private var showingMediaLimitAlert = false
    @State private var mediaLimitMessage = ""
    @State private var showingImageEditor = false
    @State private var imageToEdit: UIImage?
    @State private var editingImageIndex: Int?
    
    init(ConstituencyId: String, onNavigationRequested: ((Bool) -> Void)? = nil) {
        self.ConstituencyId = ConstituencyId
        self.onNavigationRequested = onNavigationRequested
    }
    
    // MARK: - Computed Properties
    private var videoCount: Int {
        viewModel.mediaItems.filter { item in
            if case .video = item { return true }
            return false
        }.count
    }
    
    private var imageCount: Int {
        viewModel.mediaItems.filter { item in
            if case .image = item { return true }
            return false
        }.count
    }
    
    private var canAddMoreMedia: Bool {
        let hasVideo = videoCount > 0
        if hasVideo {
            return imageCount < 4 && videoCount < 1
        } else {
            return imageCount < 5
        }
    }
    
    private var mediaSelectionText: String {
        let hasVideo = videoCount > 0
        if hasVideo {
            return "Add Photos (max 4 with video)"
        } else if imageCount > 0 {
            return "Add Photos & Videos (max 5 photos or 1 video + 4 photos)"
        } else {
            return "Choose Photos & Videos"
        }
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
                            HStack {
                                Text("Add Media")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Media count indicator
                                if !viewModel.mediaItems.isEmpty {
                                    Text("\(viewModel.mediaItems.count)/\(videoCount > 0 ? 5 : 5)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            
                            PhotosPicker(
                                selection: $viewModel.photosPicked,
                                maxSelectionCount: canAddMoreMedia ? (videoCount > 0 ? 4 - imageCount : 5 - viewModel.mediaItems.count) : 0,
                                matching: videoCount > 0 ? .images : .any(of: [.images, .videos])
                            ) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.title2)
                                        .foregroundColor(canAddMoreMedia ? .blue : .gray)
                                    
                                    Text(mediaSelectionText)
                                        .foregroundColor(canAddMoreMedia ? .blue : .gray)
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
                                        .stroke((canAddMoreMedia ? Color.blue : Color.gray).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(viewModel.isProcessing || !canAddMoreMedia)
                            
                            // Media limit info
                            if !canAddMoreMedia {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.orange)
                                    Text("Media limit reached. Remove items to add more.")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            // Media Preview
                            if !viewModel.mediaItems.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(Array(viewModel.mediaItems.enumerated()), id: \.offset) { index, item in
                                            MediaPreviewCard(
                                                item: item,
                                                onRemove: { viewModel.removeMediaItem(at: index) },
                                                onRetrim: { url in viewModel.startVideoRetrimming(for: url) },
                                                onEdit: { image in
                                                    imageToEdit = image
                                                    editingImageIndex = index
                                                    showingImageEditor = true
                                                }
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
                    let success = await viewModel.processPickedPhotos(newItems, 
                                                                   currentVideoCount: videoCount, 
                                                                   currentImageCount: imageCount)
                    if !success.canAdd {
                        await MainActor.run {
                            mediaLimitMessage = success.message
                            showingMediaLimitAlert = true
                        }
                    }
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
        .sheet(isPresented: $showingImageEditor) {
            if let imageToEdit = imageToEdit {
                ImageEditorView(
                    image: imageToEdit,
                    onSave: { editedImage in
                        if let index = editingImageIndex {
                            viewModel.replaceImage(at: index, with: editedImage)
                        }
                        showingImageEditor = false
                        self.imageToEdit = nil
                        self.editingImageIndex = nil
                    },
                    onCancel: {
                        showingImageEditor = false
                        self.imageToEdit = nil
                        self.editingImageIndex = nil
                    }
                )
            }
        }
        .alert("Media Limit Exceeded", isPresented: $showingMediaLimitAlert) {
            Button("OK") { }
        } message: {
            Text(mediaLimitMessage)
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
    let onEdit: (UIImage) -> Void
    
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
                    .contextMenu {
                        Button("Edit Image") {
                            onEdit(image)
                        }
                    }
                
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

// MARK: - Simple Image Editor
struct ImageEditorView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var scale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1
    
    var body: some View {
        NavigationView {
            VStack {
                // Image preview
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .brightness(brightness)
                        .contrast(contrast)
                        .saturation(saturation)
                        .clipped()
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(3.0, value))
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                        )
                }
                .frame(height: 300)
                .background(Color.black)
                .cornerRadius(12)
                
                // Editing controls
                VStack(spacing: 20) {
                    // Brightness
                    VStack {
                        HStack {
                            Text("Brightness")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(brightness * 100))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $brightness, in: -0.5...0.5)
                    }
                    
                    // Contrast
                    VStack {
                        HStack {
                            Text("Contrast")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(contrast * 100))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $contrast, in: 0.5...2.0)
                    }
                    
                    // Saturation
                    VStack {
                        HStack {
                            Text("Saturation")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(saturation * 100))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $saturation, in: 0...2.0)
                    }
                    
                    // Scale
                    VStack {
                        HStack {
                            Text("Zoom")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(scale * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $scale, in: 0.5...3.0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Spacer()
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let editedImage = applyFilters(to: image)
                        onSave(editedImage)
                    }
                }
            }
        }
    }
    
    private func applyFilters(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        var filteredImage = ciImage
        
        // Apply brightness
        if brightness != 0 {
            let brightnessFilter = CIFilter(name: "CIColorControls")!
            brightnessFilter.setValue(filteredImage, forKey: kCIInputImageKey)
            brightnessFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
            if let output = brightnessFilter.outputImage {
                filteredImage = output
            }
        }
        
        // Apply contrast and saturation
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(filteredImage, forKey: kCIInputImageKey)
        colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
        colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        
        if let output = colorFilter.outputImage,
           let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
}

#Preview {
    PostView(ConstituencyId: DummyConstituencyDetials.detials1.id ?? "test")
}
