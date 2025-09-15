import XCTest
@testable import speaknative

final class ProgressServiceTests: XCTestCase {
    func testRecordAttemptCreatesProgress() {
        let svc = ProgressService()
        let ex = Exercise(id: UUID(), type: .word, content: "test", targetIssue: "vowel", difficulty: 1, audioURL: "", instructions: "", successCriteria: "", createdAt: Date())
        let p = svc.recordAttempt(for: ex, success: true, score: 0.9, timeSpent: 1.2, userId: "u1")
        XCTAssertEqual(p.exerciseId, ex.id)
        XCTAssertTrue(p.success)
    }
}


