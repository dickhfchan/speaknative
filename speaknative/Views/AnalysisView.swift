import SwiftUI

struct AnalysisView: View {
    @StateObject var viewModel = AnalysisViewModel()
    let audioURL: URL
    let expectedText: String

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading { ProgressView("Analyzing...") }
            if let res = viewModel.result {
                Text("Score: \(Int(res.overallScore * 100))%")
                List(res.issues) { issue in
                    VStack(alignment: .leading) {
                        Text(issue.word).font(.headline)
                        Text(issue.description).font(.subheadline)
                    }
                }
            }
            Button("Analyze") { Task { await viewModel.analyze(audioURL: audioURL, expectedText: expectedText) } }
        }
        .padding()
        .navigationTitle("Analysis")
    }
}


