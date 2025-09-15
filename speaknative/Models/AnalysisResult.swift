import Foundation

struct AnalysisResult: Identifiable, Equatable, Codable {
    let id: UUID
    let recordingId: UUID
    var overallScore: Float
    var issues: [PronunciationIssue]
    var processingTime: TimeInterval
    var confidence: Float
    var createdAt: Date
}


