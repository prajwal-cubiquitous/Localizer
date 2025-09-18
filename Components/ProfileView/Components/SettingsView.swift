//
//  SettingsView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 9/18/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedLanguage = "English"
    @State private var defaultConstituency = "560043"
    @State private var primaryConstituency = "560043"
    @State private var secondaryConstituency = "560001"
    @State private var thirdConstituency = "560002"
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var autoPlayVideos = true
    @State private var dataSaverMode = false
    @State private var showingLogoutAlert = false
    @State private var showingLanguagePicker = false
    @State private var showingConstituencyPicker = false
    @State private var showingConstituencySelection = false
    
    let languages = ["English", "ಕನ್ನಡ"]
    let constituencies = ["560043", "560001", "560002", "560003", "560004", "560005"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    VStack(spacing: 16) {
                        // Profile Picture and Info
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(spacing: 4) {
                                Text("Prajwal S S Reddy")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("prajwal@example.com")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Settings Sections
                    VStack(spacing: 24) {
                        // Account Settings
                        SettingsSection(title: "Account") {
                            SettingsRow(
                                icon: "person.circle",
                                title: "Edit Profile",
                                subtitle: "Update your personal information",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "key",
                                title: "Change Password",
                                subtitle: "Update your account security",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "envelope",
                                title: "Email Settings",
                                subtitle: "Manage email notifications",
                                action: {}
                            )
                        }
                        
                        // Location & Constituency Settings
                        SettingsSection(title: "Location & Constituency") {
                            SettingsRow(
                                icon: "location.circle",
                                title: "Default Constituency",
                                subtitle: "Set your primary constituency",
                                value: defaultConstituency,
                                action: { showingConstituencyPicker = true }
                            )
                            
                            SettingsRow(
                                icon: "map",
                                title: "Constituency Selection",
                                subtitle: "Manage multiple constituencies",
                                action: { showingConstituencySelection = true }
                            )
                            
                            SettingsRow(
                                icon: "location.fill",
                                title: "Location Services",
                                subtitle: "Enable location-based features",
                                action: {}
                            )
                        }
                        
                        // App Preferences
                        SettingsSection(title: "App Preferences") {
                            SettingsRow(
                                icon: "globe",
                                title: "Language",
                                subtitle: "Select your preferred language",
                                value: selectedLanguage,
                                action: { showingLanguagePicker = true }
                            )
                            
                            SettingsToggleRow(
                                icon: "moon.fill",
                                title: "Dark Mode",
                                subtitle: "Switch between light and dark themes",
                                isOn: $darkModeEnabled
                            )
                            
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Push Notifications",
                                subtitle: "Receive app notifications",
                                isOn: $notificationsEnabled
                            )
                            
                            SettingsToggleRow(
                                icon: "play.circle.fill",
                                title: "Auto-play Videos",
                                subtitle: "Automatically play videos in feed",
                                isOn: $autoPlayVideos
                            )
                            
                            SettingsToggleRow(
                                icon: "wifi.slash",
                                title: "Data Saver Mode",
                                subtitle: "Reduce data usage",
                                isOn: $dataSaverMode
                            )
                        }
                        
                        // Privacy & Security
                        SettingsSection(title: "Privacy & Security") {
                            SettingsRow(
                                icon: "lock.shield",
                                title: "Privacy Settings",
                                subtitle: "Control your data and privacy",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "eye.slash",
                                title: "Blocked Users",
                                subtitle: "Manage blocked accounts",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "hand.raised",
                                title: "Content Filtering",
                                subtitle: "Filter sensitive content",
                                action: {}
                            )
                        }
                        
                        // Support & About
                        SettingsSection(title: "Support & About") {
                            SettingsRow(
                                icon: "questionmark.circle",
                                title: "Help & Support",
                                subtitle: "Get help and contact support",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "star.fill",
                                title: "Rate App",
                                subtitle: "Rate us on the App Store",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "info.circle",
                                title: "About",
                                subtitle: "App version and information",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "doc.text",
                                title: "Terms of Service",
                                subtitle: "Read our terms and conditions",
                                action: {}
                            )
                            
                            SettingsRow(
                                icon: "hand.raised.fill",
                                title: "Privacy Policy",
                                subtitle: "How we protect your data",
                                action: {}
                            )
                        }
                        
                        // Danger Zone
                        SettingsSection(title: "Account Actions") {
                            SettingsRow(
                                icon: "arrow.right.square",
                                title: "Logout",
                                subtitle: "Sign out of your account",
                                isDestructive: true,
                                action: { showingLogoutAlert = true }
                            )
                            
                            SettingsRow(
                                icon: "trash",
                                title: "Delete Account",
                                subtitle: "Permanently delete your account",
                                isDestructive: true,
                                action: {}
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground))
        }
        .overlay(
            Group {
                if showingLanguagePicker {
                    LanguagePickerView(selectedLanguage: $selectedLanguage)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeInOut(duration: 0.2), value: showingLanguagePicker)
                }
            }
        )
        .sheet(isPresented: $showingConstituencyPicker) {
            ConstituencyPickerView(selectedConstituency: $defaultConstituency)
        }
        .sheet(isPresented: $showingConstituencySelection) {
            ConstituencySelectionView(
                primaryConstituency: $primaryConstituency,
                secondaryConstituency: $secondaryConstituency,
                thirdConstituency: $thirdConstituency
            )
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                // Logout functionality will be implemented later
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, value: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Value or Chevron
                if let value = value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let action: (() -> Void)?
    
    init(icon: String, title: String, subtitle: String? = nil, isOn: Binding<Bool>, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _ in
                    action?()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Language Picker View
struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    let languages = ["English", "ಕನ್ನಡ"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Language")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // Language Options
            VStack(spacing: 0) {
                ForEach(Array(languages.enumerated()), id: \.offset) { index, language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(UIColor.systemBackground))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < languages.count - 1 {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .ignoresSafeArea()
        .onTapGesture {
            dismiss()
        }
    }
}

// MARK: - Constituency Picker View
struct ConstituencyPickerView: View {
    @Binding var selectedConstituency: String
    @Environment(\.dismiss) private var dismiss
    
    let constituencies = ["560043", "560001", "560002", "560003", "560004", "560005"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(constituencies, id: \.self) { constituency in
                    Button(action: {
                        selectedConstituency = constituency
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Constituency \(constituency)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Sample Area Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedConstituency == constituency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Constituency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Constituency Selection View
struct ConstituencySelectionView: View {
    @Binding var primaryConstituency: String
    @Binding var secondaryConstituency: String
    @Binding var thirdConstituency: String
    @Environment(\.dismiss) private var dismiss
    
    let constituencies = ["560043", "560001", "560002", "560003", "560004", "560005"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Constituency Selection")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select up to three constituencies to follow news and updates from these areas.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                    
                    // Primary Constituency
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Primary Constituency")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("Required")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        ConstituencySelectionCard(
                            title: "Primary",
                            selectedConstituency: $primaryConstituency,
                            constituencies: constituencies,
                            isRequired: true
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Secondary Constituency
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Secondary Constituency")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("Optional")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        ConstituencySelectionCard(
                            title: "Secondary",
                            selectedConstituency: $secondaryConstituency,
                            constituencies: constituencies,
                            isRequired: false
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Third Constituency
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Third Constituency")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("Optional")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        ConstituencySelectionCard(
                            title: "Third",
                            selectedConstituency: $thirdConstituency,
                            constituencies: constituencies,
                            isRequired: false
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Information")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Primary constituency is used as your default location")
                            Text("• You'll receive notifications from all selected constituencies")
                            Text("• You can change these selections anytime")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Constituency Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save functionality will be implemented later
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Constituency Selection Card
struct ConstituencySelectionCard: View {
    let title: String
    @Binding var selectedConstituency: String
    let constituencies: [String]
    let isRequired: Bool
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isRequired ? .red : .blue)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(title) Constituency")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if selectedConstituency.isEmpty {
                        Text("Tap to select constituency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Constituency \(selectedConstituency)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isRequired ? Color.red.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPicker) {
            ConstituencyPickerView(selectedConstituency: $selectedConstituency)
        }
    }
}

#Preview {
    SettingsView()
}
