import Foundation

struct UserRecording: Identifiable, Equatable, Codable {
    let id: UUID
    let narrativeId: UUID
    var audioURL: String
    var duration: TimeInterval
    var quality: String
    var volume: Float
    var createdAt: Date
    var userId: String
}


