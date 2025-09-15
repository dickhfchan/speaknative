import SwiftUI

struct NarrativeView: View {
    @StateObject var viewModel = NarrativeViewModel()

    var body: some View {
        List(viewModel.narratives) { item in
            VStack(alignment: .leading) {
                Text(item.title).font(.headline)
                Text(item.content).font(.subheadline).lineLimit(2)
            }
            .onTapGesture { viewModel.selected = item }
        }
        .onAppear { viewModel.loadSample() }
        .navigationTitle("Narratives")
    }
}


