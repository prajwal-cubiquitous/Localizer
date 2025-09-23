//
//  ConstituencyViewModel.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 9/18/25.
//


import FirebaseFirestore
import Combine

class ConstituencySearchViewModel: ObservableObject {
    @Published var allResults: [ConstituencyDetails] = []
    @Published var filteredResults: [ConstituencyDetails] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchAllConstituencies()
    }

    func fetchAllConstituencies() {
        let db = Firestore.firestore()
        db.collection("constituencies").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let data = docs.compactMap { doc -> ConstituencyDetails? in
                try? doc.data(as: ConstituencyDetails.self)
            }
            DispatchQueue.main.async {
                self.allResults = data
                self.filteredResults = data   // Initially show all
            }
        }
    }

    // Local search filter
    func search(_ query: String) {
        if query.isEmpty {
            filteredResults = allResults
        } else {
            filteredResults = allResults.filter { c in
                c.constituencyName.localizedCaseInsensitiveContains(query) ||
                c.currentMLAName.localizedCaseInsensitiveContains(query) ||
                String(c.constituencyNumber).localizedCaseInsensitiveContains(query) ||
                c.associatedPincodes.contains(where: { $0.localizedCaseInsensitiveContains(query) })
            }
        }
    }
}
