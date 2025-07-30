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
    @Published var currentLanguage: Language {
        didSet {
            // 🟡 1. Check if this block is being called
            print("🟡 LanguageManager: didSet triggered. New language is \(currentLanguage.rawValue)")
            
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            print("🟡 LanguageManager: Saved '\(currentLanguage.rawValue)' to UserDefaults.")
            
            Bundle.setLanguage(currentLanguage.rawValue)
        }
    }

    init() {
        let savedLangCode = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        self.currentLanguage = Language(rawValue: savedLangCode) ?? .english
        // 🔵 Check initial language on app start
        print("🔵 LanguageManager: Initialized with language '\(currentLanguage.rawValue)'")
    }
}
