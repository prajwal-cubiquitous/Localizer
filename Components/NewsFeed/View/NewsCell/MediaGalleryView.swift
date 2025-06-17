//
//  MediaGalleryView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI
import AVKit
import Kingfisher

// MARK: - Media Gallery Component
struct MediaGalleryView: View {
    let mediaURLs: [String]
    @State private var currentIndex = 0
    
    // ✅ Enhanced responsive media height for all iPhone models including iPhone 13
    private var mediaHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        // Device-specific calculations
        switch screenWidth {
        case 0..<375: // iPhone SE (1st/2nd gen), iPhone 12/13 mini
            return min(screenWidth * 0.75, 280)
            
        case 375..<390: // iPhone 6/7/8, iPhone X/XS, iPhone 12/13/14
            return min(screenWidth * 0.7, 300)
            
        case 390..<430: // iPhone 12/13/14 Pro, iPhone 15/15 Pro
            return min(screenWidth * 0.68, 320)
            
        default: // iPhone Plus, Pro Max models
            return min(screenWidth * 0.65, 350)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if mediaURLs.count == 1 {
                // ✅ Single media item - use MediaItemView for consistency
                MediaItemView(urlString: mediaURLs[0], height: mediaHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Multiple media items - use TabView
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, urlString in
                            MediaItemView(urlString: urlString, height: mediaHeight)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: mediaHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Page indicators for multiple items
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            // Custom page indicators
                            HStack(spacing: 6) {
                                ForEach(0..<mediaURLs.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Media counter
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(currentIndex + 1) of \(mediaURLs.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Capsule())
                                .padding(.trailing, 12)
                                .padding(.top, 12)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
