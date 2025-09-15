import SwiftUI

struct ExerciseView: View {
    @StateObject var viewModel = ExerciseViewModel()
    let issues: [PronunciationIssue]

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.exercises.isEmpty {
                Text("No exercises loaded")
            } else {
                let ex = viewModel.exercises[viewModel.currentIndex]
                Text(ex.content).font(.title2)
                Text(ex.instructions).font(.subheadline)
                HStack {
                    Button("Retry") { viewModel.retry() }
                    Button("Next") { viewModel.next() }
                }
            }
        }
        .onAppear { viewModel.load(from: issues) }
        .padding()
        .navigationTitle("Exercises")
    }
}


