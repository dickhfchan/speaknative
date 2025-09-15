import Foundation

enum PronunciationIssueType: String, Codable, Equatable {
    case vowel, consonant, stress, rhythm, intonation
}

struct PronunciationIssue: Identifiable, Equatable, Codable {
    let id: UUID
    let analysisResultId: UUID
    var type: PronunciationIssueType
    var word: String
    var position: Int
    var severity: Float
    var description: String
    var suggestion: String
}


