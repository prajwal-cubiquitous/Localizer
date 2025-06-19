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
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Remove button (top-right)
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
                    .padding(6)
                    
                    // Edit button (center)
                    Button {
                        onEdit(image)
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.blue))
                    }
                }
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

// MARK: - Advanced Image Editor
struct ImageEditorView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var currentImage: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var lastOffset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var selectedAspectRatio: AspectRatio = .original
    @State private var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var isCropMode = false
    @State private var selectedTab = 0
    
    enum AspectRatio: String, CaseIterable {
        case original = "Original"
        case square = "1:1"
        case portrait = "4:5"
        case landscape = "16:9"
        case story = "9:16"
        
        var ratio: CGFloat? {
            switch self {
            case .original: return nil
            case .square: return 1.0
            case .portrait: return 4.0/5.0
            case .landscape: return 16.0/9.0
            case .story: return 9.0/16.0
            }
        }
    }
    
    init(image: UIImage, onSave: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.image = image
        self.onSave = onSave
        self.onCancel = onCancel
        self._currentImage = State(initialValue: image)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Image preview section
                GeometryReader { geometry in
                    ZStack {
                        Color.black.opacity(0.9)
                        
                        Image(uiImage: currentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .rotationEffect(.degrees(rotation))
                            .brightness(brightness)
                            .contrast(contrast)
                            .saturation(saturation)
                            .clipped()
                            .overlay(
                                // Crop overlay
                                isCropMode ? 
                                CropOverlayView(
                                    aspectRatio: selectedAspectRatio.ratio,
                                    imageSize: currentImage.size,
                                    containerSize: geometry.size
                                ) : nil
                            )
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScaleValue
                                            lastScaleValue = value
                                            scale = max(0.5, min(3.0, scale * delta))
                                        }
                                        .onEnded { _ in
                                            lastScaleValue = 1.0
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            )
                    }
                }
                .frame(height: 400)
                
                // Tab selection
                Picker("Edit Mode", selection: $selectedTab) {
                    Text("Adjust").tag(0)
                    Text("Crop").tag(1)
                    Text("Rotate").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .onChange(of: selectedTab) { newValue in
                    isCropMode = (newValue == 1)
                }
                
                // Controls based on selected tab
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            // Adjustment controls
                            adjustmentControls
                        } else if selectedTab == 1 {
                            // Crop controls
                            cropControls
                        } else {
                            // Rotation controls
                            rotationControls
                        }
                        
                        // Reset button
                        HStack {
                            Button("Reset All") {
                                resetAll()
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            
                            Spacer()
                            
                            Button("Reset Current") {
                                resetCurrent()
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let editedImage = applyAllEdits()
                        onSave(editedImage)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // MARK: - Adjustment Controls
    private var adjustmentControls: some View {
        VStack(spacing: 20) {
            Text("Color Adjustments")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Brightness
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sun.max")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        Text("Brightness")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(brightness * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $brightness, in: -0.5...0.5)
                        .accentColor(.orange)
                }
                
                // Contrast
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundColor(.purple)
                            .frame(width: 20)
                        Text("Contrast")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(contrast * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $contrast, in: 0.5...2.0)
                        .accentColor(.purple)
                }
                
                // Saturation
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.pink)
                            .frame(width: 20)
                        Text("Saturation")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(saturation * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $saturation, in: 0...2.0)
                        .accentColor(.pink)
                }
                
                // Scale
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("Zoom")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(scale * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $scale, in: 0.5...3.0)
                        .accentColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Crop Controls
    private var cropControls: some View {
        VStack(spacing: 20) {
            Text("Aspect Ratio")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(AspectRatio.allCases, id: \.self) { ratio in
                        Button {
                            selectedAspectRatio = ratio
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedAspectRatio == ratio ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 50, height: ratio == .landscape ? 28 : ratio == .story ? 90 : ratio == .portrait ? 62 : 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                                
                                Text(ratio.rawValue)
                                    .font(.caption)
                                    .foregroundColor(selectedAspectRatio == ratio ? .blue : .primary)
                            }
                        }
                    }
                }
                
                Button("Apply Crop") {
                    applyCrop()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Rotation Controls
    private var rotationControls: some View {
        VStack(spacing: 20) {
            Text("Rotation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Rotation slider
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "rotate.right")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Angle")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(rotation))°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $rotation, in: -180...180)
                        .accentColor(.green)
                }
                
                // Quick rotation buttons
                HStack(spacing: 20) {
                    Button("↺ 90°") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            rotation -= 90
                            if rotation < -180 { rotation += 360 }
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("↻ 90°") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            rotation += 90
                            if rotation > 180 { rotation -= 360 }
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("180°") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            rotation += 180
                            if rotation > 180 { rotation -= 360 }
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Functions
    private func resetAll() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            brightness = 0
            contrast = 1
            saturation = 1
            rotation = 0
            selectedAspectRatio = .original
            lastOffset = .zero
            lastScaleValue = 1.0
            currentImage = image
        }
    }
    
    private func resetCurrent() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch selectedTab {
            case 0: // Adjustments
                brightness = 0
                contrast = 1
                saturation = 1
                scale = 1.0
                offset = .zero
                lastOffset = .zero
                lastScaleValue = 1.0
            case 1: // Crop
                selectedAspectRatio = .original
            case 2: // Rotation
                rotation = 0
            default:
                break
            }
        }
    }
    
    private func applyCrop() {
        // Apply the current crop settings to the image
        if let croppedImage = cropImage(currentImage, aspectRatio: selectedAspectRatio.ratio) {
            currentImage = croppedImage
            // Reset transform values after crop
            scale = 1.0
            offset = .zero
            lastOffset = .zero
            lastScaleValue = 1.0
        }
    }
    
    private func cropImage(_ image: UIImage, aspectRatio: CGFloat?) -> UIImage? {
        guard let aspectRatio = aspectRatio else { return image }
        
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        
        var cropSize: CGSize
        
        if imageAspectRatio > aspectRatio {
            // Image is wider than target ratio
            cropSize = CGSize(width: imageSize.height * aspectRatio, height: imageSize.height)
        } else {
            // Image is taller than target ratio
            cropSize = CGSize(width: imageSize.width, height: imageSize.width / aspectRatio)
        }
        
        let cropRect = CGRect(
            x: (imageSize.width - cropSize.width) / 2,
            y: (imageSize.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    private func applyAllEdits() -> UIImage {
        var editedImage = currentImage
        
        // Apply rotation
        if rotation != 0 {
            editedImage = rotateImage(editedImage, degrees: rotation) ?? editedImage
        }
        
        // Apply color adjustments
        editedImage = applyColorFilters(to: editedImage)
        
        return editedImage
    }
    
    private func rotateImage(_ image: UIImage, degrees: Double) -> UIImage? {
        let radians = degrees * .pi / 180
        
        var newSize = CGRect(origin: CGPoint.zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .size
        
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        context.rotate(by: CGFloat(radians))
        
        image.draw(in: CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func applyColorFilters(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        var filteredImage = ciImage
        
        // Apply color adjustments
        let colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(filteredImage, forKey: kCIInputImageKey)
        colorFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
        colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        
        if let output = colorFilter.outputImage,
           let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
}

// MARK: - Crop Overlay View
struct CropOverlayView: View {
    let aspectRatio: CGFloat?
    let imageSize: CGSize
    let containerSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay
                Color.black.opacity(0.5)
                
                // Clear crop area
                if let aspectRatio = aspectRatio {
                    let cropSize = calculateCropSize(containerSize: geometry.size, aspectRatio: aspectRatio)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: cropSize.width, height: cropSize.height)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .background(Color.clear)
                        )
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
        }
    }
    
    private func calculateCropSize(containerSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        let containerAspectRatio = containerSize.width / containerSize.height
        
        if containerAspectRatio > aspectRatio {
            // Container is wider than crop ratio
            let height = containerSize.height * 0.8
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Container is taller than crop ratio
            let width = containerSize.width * 0.8
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

#Preview {
    PostView(ConstituencyId: DummyConstituencyDetials.detials1.id ?? "test")
}
