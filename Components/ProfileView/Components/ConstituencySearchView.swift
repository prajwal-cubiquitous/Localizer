//
//  ConstituencySearchView.swift
//  Localizer
//
//  Created by Prajwal S S Reddy on 9/18/25.
//
import SwiftUI

struct ConstituencySearchView: View {
    @StateObject var viewModel = ConstituencySearchViewModel()
    @State private var searchText = ""
    @Binding var selectedConstituencyId: String
    @Binding var selectedConstituencyName : String
    @State var selectedConstituency : ConstituencyDetails?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(viewModel.filteredResults) { constituency in
                VStack(alignment: .leading) {
                    Text(constituency.constituencyName)
                        .font(.headline)
                    Text("MLA: \(constituency.currentMLAName)")
                    Text("Number: \(constituency.constituencyNumber)")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedConstituency = constituency
                    selectedConstituencyId = selectedConstituency?.documentId ?? ""
                    selectedConstituencyName = selectedConstituency?.constituencyName ?? ""
                    dismiss()
                }
            }
            .navigationTitle("Search Constituencies")
            .searchable(text: $searchText, prompt: "Search by name, MLA, number or PIN")
            .onChange(of: searchText) { query in
                viewModel.search(query)
            }
        }
//        // Example: Show details for selected constituency
//        if let selected = selectedConstituency {
//            VStack {
//                Text("Selected: \(selected.constituencyName)")
//                // Display more details or navigate to a detail view
//            }
//        }
    }
}
//#Preview {
//    ConstituencySearchView(viewModel: .constant(DummyConstituencyDetials.detials1), selectedConstituencyId: <#Binding<String>#>, selectedConstituencyName: .constant("Chickpet"))
//}
