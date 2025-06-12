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
    
    // Responsive media height based on screen size
    private var mediaHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 64 // Account for margins and padding
        
        // Maintain 16:9 aspect ratio but with reasonable limits
        let calculatedHeight = availableWidth * 9 / 16
        return min(max(calculatedHeight, 200), 320) // Between 200-320pt
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if mediaURLs.count == 1 {
                // Single media item - ensure consistent height and proper video handling
                let urlString = mediaURLs[0]
                
                if urlString.contains("news_videos") {
                    // Single Video - use proper frame constraints
                    if let videoUrl = URL(string: urlString) {
                        VideoPlayer(player: AVPlayer(url: videoUrl))
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Rectangle()
                            .fill(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Text("Invalid video URL")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            )
                    }
                } else {
                    // Single Image
                    KFImage(URL(string: urlString))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: mediaHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
