//
//  AlertsEnum.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/29/25.
//
import FirebaseAuth

enum AuthError: Error, Identifiable {
    case invalidEmail
    case weakPassword
    case emailInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknownError(code: Int, message: String) 
    case custom(message: String)
    
    var id: String { localizedDescription }
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password should be at least 6 characters"
        case .emailInUse:
            return "This email is already in use"
        case .userNotFound:
            return "Account not found"
        case .wrongPassword:
            return "Incorrect password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknownError:
            return "An unknown error occurred"
        case .custom(let message):
            return message
        }
    }
    
    init(error: Error) {
        let nsError = error as NSError
        if let authCode = AuthErrorCode(rawValue: nsError.code) {
            switch authCode {
            case .invalidEmail:
                self = .invalidEmail
            case .weakPassword:
                self = .weakPassword
            case .emailAlreadyInUse:
                self = .emailInUse
            case .userNotFound:
                self = .userNotFound
            case .wrongPassword:
                self = .wrongPassword
            case .networkError:
                self = .networkError
            default:
                self = .unknownError(code: nsError.code, message: nsError.localizedDescription)
            }
        } else {
            self = .unknownError(code: nsError.code, message: nsError.localizedDescription)
        }
    }
}
