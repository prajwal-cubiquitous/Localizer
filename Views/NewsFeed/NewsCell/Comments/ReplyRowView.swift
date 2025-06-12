//
//  ReplyRowView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 6/12/25.
//
import SwiftUI

// 2. View for a Single Reply Row
struct ReplyRowView: View {
    let reply: Reply
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let user = UserCache.shared.cacheusers[reply.userId]{
                ProfilePictureView(userProfileUrl: user.profilePictureUrl, width: 30, height: 30)
            }else{
                Image(systemName:"person.crop.circle.badge.questionmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .padding(4)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if let user = UserCache.shared.cacheusers[reply.userId]{
                        Text(user.username)
                            .font(.system(size: 13, weight: .semibold))
                    }else{
                        Text("Unkown User")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(reply.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text(reply.text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.leading, 40) // Indent replies
        .padding(.vertical, 4)
    }
}
