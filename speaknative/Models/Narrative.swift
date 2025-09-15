import Foundation

struct Narrative: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var content: String
    var difficulty: Int
    var duration: TimeInterval
    var nativeAudioURL: String
    var createdAt: Date
    var updatedAt: Date
}


