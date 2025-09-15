import Foundation

enum ExerciseType: String, Codable, Equatable {
    case word, phrase, sentence
}

struct Exercise: Identifiable, Equatable, Codable {
    let id: UUID
    var type: ExerciseType
    var content: String
    var targetIssue: String
    var difficulty: Int
    var audioURL: String
    var instructions: String
    var successCriteria: String
    var createdAt: Date
}


