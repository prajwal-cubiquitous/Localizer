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
    
    @State private var postLocation = ""
    @State private var postTitle = ""
    @State private var postContent = ""
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPosting = false
    @State private var selectedCategory: String? = nil
    
    let categories = ["Politics", "Crime", "Accident", "Sports", "Entertainment"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
                
                Text("Create Post")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                // Empty view for alignment
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Location selector
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray)
                        
                        // Dropdown for location selection
                        Menu {
                            Button("Bengaluru, Karnataka", action: { postLocation = "Bengaluru, Karnataka" })
                            Button("Mumbai, Maharashtra", action: { postLocation = "Mumbai, Maharashtra" })
                            Button("Delhi, NCR", action: { postLocation = "Delhi, NCR" })
                            Button("Chennai, Tamil Nadu", action: { postLocation = "Chennai, Tamil Nadu" })
                        } label: {
                            HStack {
                                Text(postLocation.isEmpty ? "Select location" : postLocation)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                VStack(spacing: 5) {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 10))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding(16)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    
                    // Title field
                    TextField("Title", text: $postTitle)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    
                    // Content field
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $postContent)
                            .font(.system(size: 16))
                            .padding(8)
                            .frame(height: 150)
                            .scrollContentBackground(.hidden)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .cornerRadius(8)
                        
                        if postContent.isEmpty {
                            Text("Write your story")
                                .font(.system(size: 16))
                                .foregroundStyle(.gray)
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Add media section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Media")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        // Media preview
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(alignment: .topTrailing) {
                                    Button(action: {
                                        self.selectedImage = nil
                                        self.selectedItem = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                            .padding(8)
                                    }
                                }
                        }
                        
                        // Add image/video button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "photo")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.gray)
                                }
                                
                                Text("Add Image/Video")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 10)
                        }
                        .onChange(of: selectedItem) { oldValue, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Category section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Category")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        // Category pills
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category == selectedCategory ? nil : category
                                }) {
                                    Text(category)
                                        .font(.system(size: 14))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .foregroundStyle(selectedCategory == category ? 
                                                        .white : 
                                                        (colorScheme == .dark ? .white : .black))
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category ? 
                                                    (colorScheme == .dark ? .blue : .black) : 
                                                    (colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer(minLength: 60)
                }
                .padding(.vertical, 10)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            
            // Post button
            Button(action: {
                isPosting = true
                
                // Simulate posting delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    postTitle = ""
                    postContent = ""
                    postLocation = ""
                    selectedImage = nil
                    selectedItem = nil
                    selectedCategory = nil
                    isPosting = false
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Post")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isFormValid ? 
                                 (colorScheme == .dark ? Color.blue : Color.black) : 
                                 (colorScheme == .dark ? Color.gray.opacity(0.7) : Color.gray))
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .disabled(!isFormValid || isPosting)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
//        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private var isFormValid: Bool {
        !postTitle.isEmpty && !postContent.isEmpty && selectedCategory != nil
    }
}

struct DarkModePreview: PreviewProvider {
    static var previews: some View {
        PostView(pincode: "560001")
            .preferredColorScheme(.dark)
    }
}

#Preview {
    PostView(pincode: "560001")
        .preferredColorScheme(.light)
}
