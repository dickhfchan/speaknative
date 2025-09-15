import Foundation

final class ExerciseService {
    func generateExercises(from issues: [PronunciationIssue]) -> [Exercise] {
        var exercises: [Exercise] = []
        for issue in issues {
            let base = Exercise(id: UUID(), type: .word, content: issue.word, targetIssue: issue.type.rawValue, difficulty: 1, audioURL: "", instructions: "Repeat the word focusing on \(issue.type.rawValue)", successCriteria: "Pronounce with severity < 0.3", createdAt: Date())
            exercises.append(base)
            exercises.append(Exercise(id: UUID(), type: .phrase, content: "Practice \(issue.word) in a phrase", targetIssue: issue.type.rawValue, difficulty: 2, audioURL: "", instructions: "Repeat the phrase", successCriteria: "Severity < 0.3", createdAt: Date()))
            exercises.append(Exercise(id: UUID(), type: .sentence, content: "Use \(issue.word) in a sentence", targetIssue: issue.type.rawValue, difficulty: 3, audioURL: "", instructions: "Read the sentence clearly", successCriteria: "Severity < 0.3", createdAt: Date()))
        }
        return exercises
    }
}


