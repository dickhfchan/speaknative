import Foundation

final class ExerciseViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var currentIndex: Int = 0
    private let generator = ExerciseService()

    func load(from issues: [PronunciationIssue]) {
        exercises = generator.generateExercises(from: issues)
        currentIndex = 0
    }

    func next() { if currentIndex + 1 < exercises.count { currentIndex += 1 } }
    func retry() { /* keep same index */ }
}


