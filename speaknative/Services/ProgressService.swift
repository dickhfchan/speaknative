import Foundation

final class ProgressService {
    func recordAttempt(for exercise: Exercise, success: Bool, score: Float, timeSpent: TimeInterval, userId: String) -> Progress {
        Progress(id: UUID(), userId: userId, exerciseId: exercise.id, attempts: 1, success: success, score: score, timeSpent: timeSpent, completedAt: success ? Date() : nil, createdAt: Date())
    }
}


