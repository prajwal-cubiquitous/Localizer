//
//  MediaItemView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI
import AVKit
import Kingfisher

// MARK: - Individual Media Item Component  
struct MediaItemView: View {
    let urlString: String
    let height: CGFloat
    
    var body: some View {
        if urlString.contains("news_videos") {
            // Video Player for TabView
            if let videoUrl = URL(string: urlString) {
                VideoPlayer(player: AVPlayer(url: videoUrl))
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .background(Color.black)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .overlay(
                        Text("Invalid video URL")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
        } else {
            // Image for TabView
            KFImage(URL(string: urlString))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: height)
                .clipped()
        }
    }
}
