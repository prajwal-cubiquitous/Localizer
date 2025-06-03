//
//  contentViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 5/29/25.
//

import Foundation
import FirebaseAuth
import Combine

class ContentViewModel: ObservableObject{
    
    @Published var userSession: FirebaseAuth.User?
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        Task{@MainActor in 
            setupSubscriptions()
        }
    }
    
    @MainActor
    private func setupSubscriptions() {
        AppState.shared.$userSession
            .receive(on: DispatchQueue.main) // Ensure this runs on main thread
            .sink { [weak self] userSession in
                self?.userSession = userSession
            }
            .store(in: &cancellables)
    }
}
