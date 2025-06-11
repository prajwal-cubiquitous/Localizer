//
//  ProfilePictureView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/11/25.
//

import SwiftUI
import Kingfisher

struct ProfilePictureView: View {
    
    let userProfileUrl: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
            if let profileUrl = userProfileUrl {
                KFImage(URL(string: profileUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                    )
                    .shadow(radius: 5)
                    .padding(.bottom, 8)
            }
        else{
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                )
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    ProfilePictureView(userProfileUrl: "", width: 100, height: 100)
}
