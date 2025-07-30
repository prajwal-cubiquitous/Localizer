//
//  Extension.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 7/30/25.
//

// Extensions.swift
import Foundation

private var localizedBundle: Bundle?
extension Bundle {
    static var overridenBundle: Bundle? {
        return localizedBundle
    }

    static func setLanguage(_ languageCode: String) {
        // 🟢 2. Check if this function is being called
        print("🟢 Bundle.setLanguage: Attempting to set language to '\(languageCode)'")
        
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            // 🔴 THIS IS A COMMON FAILURE POINT
            print("🔴 Bundle.setLanguage: FAILURE! Could not find path for language code '\(languageCode)'. Make sure you have a 'kn.lproj' folder in your project.")
            localizedBundle = nil
            return
        }
        
        localizedBundle = Bundle(path: path)
        
        if localizedBundle != nil {
            print("🟢 Bundle.setLanguage: SUCCESS! Custom bundle was set for '\(languageCode)'")
        } else {
            print("🔴 Bundle.setLanguage: FAILURE! Bundle path was found but creating the bundle failed.")
        }
    }
}

extension String {
    func localized() -> String {
        // 🟣 4. See which bundle is being used for your text
        let bundle = Bundle.overridenBundle ?? Bundle.main
        
        if bundle == Bundle.main {
             print("🟣 String.localized: Using MAIN bundle for key '\(self)'")
        } else {
             print("🟣 String.localized: Using OVERRIDDEN bundle for key '\(self)'")
        }
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}
