import Foundation

struct Progress: Identifiable, Equatable, Codable {
    let id: UUID
    var userId: String
    var exerciseId: UUID
    var attempts: Int
    var success: Bool
    var score: Float
    var timeSpent: TimeInterval
    var completedAt: Date?
    var createdAt: Date
}


