//
//  LocationManager.swift
//  Localizer
//
//  Created on 6/3/25.
//

import Foundation
import CoreLocation
import Combine


class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Properties for retry mechanism
    private var retryCount = 0
    private let maxRetries = 3
    private var retryTimer: Timer?
    
    @Published var pincode: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Store the completion handler to call it when the location is found
    private var pincodeCompletionHandler: ((String?) -> Void)?
    
    
    func getCurrentPincode(completion: @escaping (String?) -> Void) {
        // Store the completion handler for later use
        DispatchQueue.main.async { [weak self] in
            self?.pincodeCompletionHandler = completion
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            self.error = nil
        }
        
        // Check if we already have a pincode
        if !pincode.isEmpty {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            completion(pincode)
            return
        }
        
        // Check authorization status
        let status = locationManager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
            // The actual location fetching is handled in the delegate methods
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access denied"])
            }
            completion(nil)
        case .notDetermined:
            requestLocationPermission()
            DispatchQueue.main.async {
                self.isLoading = false
            }
            // Don't call completion here, we'll wait for authorization status to change
        @unknown default:
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status"])
            }
            completion(nil)
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    self.isLoading = false
                    print("DEBUG: Geocoding error: \(error.localizedDescription)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self.error = NSError(domain: "LocationManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No placemark found"])
                    self.isLoading = false
                    print("DEBUG: No placemark found")
                    return
                }
                
                if let postalCode = placemark.postalCode {
                    self.pincode = postalCode
                    print("DEBUG: Found pincode: \(postalCode)")
                    
                    // Update AppState with the pincode
                    AppState.shared.updatePincode(postalCode)
                    
                    // Call the completion handler with the found pincode
                    self.pincodeCompletionHandler?(postalCode)
                    self.pincodeCompletionHandler = nil  // Clear the handler after use
                } else {
                    self.error = NSError(domain: "LocationManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "No postal code found"])
                    print("DEBUG: No postal code found in placemark")
                    
                    // Call the completion handler with nil to indicate failure
                    self.pincodeCompletionHandler?(nil)
                    self.pincodeCompletionHandler = nil  // Clear the handler after use
                }
                
                self.isLoading = false
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = NSError(domain: "LocationManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "No location data"])
            }
            return
        }
        
        print("DEBUG: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        reverseGeocodeLocation(location)
    }
    
    // Retry mechanism is handled in the main class
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.error = error
            print("DEBUG: Location manager error: \(error.localizedDescription)")
            
            // If we haven't exceeded max retries, try again automatically
            if self.retryCount < self.maxRetries {
                self.retryCount += 1
                print("DEBUG: Retry attempt \(self.retryCount) of \(self.maxRetries)")
                
                // Wait 2 seconds before retrying
                self.retryTimer?.invalidate()
                self.retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    print("DEBUG: Retrying location request automatically")
                    self.locationManager.requestLocation()
                }
            } else {
                self.isLoading = false
                print("DEBUG: Maximum retry attempts reached")
                
                // Call completion handler with nil to indicate failure
                self.pincodeCompletionHandler?(nil)
                self.pincodeCompletionHandler = nil
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}
