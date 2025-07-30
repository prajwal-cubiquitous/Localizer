//
//  Language.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/30/25.
//


// LanguageManager.swift
import Foundation
import Combine // For ObservableObject

// Define the keys for UserDefaults
enum Language: String, CaseIterable {
    case english = "en"
    case kannada = "kn"

    var title: String {
        switch self {
        case .english:
            return "English"
        case .kannada:
            return "ಕನ್ನಡ" // Kannada
        }
    }
}

class LanguageManager: ObservableObject {
    // @Published will notify views when the language changes
    @Published var currentLanguage: Language {
        didSet {
            // Save the new language selection to UserDefaults
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            // Update the app's bundle to the new language
            Bundle.setLanguage(currentLanguage.rawValue)
        }
    }

    init() {
        // Get the saved language from UserDefaults, or default to English
        let savedLangCode = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        self.currentLanguage = Language(rawValue: savedLangCode) ?? .english
    }
}
