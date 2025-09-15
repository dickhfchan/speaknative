import XCTest
@testable import speaknative

final class ExerciseServiceTests: XCTestCase {
    func testGenerateExercisesFromIssues() {
        let issues = [PronunciationIssue(id: UUID(), analysisResultId: UUID(), type: .vowel, word: "coffee", position: 0, severity: 0.8, description: "Vowel sound off", suggestion: "Short 'o'")]
        let svc = ExerciseService()
        let exercises = svc.generateExercises(from: issues)
        XCTAssertEqual(exercises.count, 3)
        XCTAssertEqual(exercises.first?.type, .word)
    }
}


