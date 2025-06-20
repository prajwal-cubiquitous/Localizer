//
//  Usercell.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/20/25.
//

import SwiftUI

struct Usercell: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            ProfilePictureView(userProfileUrl: user.profileImageUrl, width: 44, height: 44)
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Three Dots
            Menu{
                Button("Recommend User"){
                    
                }
            }label:{
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding()
    }
}

#Preview {
    Usercell(user: DummylocalUser.user1.toUser())
}
