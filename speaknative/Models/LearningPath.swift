import Foundation

enum LearningPathStatus: String, Codable, Equatable {
    case active, completed, paused
}

struct LearningPath: Identifiable, Equatable, Codable {
    let id: UUID
    var userId: String
    var analysisResultId: UUID
    var exercises: [Exercise]
    var currentExerciseIndex: Int
    var status: LearningPathStatus
    var createdAt: Date
    var updatedAt: Date
}


